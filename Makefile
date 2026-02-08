sim-build:
	iverilog -g2012 -o sim.out src/*.sv

run-sim: 
	vvp sim.out