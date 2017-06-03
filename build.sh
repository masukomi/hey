#!/bin/sh

function compile_modules {
	csc -emit-all-import-libraries -explicit-use listicles.scm
	csc -emit-all-import-libraries -explicit-use interrupt-database.scm
	csc -emit-all-import-libraries -explicit-use uri-tools.scm
	csc -emit-all-import-libraries -explicit-use hey-dates.scm
	csc -emit-all-import-libraries -explicit-use people-by-hour-report.scm
}

deploy_type=$1
if [ "$deploy_type" = "" ]; then
	echo "deploy type? [libraries|local|gui|dmg|modules]: "
	read deploy_type
fi

if [ "$deploy_type" = "libraries" ]; then
	echo "doing clean gui build."

	if [ -d "hey_libs" ]; then
		  rm -rf hey_libs
	fi
	mkdir -p hey_libs
	chicken-install fmt
	chicken-install -deploy -p hey_libs/ fmt
	chicken-install loops
	chicken-install -deploy -p hey_libs/ loops
	chicken-install sql-de-lite
	chicken-install -deploy -p hey_libs/ sql-de-lite
	chicken-install srfi-13
	chicken-install -deploy -p hey_libs/ srfi-13
	chicken-install srfi-1
	chicken-install -deploy -p hey_libs/ srfi-1
	chicken-install pathname-expand
	chicken-install -deploy -p hey_libs/ pathname-expand
	chicken-install numbers
	chicken-install -deploy -p hey_libs/ numbers
	chicken-install json-abnf
	chicken-install -deploy -p hey_libs/ json-abnf
	chicken-install json
	chicken-install -deploy -p hey_libs/ json
	chicken-install uri-common
	chicken-install -deploy -p hey_libs/ uri-common
	chicken-install shell
	chicken-install -deploy -p hey_libs/ shell
elif [ "$deploy_type" = "local" ]; then
	echo "doing local build"
	csc hey.scm
elif [ "$deploy_type" = "modules" ]; then
	compile_modules
elif [ "$deploy_type" = "gui" ]; then
	# let's just make sure listicles is good and fresh
	compile_modules
	rm -rf hey.app
	csc -deploy -gui hey.scm
	cp listicles hey.app/Contents/MacOS/
	cp interrupt-database hey.app/Contents/MacOS/
	cp people-by-hour-report hey.app/Contents/MacOS/
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
elif [ "$deploy_type" = "dmg" ]; then
  rm html/downloads/hey.dmg
  appdmg appdmg.json html/downloads/hey.dmg
fi


