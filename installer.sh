#!/bin/sh

echo "Ready to install hey? [y|n]: "
read install

HEY_APP_PATH="/Applications/hey.app"
FOUND_AT_DEFAULT=false
function test_app_at_default_loc {
	if [ -d "$HEY_APP_PATH" ]; then
		FOUND_AT_DEFAULT=true
	else
		FOUND_AT_DEFAULT=true
	fi
}

if [ "$install" != "y" ]; then
	echo "Oh, well. I'll wait until you are."
	exit 0
else
	test_app_at_default_loc

	if [ "$FOUND_AT_DEFAULT" != true ]; then
		echo "Um. I was expecting to find hey.app at $HEY_APP_PATH"
		if [ -d "./hey.app" ]; then
			echo "I found it right beside me though. Can I move it to $HEY_APP_PATH ? [y|n]"
			read move_to_default
			if [ "$move_to_default" = "y" ]; then
				cp -r ./hey.app $HEY_APP_PATH
				test_app_at_default_loc
				if [ "$FOUND_AT_DEFAULT" != true ]; then
					echo "um... that didn't work. Can you please move it to"
					echo "$HEY_APP_PATH and then run me again?"
					exit 1
				fi
			fi
		else
			echo "I'm not sure where it is. "
			echo "Please enter the path to where hey.app lives: "
			read HEY_APP_PATH
			echo "Thanks. Moving on..."
		fi
	fi

	echo "Where should I put it? Here are all the directories on your PATH:"

	arrPATH=(${PATH//:/ })
	count=0
	for i in "${arrPATH[@]}"
	do
		count=$((count+1))
		echo "$count: $i" 
	done
	echo ""
	echo "Which one would you like the cli tool installed in? [number]: "
	read number

	arrPATH=(${PATH//:/ })
	count=0
	installed=0
	for i in "${arrPATH[@]}"
	do
		count=$((count+1))
		if [ "$count" = "$number" ]; then
			echo "installing in $i"
			cat > "$i/hey" << EOM
#!/bin/sh

(cd $HEY_APP_PATH/Contents/MacOS && HEY_DB="\$HEY_DB" ./hey "\$@")

EOM
			chmod 755 "$i/hey"

			echo "Done. Happy tracking."
			installed=1
		fi
		# echo "$count: $i" 
	done

	if [ $installed -eq 0 ]; then
		echo "um... you didn't enter a number I recognized."
		echo "Please start over, you silly human."
	fi

	#TODO copy $HEY_APP_PATH/Contents/MacOS/default.db ~/default/db/loc


fi
