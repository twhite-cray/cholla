#!/bin/bash
module restore PrgEnv-cray
module load cray-mvapich2/2.3.4
module load hdf5
module load gcc/8.1.0
module load rocm
module list

export LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"

export CXX=CC
export DFLAGS='-DPARIS_NO_GPU_MPI'
export HIPCONFIG=$(hipconfig -C)
export MPI_HOME=$(dirname $(dirname $(which mpicc)))
export OMP_NUM_THREADS=16
export POISSON_SOLVER='-DSOR -DPARIS'
export SUFFIX='.paris.sor'
export TYPE=gravity

make clean
make -j
