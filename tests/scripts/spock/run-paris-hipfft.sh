#!/bin/bash

module load craype-accel-amd-gfx908
module load cray-hdf5
module load rocm
module list

OUTDIR="run/spock.paris.hipfft.$(date +%m%d.%H%M%S)"
set -x
export OMP_NUM_THREADS=16
export MPIR_CVAR_GPU_EAGER_DEVICE_MEM=0
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_SMP_SINGLE_COPY_MODE=CMA
mkdir -p ${OUTDIR}
cd ${OUTDIR}
srun -n1 -c$OMP_NUM_THREADS -N1 -A ${ACCT} -p caar -t 2:00 ../../bin/cholla-spock.paris.hipfft ../../tests/scripts/sphere-periodic.txt |& tee tee
