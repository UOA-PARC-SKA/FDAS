#!/bin/bash

mkdir dse

python3 cl_codegen.py -c dse/fdas_4x16x1.cl -g dse/gen_info_4x16x1.h --n-engines 4 --group-sz 16 --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_4x12x1.cl -g dse/gen_info_4x12x1.h --n-engines 4 --group-sz 12 --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_4x8x2.cl  -g dse/gen_info_4x8x2.h  --n-engines 4 --group-sz 8  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_4x6x2.cl  -g dse/gen_info_4x6x2.h  --n-engines 4 --group-sz 6  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_4x4x4.cl  -g dse/gen_info_4x4x4.h  --n-engines 4 --group-sz 4  --bundle-sz 4
python3 cl_codegen.py -c dse/fdas_4x3x4.cl  -g dse/gen_info_4x3x4.h  --n-engines 4 --group-sz 3  --bundle-sz 4
python3 cl_codegen.py -c dse/fdas_4x2x8.cl  -g dse/gen_info_4x2x8.h  --n-engines 4 --group-sz 2  --bundle-sz 8
python3 cl_codegen.py -c dse/fdas_4x1x16.cl -g dse/gen_info_4x1x16.h --n-engines 4 --group-sz 1  --bundle-sz 16

python3 cl_codegen.py -c dse/fdas_3x16x1.cl -g dse/gen_info_3x16x1.h --n-engines 3 --group-sz 16 --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_3x12x1.cl -g dse/gen_info_3x12x1.h --n-engines 3 --group-sz 12 --bundle-sz 1
python3 cl_codegen.py -c dse/fdas_3x8x2.cl  -g dse/gen_info_3x8x2.h  --n-engines 3 --group-sz 8  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_3x6x2.cl  -g dse/gen_info_3x6x2.h  --n-engines 3 --group-sz 6  --bundle-sz 2
python3 cl_codegen.py -c dse/fdas_3x4x4.cl  -g dse/gen_info_3x4x4.h  --n-engines 3 --group-sz 4  --bundle-sz 4
python3 cl_codegen.py -c dse/fdas_3x3x4.cl  -g dse/gen_info_3x3x4.h  --n-engines 3 --group-sz 3  --bundle-sz 4
python3 cl_codegen.py -c dse/fdas_3x2x8.cl  -g dse/gen_info_3x2x8.h  --n-engines 3 --group-sz 2  --bundle-sz 8
python3 cl_codegen.py -c dse/fdas_3x1x16.cl -g dse/gen_info_3x1x16.h --n-engines 3 --group-sz 1  --bundle-sz 16
