restart -f -nowave
config wave -signalnamewidth 1

add wave reg_uart_clk    
add wave reg_uart_rst    
add wave reg_uart_rxd_rx 
add wave -radix binary reg_uart_rx_data
add wave -radix binary stimuli
add wave reg_uart_wr_en

add wave dut/uart_rx_ctl_inst/state
add wave dut/uart_rx_ctl_inst/next_state

add wave dut/uart_rx_ctl_inst/over_sample_cnt
add wave dut/uart_rx_ctl_inst/over_sample_done
add wave dut/uart_rx_ctl_inst/bit_cnt
add wave dut/uart_rx_ctl_inst/bit_cnt_done
add wave dut/uart_rx_ctl_inst/baud_en

run -all

view signals wave
wave zoom full
