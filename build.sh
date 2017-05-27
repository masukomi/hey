#!/bin/sh

echo "deploy type? [clean_gui|local|gui]: "
read deploy_type

if [ "$deploy_type" = "clean_gui" ]; then
	echo "doing clean gui build."

	if [ -d "hey" ]; then
		  rm -rf hey
	fi
	mkdir -p hey
	chicken-install -deploy -p hey/ fmt
	chicken-install -deploy -p hey/ loops
	chicken-install -deploy -p hey/ sql-de-lite
	chicken-install -deploy -p hey/ srfi-13
	chicken-install -deploy -p hey/ srfi-1
	chicken-install -deploy -p hey/ pathname-expand
	chicken-install -deploy -p hey/ numbers
	chicken-install -deploy -p hey/ toml
elif [ "$deploy_type" = "local" ]; then
	echo "doing local build"
	csc hey.scm
fi

if [ "$deploy_type" = "clean_gui" ] || [ "$deploy_type" = "gui" ]; then
	rm -rf hey.app
	csc -deploy -gui hey.scm
	cp listicles.so hey.app/Contents/MacOS/
	cp default.db hey.app/Contents/MacOS/
	cp -r hey/* hey.app/Contents/MacOS/

	echo "replace /Appications/hey.app ? [y|n]: "
	read replace_it
	if [ "$replace_it" = "y" ]; then 
		rm -rf /Applications/hey.app
		cp -r hey.app /Applications/
		echo "replaced."
	fi

fi


