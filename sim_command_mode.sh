#!/bin/bash

#create work library
vlib work
#compiling TB and Design files
vcom TB.vhdl src/uart_rx.vhd src/uart_baud.vhd src/uart_rx_ctl.vhd
#run optimization
vopt TB +acc=rn -o tb_opt
#run simulation in command mode
vsim -c -do "run -all; exit" tb_opt
