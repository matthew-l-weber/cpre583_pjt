onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /user_logic_tb/clk
add wave -noupdate /user_logic_tb/reset_n
add wave -noupdate /user_logic_tb/reset_user_logic
add wave -noupdate -radix hexadecimal /user_logic_tb/ipif_Bus2IP_Data
add wave -noupdate /user_logic_tb/ipif_Bus2IP_BE
add wave -noupdate -radix hexadecimal /user_logic_tb/user_Bus2IP_RdCE
add wave -noupdate -radix hexadecimal /user_logic_tb/user_Bus2IP_WrCE
add wave -noupdate -radix hexadecimal /user_logic_tb/user_IP2Bus_Data
add wave -noupdate /user_logic_tb/user_IP2Bus_RdAck
add wave -noupdate /user_logic_tb/user_IP2Bus_WrAck
add wave -noupdate /user_logic_tb/user_IP2Bus_Error
add wave -noupdate -radix decimal /user_logic_tb/current_test
add wave -noupdate /user_logic_tb/tsi
add wave -noupdate /user_logic_tb/tso
add wave -noupdate -divider {Test 1}
add wave -noupdate /user_logic_tb/test1_i/current_state
add wave -noupdate -divider {Test 2}
add wave -noupdate /user_logic_tb/test2_i/current_state
add wave -noupdate -divider {Test 3}
add wave -noupdate /user_logic_tb/test3_i/current_state
add wave -noupdate /user_logic_tb/test3_i/msg_count
add wave -noupdate -divider {Test 4}
add wave -noupdate /user_logic_tb/test4_i/current_state
add wave -noupdate /user_logic_tb/test4_i/msg_count
add wave -noupdate -divider user_logic
add wave -noupdate /user_logic_tb/user_logic_i/algoState
add wave -noupdate /user_logic_tb/user_logic_i/new_op
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/local_status
add wave -noupdate -radix decimal /user_logic_tb/user_logic_i/local_rst
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/ld_map
add wave -noupdate /user_logic_tb/user_logic_i/ul_msg
add wave -noupdate /user_logic_tb/user_logic_i/ul_init
add wave -noupdate /user_logic_tb/user_logic_i/ul_load
add wave -noupdate /user_logic_tb/user_logic_i/ul_hash
add wave -noupdate /user_logic_tb/user_logic_i/ul_valid
add wave -noupdate /user_logic_tb/user_logic_i/ul_reset
add wave -noupdate /user_logic_tb/user_logic_i/local_startBlk
add wave -noupdate /user_logic_tb/user_logic_i/local_finished
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/bus_slv_reg0
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/bus_slv_reg1
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/bus_slv_reg2
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/bus_slv_reg3
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg0_rst
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg1_status
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg2_startBlk
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg3_finished
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg4_h0
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg5_h1
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg6_h2
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg7_h3
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg8_h4
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg9
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg10
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg11
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg12
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg13
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg14
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg15
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg16
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg17
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg18
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg19
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg20
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg21
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg22
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg23
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg24
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg25
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg26
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg27
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg28
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg29
add wave -noupdate -radix hexadecimal /user_logic_tb/user_logic_i/slv_reg31
add wave -noupdate /user_logic_tb/user_logic_i/slv_reg_write_sel
add wave -noupdate /user_logic_tb/user_logic_i/slv_reg_read_sel
add wave -noupdate /user_logic_tb/user_logic_i/slv_ip2bus_data
add wave -noupdate /user_logic_tb/user_logic_i/slv_read_ack
add wave -noupdate /user_logic_tb/user_logic_i/slv_write_ack
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {182492 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 178
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {1858594 ps} {2007443 ps}
