sim-build:
	iverilog -g2012 -o sim.out -s tb_calculator src/*.sv

run-sim: 
	vvp sim.out