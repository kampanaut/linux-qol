#! /usr/bin/zsh

session_name=$(echo $1 | sed -n 's/.*{\(.*\)}.*/\1/p' | sed 's/^[ \t]*//;s/[ \t]*$//'); 
if [[  -n $session_name && -n "$(tmux list-sessions -F "#{session_name}" | grep "$session_name")"  ]]; then 
	echo -e "$(tmux list-sessions -F "[32m{ #S }[0m\n      |    [34m#I[0m windows (current: [33m#W[0m, last activity: ([35m#{session_activity}[0m)\n      |    session_created: ([35m#{session_created}[0m) host: [ [33m#{pane_title}[0m ]\n      |" 2>/dev/null)" | grep -A 3 $1;

	tmuxpath="$(tmux display-message -t $session_name -p '#{pane_current_path}')";
	tree -C -L 3 -I "node_modules|.git" $tmuxpath | head -n 26; 
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

