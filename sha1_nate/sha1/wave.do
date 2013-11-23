onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sha1_tb/system_clk
add wave -noupdate /sha1_tb/reset
add wave -noupdate -radix hexadecimal /sha1_tb/msg
add wave -noupdate /sha1_tb/init
add wave -noupdate /sha1_tb/ld
add wave -noupdate -radix hexadecimal /sha1_tb/hash
add wave -noupdate /sha1_tb/valid
add wave -noupdate -divider {Test Bench Driver}
add wave -noupdate /sha1_tb/sha1_driver/current_state
add wave -noupdate /sha1_tb/sha1_driver/idx
add wave -noupdate -divider SHA1
add wave -noupdate /sha1_tb/sha1_hw/w
add wave -noupdate /sha1_tb/sha1_hw/w0
add wave -noupdate /sha1_tb/sha1_hw/nld
add wave -noupdate /sha1_tb/sha1_hw/ild
add wave -noupdate /sha1_tb/sha1_hw/ild_rst
add wave -noupdate /sha1_tb/sha1_hw/sr
add wave -noupdate /sha1_tb/sha1_hw/sc
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {165948 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ns
update
WaveRestoreZoom {247414 ps} {292672 ps}
