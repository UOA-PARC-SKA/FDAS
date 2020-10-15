#!/bin/bash

python3 tmpl-gen.py -o fdas_templates_85_350.npy
python3 tmpl-gen.py -o fdas_templates_85_350_ft_p4.npy --fourier-transform --fft-order
