onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uvm_top/_dut/packet_finished
add wave -noupdate /uvm_top/_dut/port_req
add wave -noupdate /uvm_top/_dut/port_data
add wave -noupdate /uvm_top/_dut/port_received
add wave -noupdate -divider {New Divider}
add wave -noupdate /uvm_top/inst_if_in/clk
add wave -noupdate /uvm_top/inst_if_in/reset
add wave -noupdate /uvm_top/inst_if_in/mem_port_index
add wave -noupdate /uvm_top/inst_if_in/port_address
add wave -noupdate /uvm_top/inst_if_in/mem_write
add wave -noupdate /uvm_top/inst_if_in/packet_data
add wave -noupdate /uvm_top/inst_if_in/packet_send_req
add wave -noupdate /uvm_top/inst_if_in/packet_finished
add wave -noupdate -divider {New Divider}
add wave -noupdate /uvm_top/_dut/i_switch/clk
add wave -noupdate /uvm_top/_dut/i_switch/reset
add wave -noupdate /uvm_top/_dut/i_switch/mem_port_index
add wave -noupdate /uvm_top/_dut/i_switch/port_address
add wave -noupdate /uvm_top/_dut/i_switch/mem_write
add wave -noupdate /uvm_top/_dut/i_switch/packet_data
add wave -noupdate /uvm_top/_dut/i_switch/packet_send_req
add wave -noupdate /uvm_top/_dut/i_switch/packet_finished
add wave -noupdate /uvm_top/_dut/i_switch/port_req
add wave -noupdate /uvm_top/_dut/i_switch/port_data
add wave -noupdate /uvm_top/_dut/i_switch/port_received
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 297
configure wave -valuecolwidth 205
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {6820 ps}
