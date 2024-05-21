# Record all commands done in transcript window
transcript on

# Remove previous contents in pr directory
rm -rf ./pr

set project_name 		pr_sim
set base_revision_name 	top
set static_qdb_name 	top_static.qdb

set root_partition		root_partition
set pr_partition		pr_partition

set persona_names {
	and_gate
	counter
	fsm
}

#######################################
# Make PR Persona Sim Models
#######################################

puts "Running Analysis & Synthesis on base revision"
# quartus_syn <project name> -c <base revision name>
quartus_syn $project_name -c $base_revision_name

puts "Exporting base partition from base revision"
#quartus_cdb <project name> -c <base revision name> --export_block root_partition --snapshot synthesized --file <static qdb name>
quartus_cdb $project_name -c $base_revision_name --export_block $root_partition --snapshot synthesized --file $static_qdb_name


#######################################
# Make Each Persona Sim Model
#######################################

foreach persona_name $persona_names {
	
	puts "Running Analysis & Synthesis on persona revision: $persona_name"
	# quartus_syn <project name> -c <persona revision name>
	quartus_syn $project_name -c $persona_name

	puts "Make PR sim model for $persona_name persona"
	#quartus_eda <project name> –c <persona revision name> --pr --simulation --tool=questasim --format=verilog --partition=<pr partition name> --module=<partition name>=<persona module name>
	quartus_eda $project_name -c $persona_name --pr --simulation --tool=questasim --format=verilog --partition=$pr_partition --module=$pr_partition=$persona_name
}
