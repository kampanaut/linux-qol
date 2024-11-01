#! /usr/bin/zsh

source ~/.globals

findprojectitems () {
	find $1 -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

list_projectdirs() {
	for dir in ${DYNAMIC_PROJDIRS}; do 
		output=$(basename $(dirname $dir))
		if [[ $output == "aunkquoi" ]]; then 
			output="Routome";
		fi
		echo -e "$output"
	done
	for dir in ${STATIC_PROJDIRS[@]}; do 
		basename $dir
	done
}

BASE_CHOICE=$(echo -e "$(list_projectdirs)" | fzf --header "Choose a volume" --preview-window=right:50% \
	--preview "projdirs=($(echo ${DYNAMIC_PROJDIRS[@]} ${STATIC_PROJDIRS[@]})); input='{}'; if [[ \"\$input\" == \"Routome\" ]]; then input=\"aunkquoi\"; fi; for dir in \${projdirs}; do if [[ \$(basename \$(dirname \$dir)) == \$input ]]; then tree -C -d -L 2 -I \"node_modules|.git\" \$(dirname \$dir)/Projects; exit; elif [[ \$(basename \$dir) == \$input ]]; then tree -C -d -L 1 -I \"node_modules|.git\" \$dir; exit; fi; done;")

base_choice=$BASE_CHOICE

if [[ -z $base_choice ]]; then 
	return;
fi

projdirs=("${DYNAMIC_PROJDIRS[@]}" "${STATIC_PROJDIRS[@]}"); 
root_dir="";

if [[ $base_choice == "Routome" ]]; then 
	base_choice="aunkquoi"; 
fi; 

static=0
for dir in ${projdirs}; do 
	if [[ $(basename $(dirname $dir)) == $base_choice ]]; then 
		root_dir=$dir
		break;
	elif [[ $(basename $dir) == $base_choice ]]; then 
		root_dir=$dir
		static=1
		break;
	fi; 
done;


CATEG_CHOICE=""
if [[ -n $base_choice ]]; then 
	for dir in ${DYNAMIC_PROJDIRS[@]}; do 
		if [[ $base_choice == $(basename $(dirname $dir)) ]]; then 
			CATEG_CHOICE=$(echo -e "$(findprojectitems $dir)" | fzf --print-query --header "Choose a category or Create one with - or ~ as prefix."\
				--preview-window=right:50% --preview "tree -C -L 1 -d -I \"node_modules|.git\" $root_dir/{}");

			categ_choice=$(echo -e "$CATEG_CHOICE" | sed -n '2p');
			categ_prompt=$(echo -e "$CATEG_CHOICE" | sed -n '1p');

			if [[ -n $categ_prompt ]]; then 
				if [[ $categ_prompt =~ ^(~|-) ]]; then 
					mkdir $root_dir/${categ_prompt:2}
					CATEG_CHOICE="${categ_prompt:2}/"
				elif [[ -z $categ_choice ]]; then
					mkdir $root_dir/${categ_prompt}
					CATEG_CHOICE="${categ_prompt}/"
				else 
					CATEG_CHOICE="${categ_choice}/"
				fi
			else
				CATEG_CHOICE="${categ_choice}/"
			fi
			break;
		fi
	done;
	if [[ -z $(echo $CATEG_CHOICE | tr -d '[:space:]') && $static -eq 0 ]]; then 
		 return;
	fi
	CREATED_CHOICE=$(echo -e "$(findprojectitems $root_dir/$CATEG_CHOICE)" | fzf --print-query --header "Enter prompt the project name you want to create." \
		--preview-window=right:50% --preview "tree -C -L 2 -I \"node_modules|.git\" '$root_dir/$CATEG_CHOICE{}'");

	created_choice=$(echo -e "$CREATED_CHOICE" | sed -n '2p');
	created_prompt=$(echo -e "$CREATED_CHOICE" | sed -n '1p') 
	if [[ (-z $created_choice || $created_choice != $created_prompt) && -n $created_prompt ]]; then 
		if [[ $created_prompt =~ ^(~|-) ]]; then
			created_prompt=${created_prompt:2};
			if [[ -z $(echo $created_prompt | tr -d '[:space:]') ]]; then 
				 return;
			fi
		fi
		mkdir "$root_dir/$CATEG_CHOICE$created_prompt"
		if [[ -n $(tmux list-sessions -F "#S" | grep "^/$created_prompt$") ]]; then 
			if [ -n "$TMUX" ]; then
				tmux display-message -d 1000 "Project created. There's already a session { $created_prompt }"
				full_path="$root_dir/$CATEG_CHOICE$created_prompt"
				session_pname="/$(echo ${full_path#/*/} | tr '[:upper:]' '[:lower:]' | sed "s/projects\///g" | sed "s/$(basename $HOME)/routome/" )"
				if [[ $(tmux display-message -p "#S") == /$created_prompt && $(tmux display-message -p "#{pane_current_path}") == $HOME ]]; then 
					cd "$root_dir/$CATEG_CHOICE$created_prompt";
				elif [[ -z $(tmux list-session -F "#S" | grep "^$session_pname$" ) ]]; then 
					tmux new-session -s "$session_pname" -d -c "$full_path";
					tmux rename-window -t "$session_pname:1" "main"
					tmux new-window -t "$session_pname" -n "${session_pname}-abut" -c "$full_path"
					tmux select-window -t "$session_pname:main"
					tmux switch-client -t "$session_pname"
				fi
			else
				echo "Project created. There's already a session { $created_prompt }"
			fi
			return;
		fi
		tmux new-session -s "/$created_prompt" -d -c "$root_dir/$CATEG_CHOICE$created_prompt";
		tmux rename-window -t "/$created_prompt:1" "main"
		tmux new-window -t "/$created_prompt" -n "/${created_prompt}-abut" -c "$root_dir/$CATEG_CHOICE$created_prompt"
		tmux select-window -t "/$created_prompt:main"
		if [ -n "$TMUX" ]; then
			tmux switch-client -t "/$created_prompt"
		else
			tmux attach-session -t "/$created_prompt"
		fi
	elif [[ -n $created_choice ]]; then
		if [[ -n $(tmux list-sessions -F "#S" | grep "^/$created_choice$") ]]; then 
			if [ -n "$TMUX" ]; then
				tmux display-message -d 1000 "Project created. There's already a session { $created_choice }"
				full_path="$root_dir/$CATEG_CHOICE$created_choice"
				session_pname="/$(echo ${full_path#/*/} | tr '[:upper:]' '[:lower:]' | sed "s/projects\///g" | sed "s/$(basename $HOME)/routome/" )"
				if [[ $(tmux display-message -p "#S") == /$created_choice && $(tmux display-message -p "#{pane_current_path}") == $HOME ]]; then 
					cd "$root_dir/$CATEG_CHOICE$created_choice";
				elif [[ -z $(tmux list-session -F "#S" | grep "^$session_pname$" ) ]]; then 
					tmux new-session -s "$session_pname" -d -c "$full_path";
					tmux rename-window -t "$session_pname:1" "main"
					tmux new-window -t "$session_pname" -n "${session_pname}-abut" -c "$full_path"
					tmux select-window -t "$session_pname:main"
					tmux switch-client -t "$session_pname"
				fi
			else
				echo "Project created. There's already a session { $created_choice }"
			fi
			return;
		fi
		tmux new-session -s "/$created_choice" -d -c "$root_dir/$CATEG_CHOICE$created_choice";
		tmux rename-window -t "/$created_choice:1" "main"
		tmux new-window -t "/$created_choice" -n "/${created_choice}-abut" -c "$root_dir/$CATEG_CHOICE$created_choice"
		tmux select-window -t "/$created_choice:main"
		if [ -n "$TMUX" ]; then
			tmux switch-client -t "/$created_choice"
		else
			tmux attach-session -t "/$created_choice"
		fi
	fi

fi


