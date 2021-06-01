#!/bin/bash
#BSUB -W 0:05
#BSUB -nnodes 1
#BSUB -J cholla.paris.pfft
#BSUB -o o.%J
#BSUB -q debug

module load gcc hdf5 cuda fftw

OUTDIR="run/summit.paris.pfft.${LSB_JOBID}"
set -x
mkdir -p ${OUTDIR}
cd ${OUTDIR}
export OMP_NUM_THREADS=16
jsrun --smpiargs="-gpu" -n4 -a1 -c4 -g1 ../../bin/cholla-summit.paris.pfft ../../tests/scripts/sphere-periodic.txt |& tee tee
