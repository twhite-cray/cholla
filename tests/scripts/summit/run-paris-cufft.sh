#!/bin/bash
#BSUB -W 0:05
#BSUB -nnodes 1
#BSUB -J cholla.paris.cufft
#BSUB -o o.%J
#BSUB -q debug

module load xl cuda fftw hdf5 python
module list

OUTDIR="run/summit.paris.cufft.${LSB_JOBID}"
set -x
mkdir -p ${OUTDIR}
cd ${OUTDIR}
export OMP_NUM_THREADS=16
jsrun --smpiargs="-gpu" -n1 -a1 -c16 -g1 ../../bin/cholla-summit.paris.cufft ../../tests/scripts/sphere-preiodic.txt |& tee tee
