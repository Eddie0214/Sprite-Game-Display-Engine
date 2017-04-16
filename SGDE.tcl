#Setting Design Environment
set_operating_conditions -min_library fsa0m_a_generic_core_ff1p98vm40c -min BCCOM  -max_library fsa0m_a_generic_core_ss1p62v125c -max WCCOM
set_driving_cell -lib_cell DFFP -library fsa0m_a_generic_core_ss1p62v125c -no_design_rule [all_inputs]
set_load [load_of "fsa0m_a_generic_core_ss1p62v125c/BUF1/I"] [all_outputs]
set_wire_load_model -name G0K -library fsa0m_a_generic_core_ss1p62v125c

#Setting Clock Constriants
create_clock -name clk -period 100 [get_ports clk]  

set_dont_touch_network              [get_clocks clk]
set_fix_hold                        [get_clocks clk]
set_clock_uncertainty       0.1     [get_clocks clk]
set_clock_latency   -source 0       [get_clocks clk]
set_clock_latency           0.5     [get_clocks clk]  
set_input_transition        0.5     [all_inputs]
set_clock_transition        0.1     [all_clocks]

set_input_delay   5    -clock clk   [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay  0.5    -clock clk   [all_outputs]


#Setting DRC Constraint
set_max_area        0
set_max_fanout      20    [all_inputs]
set_max_transition  0.5  [all_inputs]

#set_ideal_network   -no_propagate    [get_nets clk]
#set_ideal_network   -no_propagate    [get_nets rst] 
set high_fanout_net_threshold 30
set high_fanout_net_pin_capacitance 0.01



