#!/bin/bash

#compile TB and design files
vcom TB.vhdl src/uart_rx.vhd src/uart_baud.vhd src/uart_rx_ctl.vhd src/meta_harden.vhd
