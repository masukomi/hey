
EXPECTED_PATH=""


function install_cli_tool {
	HEY_APP_PATH=$1
	if [ "$(uname)" = "Darwin" ]; then
		if [[ $HEY_APP_PATH == *"hey.app"* ]]; then
			HEY_APP_PATH="$HEY_APP_PATH/Contents/MacOS/"
		fi
	fi
	echo "---------------------------------------------------------------"
	echo "Where should I install the hey cli tool? "
	echo "Here are all the writable directories on your PATH:"

	arrPATH=(${PATH//:/ })
	count=0
	for i in "${arrPATH[@]}"
	do
	    if [ -w "$i" ]; then
		  count=$((count+1))
		  echo "$count: $i" 
	    fi
	done
	echo ""
	echo "Which one would you like the cli tool installed in? [number]: "
	read number

	arrPATH=(${PATH//:/ })
	count=0
	installed=0
	for i in "${arrPATH[@]}"
	do
		if [ -w "$i" ]; then
			count=$((count+1))
			if [ "$count" = "$number" ]; then
				echo "installing hey cli tool in $i"
				cat > "$i/hey" << EOM
#!/bin/sh

(cd $HEY_APP_PATH && ./hey "\$@")

EOM
				chmod 755 "$i/hey"

				installed=1
			fi
		fi
		# echo "$count: $i" 
	done
	if [ $installed -eq 0 ]; then
		echo "um... you didn't enter a number I recognized."
		echo "Please start over, you silly human."
		exit 2
	fi

}

