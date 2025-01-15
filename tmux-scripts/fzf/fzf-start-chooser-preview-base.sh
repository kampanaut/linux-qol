#! /usr/bin/zsh

session_name=$(echo $1 | sed -n 's/.*{\(.*\)}.*/\1/p' | sed 's/^[ \t]*//;s/[ \t]*$//'); 
if [[  -n $session_name && -n "$(tmux list-sessions -F "#{session_name}" | grep "$session_name")"  ]]; then 

	raw_details=$(tmux display-message -p -t $session_name "#{window_index},#{window_name},#{session_activity},#{session_created},#{pane_title}")
	
	# Create array from comma-separated values
	IFS=',' read -rA details <<< "$raw_details";
	
	window_index="${details[1]}"
	window_name="${details[2]}"
	activity="${details[3]}"
	created="${details[4]}"
	pane_title="${details[5]}"

	activity_date=$(date -d "@${activity}" "+%A at %I:%M %p" 2>/dev/null || echo "unknown")
	created_date=$(date -d "@${created}" "+%A at %I:%M %p" 2>/dev/null || echo "unknown")


	formatted_details=$(cat << EOF
     │  \e[34m$window_index\e[0m windows (current: \e[33m$window_name\e[0m), last activity: (\e[35m$activity_date\e[0m)
     │  session_created: (\e[35m$created_date\e[0m) host: [ \e[33m$pane_title\e[0m ]
EOF
)

	echo -e "{ [32m$session_name[0m }\n$formatted_details"

	tmuxpath="$(tmux display-message -t $session_name -p '#{pane_current_path}')";

	pane_pid=$(tmux display-message -p -t $session_name "#{pane_pid}")
	current_program=$(ps -o comm= -p $(pgrep -P $pane_pid) 2>/dev/null | tail -n1)

	[[ -z "$current_program" ]] && current_program=$(tmux display-message -p -t $session_name "#{pane_current_command}")
	if [[ "$current_program" == "nvim-handler" ]]; then
		current_program="nvim (handler)"
	fi
	echo -e "\n━━━━━━━━ { \e[34m${current_program}\e[0m } ━━ ⟬ \e[35m${tmuxpath}\e[0m ⟭ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[0m\n";
    
    tmux capture-pane -p -e -t "$session_name" | head -n 40

	echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[0m\n"
else 
	source ~/.globals

	IFS=',' read -rA projects_dirs <<< "$PROJECTS_DIRS[@]"; 
	for dir in ${projects_dirs[@]}; do  
		dir=$(echo -e "$dir"$1); 
		if [[ -d $dir ]]; then 
			tree -C -L 3 -I "node_modules|.git" $dir; 
			exit; 
		elif [[ $1 =~ \<[0-9]+\>$ ]]; then
			output="";
			for dir in "${projects_dirs[@]}"; do
				output="$output$(find "$dir" -mindepth 1 -maxdepth 1 -type d -exec printf '%s,' {} + 2>/dev/null)"
			done

			output=${output[1,-2]}

			output_unique=$output
			typeset -A unique_projects;
			IFS=',' read -rA output_unique <<< "$output_unique";

			for dir in "${output_unique[@]}"; do
				basename=$(basename $dir);
				if [[ -v unique_projects[/$basename] ]]; then
					unique_projects[/$basename]="${unique_projects[/$basename]}:$dir";
				else
					unique_projects[/$basename]="$dir";
				fi
			done

			input=${1[1,-5]};
			projdups=${unique_projects[$input]};
			IFS=':' read -rA projdups <<< "$projdups";

			echo "Name grouped by [ ${input:1} ]\n";
			for dir in "${projdups[@]}"; do 
				tree -C -L 3 -I "node_modules|.git" $dir | head -n 30; 
			done
			exit;
		fi; 
	done; 
	echo "No preview available"; 
fi;
