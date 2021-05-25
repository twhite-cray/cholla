#!/bin/bash

module load craype-accel-amd-gfx908
module load cray-hdf5
module load rocm
module list

OUTDIR="run/out.hydro-spock.$(date +%m%d.%H%M%S)"
set -x
export OMP_NUM_THREADS=16
export MPIR_CVAR_GPU_EAGER_DEVICE_MEM=0
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_SMP_SINGLE_COPY_MODE=CMA
mkdir -p ${OUTDIR}
cd ${OUTDIR}
srun -n1 -c$OMP_NUM_THREADS -N1 -A CSC434_spock -t 2:00 ../../bin/cholla.hydro-spock ../../tests/3D/sod.txt |& tee tee.mi100
