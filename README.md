# MIPS-5-Stage-Pipelined-CPU
A simple implementation of the MIPS CPU with hazard detection and resolution

A canonical 5 stage pipelined MIPS processory consisting of the Fetch, Decode, Execute, Memory and Writeback stages. 
Processor detects R-Type data hazards and resolves them through stalling (flushing).
Check source code by checking the file at MIPS-5-Stage-Pipelined-CPU/PipelinedCPU.srcs/sources_1/new/processor.v in this repository
Written in Verilog on Xilinx Vivado. 


Tianqi Yang @Penn State University, Dec 2020
