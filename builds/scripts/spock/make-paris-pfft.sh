#!/bin/bash

module load craype-accel-amd-gfx908
module load cray-hdf5
module load rocm
module use /ccs/home/trey/public/spock/modulefiles
module load pfft
module list

set -x
export PE_MPICH_GTL_DIR_amd_gfx908=${PE_MPICH_GTL_DIR_gfx908}
export PE_MPICH_GTL_LIBS_amd_gfx908=${PE_MPICH_GTL_LIBS_gfx908}
export CC=cc
export CXX=CC
export HIPCONFIG=$(hipconfig -C)
export OMP_NUM_THREADS=16
export POISSON_SOLVER="-DPFFT -DPARIS"
export SUFFIX='-spock.paris.pfft'
export TYPE=gravity

make clean
make -j
