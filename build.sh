#!/bin/sh

echo "deploy type? [clean_gui|local|gui]: "
read deploy_type

# no matter what, we're doing this...

if [ "$deploy_type" = "clean_gui" ]; then
	echo "doing clean gui build."

	if [ -d "hey_libs" ]; then
		  rm -rf hey_libs
	fi
	mkdir -p hey_libs
	chicken-install -deploy -p hey_libs/ fmt
	chicken-install -deploy -p hey_libs/ loops
	chicken-install -deploy -p hey_libs/ sql-de-lite
	chicken-install -deploy -p hey_libs/ srfi-13
	chicken-install -deploy -p hey_libs/ srfi-1
	chicken-install -deploy -p hey_libs/ pathname-expand
	chicken-install -deploy -p hey_libs/ numbers
	chicken-install -deploy -p hey_libs/ json-abnf
elif [ "$deploy_type" = "local" ]; then
	echo "doing local build"
	csc hey.scm
fi

if [ "$deploy_type" = "clean_gui" ] || [ "$deploy_type" = "gui" ]; then
	# let's just make sure listicles is good and fresh
	csc -emit-all-import-libraries -explicit-use listicles.scm
	rm -rf hey.app
	csc -deploy -gui hey.scm
	cp listicles hey.app/Contents/MacOS/
	cp default.db hey.app/Contents/MacOS/
	cp -r hey_libs/* hey.app/Contents/MacOS/
	rm hey.app/Contents/Resources/CHICKEN.icns
	cp images/iconset.icns hey.app/Contents/Resources/CHICKEN.icns
	# perl -pi -e 's/CHICKEN.icns/iconfile.icns/g' hey.app/Contents/Info.plist

	echo "replace /Appications/hey.app ? [y|n]: "
	read replace_it
	if [ "$replace_it" = "y" ]; then 
		rm -rf /Applications/hey.app
		cp -r hey.app /Applications/
		echo "replaced."
	fi

fi


