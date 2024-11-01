#! /usr/bin/zsh
if [[ -d $1 ]]; then 
	cd $1 && nvim;
else
	echo "Not valid directory $1"
fi
