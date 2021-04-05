#!/bin/bash
#BSUB -P VEN114
#BSUB -W 0:05
#BSUB -nnodes 1
#BSUB -J cholla.paris.sor
#BSUB -o o.%J
#BSUB -q debug

module load xl cuda fftw hdf5 python
module list

OUTDIR="run/out.paris.sor.${LSB_JOBID}"
set -x
mkdir -p ${OUTDIR}
cd ${OUTDIR}
export OMP_NUM_THREADS=10
jsrun --smpiargs="-gpu" -n4 -a1 -c4 -g1 ../../bin/cholla.paris.sor ../../tests/scripts/sphere.txt |& tee tee
