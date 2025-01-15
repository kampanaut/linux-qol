#! /usr/bin/zsh

list_all() {
	sessions=$(tmux list-sessions -F "#{session_created} { #{session_name} }" 2>/dev/null | sort -rn | awk '{ $1=""; print substr($0,2) }')
	echo "$sessions"
}

# Use fzf to choose an option with preview
CHOICE=$(echo -e "$(list_all)" | fzf --print-query --header "[KILLER] Select Project or Session to kill (Press Enter for new session)" --preview-window=right:50%\
	--preview "~/.config/tmux/scripts/fzf/fzf-start-chooser-preview-base.sh {}")


if [[ -z $(echo $CHOICE | tr -d '[:space:]') ]]; then 
	 return;
fi

current_session=$(tmux display-message -p '#S' 2>/dev/null);

if [[ $CHOICE =~ \}$ ]]; then 
	choice=$(echo $CHOICE | sed -n '2p' | sed -n 's/.*{\(.*\)}.*/\1/p' | sed 's/^[ \t]*//;s/[ \t]*$//')
	if [[ $current_session == $choice ]]; then 
		source ~/.config/tmux/scripts/close-session.sh
		return;
	fi
	tmux kill-session -t "$choice";
	return;
fi


