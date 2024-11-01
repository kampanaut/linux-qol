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
			CATEG_CHOICE=$(echo -e "$(findprojectitems $dir)" | fzf --print-query --header "Choose the category of project you want to delete."\
				--preview-window=right:50% --preview "tree -C -L 1 -d -I \"node_modules|.git\" "$root_dir"/{}");

			categ_choice=$(echo -e "$CATEG_CHOICE" | sed -n '2p');
			categ_prompt=$(echo -e "$CATEG_CHOICE" | sed -n '1p');

			if [[ -n $categ_prompt ]]; then 
				if [[ -z $categ_choice ]]; then
					CATEG_CHOICE="";
				else 
					CATEG_CHOICE="${categ_choice}/";
				fi
			else
				CATEG_CHOICE="${categ_choice}/";
			fi
			break;
		fi
	done;
	if [[ -z $(echo $CATEG_CHOICE | tr -d '[:space:]') && $static -eq 0 ]]; then 
		 return;
	fi
	REMOVE_CHOICE=$(echo -e "$(findprojectitems $root_dir/$CATEG_CHOICE)" | fzf --print-query --header "[DELETE PROJECT] Highlighted project will be deleted." \
		--preview-window=right:50% --preview "project={}; tree -C -L 2 -I \"node_modules|.git\" \""$root_dir/""$CATEG_CHOICE"\$project\"");

	remove_choice=$(echo -e "$REMOVE_CHOICE" | sed -n '2p');
	remove_prompt=$(echo -e "$REMOVE_CHOICE" | sed -n '1p') 
	if [[ (-z $remove_choice || $remove_choice != $remove_prompt) && -n $remove_prompt ]]; then 
		echo "Nothing to be removed. Type the thing you wanna delete completely if you wanna search!";
		return;
	elif [[ -n $remove_choice ]]; then
		rm -rfi "$root_dir/$CATEG_CHOICE$remove_choice"
	fi
fi
