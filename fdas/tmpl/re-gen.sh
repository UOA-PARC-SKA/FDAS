#!/bin/bash

python3 tmpl-gen.py -o fdas_templates_85_350.npy
python3 tmpl-gen.py -o fdas_templates_85_350_ft_p4.npy --fourier-transform --fft-order

python3 tmpl-gen.py -o fdas_templates_21_87.5.npy --num-templates 21 --max-accel 87.5
python3 tmpl-gen.py -o fdas_templates_21_87.5_ft_p4.npy --num-templates 21 --max-accel 87.5 --fourier-transform --fft-order
