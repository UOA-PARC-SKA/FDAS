#!/bin/bash

mkdir dse

for N_ENGINES in $(seq 2 5) ; do

# total points in HSum: 8
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x8x1.cl  -g dse/gen_info_${N_ENGINES}x8x1.h  --n-engines ${N_ENGINES} --group-sz 8  --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x4x2.cl  -g dse/gen_info_${N_ENGINES}x4x2.h  --n-engines ${N_ENGINES} --group-sz 4  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x2x4.cl  -g dse/gen_info_${N_ENGINES}x2x4.h  --n-engines ${N_ENGINES} --group-sz 2  --bundle-sz 4
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x1x8.cl  -g dse/gen_info_${N_ENGINES}x1x8.h  --n-engines ${N_ENGINES} --group-sz 1  --bundle-sz 8

# total points in HSum: 12 (bundle sz needs to be a power of 2)
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x12x1.cl -g dse/gen_info_${N_ENGINES}x12x1.h --n-engines ${N_ENGINES} --group-sz 12 --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x6x2.cl  -g dse/gen_info_${N_ENGINES}x6x2.h  --n-engines ${N_ENGINES} --group-sz 6  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x3x4.cl  -g dse/gen_info_${N_ENGINES}x3x4.h  --n-engines ${N_ENGINES} --group-sz 3  --bundle-sz 4

# total points in HSum: 16
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x16x1.cl -g dse/gen_info_${N_ENGINES}x16x1.h --n-engines ${N_ENGINES} --group-sz 16 --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x8x2.cl  -g dse/gen_info_${N_ENGINES}x8x2.h  --n-engines ${N_ENGINES} --group-sz 8  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x4x4.cl  -g dse/gen_info_${N_ENGINES}x4x4.h  --n-engines ${N_ENGINES} --group-sz 4  --bundle-sz 4
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x2x8.cl  -g dse/gen_info_${N_ENGINES}x2x8.h  --n-engines ${N_ENGINES} --group-sz 2  --bundle-sz 8
python3 cl_codegen.py -c dse/fdas_${N_ENGINES}x1x16.cl -g dse/gen_info_${N_ENGINES}x1x16.h --n-engines ${N_ENGINES} --group-sz 1  --bundle-sz 16

done
