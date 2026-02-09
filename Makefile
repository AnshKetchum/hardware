sim-build:
	iverilog -g2012 -o sim.out -s tb_calculator src/verilog/*.sv

run-sim: 
	vvp sim.out