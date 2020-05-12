This is the FDAS pipeline that implemented before Haomiao leave on 31st Jul 2019.

The main OpenCL kernel is in device/fdas_fft2_op2.cl
It consists of 3 parts with 5 kernels:

-FT convolution
	-fetch
	-fdfir
	-reversed
-FOP preparing
	-discard
-Harmonic summing
	-harmonic_summing

The kernel is compiled with the command:

aoc device/fdas_fft2_op2.cl -o fdas_fft2_op2_ll.aocx --no-interleaving default --report -g -v --profile
The *.aocx file and the executable file have been stored in bin/

The input is in bin/real_data/padded_input_p_1_234_2584group.dat,
which consists of 2584 groups of 2K input. Each 2K input has been Fourier transformed and
each pre-tranformed 2K input has an overlapped part, which length is 421, with its 2 neighbor 
2K inputs.

The filter coefficient is stored in bin/real_data/template_fft_8x_2048.dat

The details of execution times in profile is as follows:

single FT convolution: 4ms-5ms
43 FT convolution launch: 250ms
FOP preparing: 225ms
Harmonic summing: 775ms

The FT convolution part contains two FFT engine and it has to be launched 43 times to
process 85 FIR filters.
Since the execution time of FT convoultion+FOP preparing is faster than that of Harmonic 
summing, the fdas pipeline can be launched using double buffering technique.





 