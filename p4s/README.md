# P4 Scripts
This folder contains the P4 examples used in order to test the menshen pipeline.
In each folder there is the P4 script and the compiled files with the comfiguration of the pipeline; in order to recompile them please check the [menshen compiler](https://github.com/multitenancy-project/menshen-compiler.git).

The python script "verilog_converter.py" is used to convert the compiled P4 files into verilog code, in order to simulate and test the menshen pipeline. To convert a P4 example, rename the desired folder into "p4_generated" and run the python script.
