#!/bin/bash

python3 tmpl-gen.py -o fdas_templates_85_350.npy
python3 tmpl-gen.py -o fdas_templates_85_350_ft.npy --fourier-transform
python3 tmpl-gen.py -o fdas_templates_21_87.5.npy --num-templates 21 --max-accel 87.5
python3 tmpl-gen.py -o fdas_templates_21_87.5_ft.npy --num-templates 21 --max-accel 87.5 --fourier-transform
