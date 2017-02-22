set_property PACKAGE_PIN G24 [get_ports uart_rx]
set_property PACKAGE_PIN J21 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]




set_property PACKAGE_PIN D26 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]





set_false_path -from [get_pins sys/ledval_reg/C] -to [get_ports *led*]
set_false_path -from [get_ports *uart_rx*] -to [get_pins {sys/coregen[0].uart/rx_1_reg/D}]
set_false_path -from [get_pins {sys/coregen[0].uart/uart/tx_out_reg/C}] -to [get_ports uart_tx]

set_property PACKAGE_PIN A23 [get_ports usbclk]
set_property IOSTANDARD LVCMOS33 [get_ports usbclk]
set_property IOSTANDARD LVCMOS33 [get_ports pll_clk_en]
set_property IOSTANDARD LVCMOS33 [get_ports pll_i2c_in4]
set_property PACKAGE_PIN C26 [get_ports pll_clk_en]
set_property PACKAGE_PIN B20 [get_ports pll_i2c_in4]
