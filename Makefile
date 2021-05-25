#-- Set default include makefile
MACHINE ?= $(shell builds/machine.sh)
TYPE    ?= hydro

include builds/make.host.$(MACHINE)
include builds/make.type.$(TYPE)

DIRS     := src src/gravity src/particles src/cosmology src/cooling src/model src/cooling_grackle src/analysis
ifeq ($(findstring -DPARIS,$(POISSON_SOLVER)),-DPARIS)
  DIRS += src/gravity/paris
  SUFFIX ?= .paris.$(MACHINE)
endif

SUFFIX ?= .$(TYPE).$(MACHINE)

CFILES   := $(foreach DIR,$(DIRS),$(wildcard $(DIR)/*.c))
CPPFILES := $(foreach DIR,$(DIRS),$(wildcard $(DIR)/*.cpp))
GPUFILES := $(foreach DIR,$(DIRS),$(wildcard $(DIR)/*.cu))

OBJS     := $(subst .c,.o,$(CFILES)) \
            $(subst .cpp,.o,$(CPPFILES)) \
            $(subst .cu,.o,$(GPUFILES))

#-- Set default compilers and flags
CC                ?= cc
CXX               ?= CC

CFLAGS_OPTIMIZE   ?= -Ofast
CXXFLAGS_OPTIMIZE ?= -Ofast -std=c++11
BUILD             ?= OPTIMIZE

CFLAGS             = $(CFLAGS_$(BUILD))
CXXFLAGS           = $(CXXFLAGS_$(BUILD))


#-- Add flags and libraries as needed

CFLAGS   += $(DFLAGS) -Isrc
CXXFLAGS += $(DFLAGS) -Isrc
GPUFLAGS += $(DFLAGS) -Isrc -std=c++11

ifeq ($(findstring -DPFFT,$(DFLAGS)),-DPFFT)
  CXXFLAGS += -I$(FFTW_ROOT)/include -I$(PFFT_ROOT)/include
  GPUFLAGS += -I$(FFTW_ROOT)/include -I$(PFFT_ROOT)/include
  LIBS += -L$(FFTW_ROOT)/lib -L$(PFFT_ROOT)/lib -lpfft -lfftw3_mpi -lfftw3
endif

ifeq ($(findstring -DCUFFT,$(DFLAGS)),-DCUFFT)
  ifdef HIPCONFIG
    CXXFLAGS += -I$(ROCM_PATH)/hipfft/include
    GPUFLAGS += -I$(ROCM_PATH)/hipfft/include
    LIBS += -L$(ROCM_PATH)/hipfft/lib -lhipfft
  else
    LIBS += -lcufft
  endif
endif

ifeq ($(findstring -DPARIS,$(DFLAGS)),-DPARIS)
  ifdef HIPCONFIG
    CXXFLAGS += -I$(ROCM_PATH)/hipfft/include
    GPUFLAGS += -I$(ROCM_PATH)/hipfft/include
    LIBS += -L$(ROCM_PATH)/hipfft/lib -lhipfft
  else
    LIBS += -lcufft
  endif
  ifeq ($(findstring -DGRAVITY_5_POINTS_GRADIENT,$(DFLAGS)),-DGRAVITY_5_POINTS_GRADIENT)
    DFLAGS += -DPARIS_5PT
  else
    DFLAGS += -DPARIS_3PT
  endif
endif

ifeq ($(findstring -DHDF5,$(DFLAGS)),-DHDF5)
  CXXFLAGS += -I$(HDF5_ROOT)/include
  GPUFLAGS += -I$(HDF5_ROOT)/include
  LIBS     += -L$(HDF5_ROOT)/lib -lhdf5
endif

ifeq ($(findstring -DMPI_CHOLLA,$(DFLAGS)),-DMPI_CHOLLA)
  GPUFLAGS += -I$(MPI_ROOT)/include
  ifdef HIPCONFIG
     LIBS += -L$(MPI_ROOT)/lib -lmpi
  endif
endif

ifeq ($(findstring -DPARALLEL_OMP,$(DFLAGS)),-DPARALLEL_OMP)
  CXXFLAGS += -fopenmp
endif

ifeq ($(findstring -DLYA_STATISTICS,$(DFLAGS)),-DLYA_STATISTICS)
  CXXFLAGS += -I$(FFTW_ROOT)/include 
  GPUFLAGS += -I$(FFTW_ROOT)/include 
  LIBS += -L$(FFTW_ROOT)/lib -lfftw3_mpi -lfftw3
endif


ifdef HIPCONFIG
  DFLAGS    += -DO_HIP
  CXXFLAGS  += $(HIPCONFIG)
  GPUCXX    ?= hipcc
  GPUFLAGS  += -g -O3 -Wall --amdgpu-target=gfx908 -std=c++11 -ferror-limit=1
  LD        := $(CXX)
  LDFLAGS   := $(CXXFLAGS)
  LIBS      += -L$(ROCM_PATH)/lib -lamdhip64 -lhsa-runtime64
else
  CUDA_INC  ?= -I$(CUDA_ROOT)/include
  CUDA_LIB  ?= -L$(CUDA_ROOT)/lib64 -lcudart
  CXXFLAGS  += $(CUDA_INC)
  GPUCXX    ?= nvcc
  GPUFLAGS  += -std=c++11 --expt-extended-lambda -g -O3 -arch sm_70 -fmad=false
  GPUFLAGS  += $(CUDA_INC)
  LD        := $(CXX)
  LDFLAGS   += $(CXXFLAGS)
  LIBS      += $(CUDA_LIB)
endif

ifeq ($(findstring -DCOOLING_GRACKLE,$(DFLAGS)),-DCOOLING_GRACKLE)
  DFLAGS += -DCONFIG_BFLOAT_8
  DFLAGS += -DSCALAR
  CXXFLAGS += -I$(GRACKLE_ROOT)/include
  GPUFLAGS += -I$(GRACKLE_ROOT)/include
  LIBS     += -L$(GRACKLE_ROOT)/lib -lgrackle
endif

.SUFFIXES: .c .cpp .cu .o

EXEC := bin/cholla$(SUFFIX)

$(EXEC): prereq-build $(OBJS) 
	mkdir -p bin/ && $(LD) $(LDFLAGS) $(OBJS) -o $(EXEC) $(LIBS)
	eval $(EXTRA_COMMANDS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.cu
	$(GPUCXX) $(GPUFLAGS) -c $< -o $@

.PHONY: clean
	
clean:
	rm -f $(OBJS) 
	-find bin/ -type f -executable -name "cholla.*.$(MACHINE)" -exec rm -f '{}' \;

clobber: clean
	find . -type f -executable -name "cholla*" -exec rm -f '{}' \;

prereq-build:
	builds/prereq.sh build $(MACHINE)
prereq-run:
	builds/prereq.sh run $(MACHINE)

check : OUTPUT=-DOUTPUT
check : clean $(EXEC) prereq-run
	$(JOB_LAUNCH) bin/cholla.$(TYPE).$(MACHINE) tests/regression/${TYPE}_input.txt
	builds/check.sh $(TYPE) tests/regression/${TYPE}_test.txt
