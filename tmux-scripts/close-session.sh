#! /usr/bin/zsh

current_session=$(tmux display-message -p '#S' 2>/dev/null ); 
last_session=$(tmux display-message -p '#{client_last_session}')

if [[ -z $last_session ]]; then 
	tmux switch-client -n 2>/dev/null ; 
else
	tmux switch-client -l 2>/dev/null ; 
fi

tmux kill-session -t "$current_session" 2>/dev/null ;
exit 0;
