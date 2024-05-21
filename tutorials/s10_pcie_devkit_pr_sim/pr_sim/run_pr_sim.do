# Record all commands done in transcript window
#transcript on

rm -rf work
vlib work

set quartus_dir				/p/psg/swip/releases/acds/24.1/115/linux64/quartus
set quartus_sim_lib_path	$quartus_dir/eda/sim_lib
set root_partition			root_partition
set pr_partition			pr_partition
set pr_sim_model_path		simulation/questa/pr

set testbench_files {
	top_tb.sv
}					

set design_files {
	top.sv
	pr_wrapper.sv
	top_sim.sv
	pr_sim_wrapper.sv
	freeze_logic_controller.sv
}	

# Used to compile persona pr sim models below
set persona_names {
	and_gate
	counter
	fsm
}

set library_files {
	altera_lnsim.sv
	fourteennm_atoms.sv
	altera_primitives.v
}

puts "============= Running PR Simulation ============="

puts "Generate PR simulation models"
do gen_pr_models.do

puts "Compiling testbench files"
foreach file $testbench_files {
	vlog -sv -work work $file
}

puts "Compiling design files"
foreach file $design_files {
	vlog -sv -work work $file
}

puts "Compiling pr persona files"
foreach persona_name $persona_names {
	vlog -sv -work work $pr_sim_model_path/$persona_name.$pr_partition.vo
}

puts "Compiling library files"
foreach library_file $library_files {
	vlog -sv -work work $quartus_sim_lib_path/$library_file 
}

puts "Start simulation"
vsim -t 1ps -L work -voptargs="+acc" top_tb

puts "Running waveform file"
do wave.do

puts "Running sim"
run -all
puts "============= Finished PR Simulation ============="

