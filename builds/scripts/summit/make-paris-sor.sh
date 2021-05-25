#!/bin/bash

module load xl cuda fftw hdf5 python

module list

export F_OFFLOAD="-qsmp=omp -qoffload"
export CHOLLA_ENVSET=1
export HDF5INCLUDE=${OLCF_HDF5_ROOT}/include
export HDF5DIR=${OLCF_HDF5_ROOT}/lib
export MPI_HOME=${MPI_ROOT}
export POISSON_SOLVER='-DPARIS -DSOR'
export SUFFIX='.paris.sor'
export CC=mpicc
export CXX=mpicxx
export LIBS="-L${CUDA_DIR}/lib64"
make clean
make TYPE=gravity -j
