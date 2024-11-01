#!/bin/zsh

if [ -n "$TMUX" ]; then
	echo "Already inside TMUX!";
	return;
fi

source ~/.globals

IFS=',' read -rA PROJECTS_DIRS <<< "$PROJECTS_DIRS";

typeset -A unique_projects;

# Function to list project directories
list_all() {
	sessions=$(tmux list-sessions -F "#{session_created} { #{session_name} }" 2>/dev/null | sort -rn | awk '{ $1=""; print substr($0,2) }')
	if [[ -n $sessions ]]; then
		echo "$sessions"
	fi
	for dir in "${PROJECTS_DIRS[@]}"; do
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

	for uniq in "${(@k)unique_projects[@]}"; do
		if [[ -z $(echo ${unique_projects[$uniq]} | grep ":") ]]; then
			echo $uniq
		else
			count=$(echo ${unique_projects[$uniq]} | grep -o ":" | wc -l)
			count=$(($count + 1))
			echo "$uniq <$count>"
		fi
	done
}

setup_uniques() {
	for dir in "${PROJECTS_DIRS[@]}"; do
		output="$output$(find "$dir" -mindepth 1 -maxdepth 1 -type d -exec printf '%s,' {} + 2>/dev/null)"
	done

	output=${output[1,-2]}

	output_unique=$output

	IFS=',' read -rA output_unique <<< "$output_unique";

	for dir in "${output_unique[@]}"; do
		basename=$(basename $dir);
		if [[ -v unique_projects[/$basename] ]]; then
			unique_projects[/$basename]="${unique_projects[/$basename]}:$dir";
		else
			unique_projects[/$basename]="$dir";
		fi
	done
}

# Use fzf to choose an option with preview
CHOICE=$(echo -e "$(list_all)" | fzf --print-query --header "Select Project or Session (Press Enter for new session)" --preview-window=right:50%\
	--preview "~/.config/tmux/scripts/fzf/fzf-start-chooser-preview-base.sh {}")

# Create a new tmux session if no choice is made
if [[ -z $(echo $CHOICE | tr -d '[:space:]') ]]; then
	tmux new-session;
	return 1;
fi

# if query starts tilde
if [[ $CHOICE =~ ^(~|-) ]]; then 
	choice=$(echo ${CHOICE:2} | sed -n '1p' | awk '{$1=$1; print}' | sed 's/^[ \t]*//;s/[ \t]*$//');
	tmux new-session -d -s "$choice" -c "~"
	tmux rename-window -t "$choice:1" "main"
	tmux new-window -t "$choice" -n "${choice}-abut" -c "~"
	tmux select-window -t "$choice:main"
	tmux attach-session -t "$session_name"
	return 1
fi

if [[ $CHOICE =~ \}$ ]]; then 
	choice=$(echo $CHOICE | sed -n '2p' | sed -n 's/.*{\(.*\)}.*/\1/p' | sed 's/^[ \t]*//;s/[ \t]*$//')
	tmux attach-session -t "$choice";
	return 1;
fi

setup_uniques;
choice=$(echo $CHOICE | sed -n '2p');

if [[ -z $choice ]]; then
	if [[ -n $(tmux list-sessions -F "#S" | grep "^$choice$") ]]; then
		tmux switch-client -t "$choice";
		return;
	fi
	choice=$(echo $CHOICE | sed -n '1p' | awk '{$1=$1; print}' | sed 's/^[ \t]*//;s/[ \t]*$//');
	tmux new-session -s "$choice" -d -c "~";
	tmux rename-window -t "$choice:1" "main"
	tmux new-window -t "$choice" -n "${choice}-abut" -c "~"
	tmux select-window -t "$choice:main"
	tmux attach-session -t "$session_name"
	return;
fi

if [[ -v unique_projects[${choice[1,-5]}] ]]; then 
	SecondCHOICE=$(echo -e "${unique_projects[${choice[1,-5]}]//:/\\n}" | fzf --print-query --header "Specify which Project" --preview-window=right:50% \
		--preview "tree -C -L 3 -I \"node_modules|.git\" {}");

	choice=$(echo $SecondCHOICE | sed -n '2p');

	if [[ -z $choice ]]; then
		return;
	else
		if [[ -n $(tmux list-sessions -F "#S" | grep "^/$(basename $choice)$") ]]; then
			session_pname="/$(echo ${choice#/*/} | tr '[:upper:]' '[:lower:]' | sed "s/projects\///g" | sed "s/$(basename $HOME)/routome/" )"
			if [[ -z $(tmux list-session -F "#S" | grep "^$session_pname$" ) && $(tmux -p display-message -t "/$(basename $choice)" "#{pane_current_path}") != $choice ]]; then 
				tmux new-session -s "$session_pname" -d -c "$choice";
				tmux rename-window -t "$session_pname:1" "main"
				tmux new-window -t "$session_pname" -n "${session_pname}-abut" -c "$choice"
				tmux select-window -t "$session_pname:main"
				tmux attach-session -t "$session_pname"
			else
				if [[ $(tmux display-message -p "#S") == $choice ]]; then 
					tmux display-message -d 1000 "Project session created. You are already inside same named session { $choice }."
				else
					tmux display-message -d 1000 "Project session created. There's already a session { $choice }."
				fi
				tmux switch-client -t "$session_pname";
			fi
			return;
		else
			basename=$(basename $choice)
			tmux new-session -s "/$basename" -d -c "$choice";
			tmux rename-window -t "/$basename:1" "main"
			tmux new-window -t "/$basename" -n "/${basename}-abut" -c "$choice"
			tmux select-window -t "/$basename:main"
			tmux attach-session -t "/$basename"
		fi
		return;
	fi
fi

# check if the entry is a project i.e. a directory
for dir in ${PROJECTS_DIRS[@]}; do 
	if [[ -d $dir$choice ]]; then 
		# Change to the selected project directory and create a new session
		basename="$(basename $basename)"
		if [[ -n $(tmux list-sessions -F "#S" | grep "^$basename$") ]]; then 
			tmux attach-session -t "$basename";
			if [[ $(tmux display-message -p "#S") == $basename ]]; then 
				tmux display-message -d 1000 "Project session created. You are already inside same named session { $basename }."
			else
				tmux display-message -d 1000 "Project session created. There's already a session { $basename }."
			fi
			return 1;
		fi
		tmux new-session -d -s "$choice" -c $dir$choice
		tmux rename-window -t "$choice:1" "main"
		tmux new-window -t "$choice" -n "${choice}-abut" -c "$dir$choice"
		tmux select-window -t "$choice:main"
		tmux attach-session -t "$session_name"
		return 1;
	fi; 
done;
