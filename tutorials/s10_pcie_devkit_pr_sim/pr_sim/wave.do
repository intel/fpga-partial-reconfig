onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TOP TB}
add wave -noupdate -radix ascii /top_tb/pr_sim_text
add wave -noupdate /top_tb/clk
add wave -noupdate /top_tb/rst_n
add wave -noupdate /top_tb/pr_activate
add wave -noupdate /top_tb/freeze
add wave -noupdate -radix ascii /top_tb/persona_select_text
add wave -noupdate /top_tb/persona_select
add wave -noupdate /top_tb/a
add wave -noupdate /top_tb/b
add wave -noupdate /top_tb/result
add wave -noupdate -divider {PR PERSONAS}
add wave -noupdate /top_tb/result_and_gate_pr
add wave -noupdate /top_tb/result_counter_pr
add wave -noupdate /top_tb/result_fsm_pr
add wave -noupdate -divider {RTL PERSONAS}
add wave -noupdate /top_tb/result_and_gate
add wave -noupdate /top_tb/result_counter
add wave -noupdate /top_tb/result_fsm
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40000 ps} 0} {{Cursor 2} {585726 ps} 0} {{Cursor 3} {1320000 ps} 0}
quietly wave cursor active 3
configure wave -namecolwidth 222
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {1722 ns}
