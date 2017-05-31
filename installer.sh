#!/bin/sh

HEY_APP_PATH="/Applications/hey.app"
FOUND_AT_DEFAULT=false


ask() {
    # https://djm.me/ask
    local prompt default REPLY

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}


function test_app_at_default_loc {
	if [ -d "$HEY_APP_PATH" ]; then
		FOUND_AT_DEFAULT=true
	else
		FOUND_AT_DEFAULT=true
	fi
}

if ! ask "Ready to install hey?"; then
	echo "Oh, well. I'll wait until you are."
	exit 0
else
	test_app_at_default_loc

	if [ "$FOUND_AT_DEFAULT" != true ]; then
		echo "Um. I was expecting to find hey.app at $HEY_APP_PATH"
		if [ -d "./hey.app" ]; then
			if ask "I found it right beside me though. Can I move it to $HEY_APP_PATH ?"; then
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
				echo "installing in $i"
				cat > "$i/hey" << EOM
#!/bin/sh

(cd $HEY_APP_PATH/Contents/MacOS && HEY_DB="\$HEY_DB" ./hey "\$@")

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

	mkdir -p $HOME/.config/hey
	DB_PATH=$HEY_APP_PATH/Contents/MacOS/database.db
	if [ -e "$HOME/Dropbox" ]; then
		echo "---------------------------------------------------------------"
		echo "Hey, I see you use Dropbox. I'd suggest saving your db there."
		echo "That way you can easily share it across computers."
		if ask "Is that ok?"; then
			mkdir -p $HOME/Dropbox/apps/hey/database/
			DB_PATH=$HOME/Dropbox/apps/hey/database/hey.db
		fi
	fi
	if [ ! -e "$DB_PATH" ];then
		cp $HEY_APP_PATH/Contents/MacOS/default.db $DB_PATH
	else
		echo "---------------------------------------------------------------"
		echo "DB already exists at $DB_PATH"
		echo "I won't overwrite." 
		echo "If you'd like to replace it with an empty one, run this command:"
		echo "cp $HEY_APP_PATH/Contents/MacOS/default.db $DB_PATH"
	fi
	cat > $HOME/.config/hey/config.json <<EOM
{
  "HEY_DB": "$DB_PATH"
}
EOM
	echo "---------------------------------------------------------------"
	echo "Your DB is installed at $DB_PATH"
	echo "If you choose to move it you will need to update the path in"
	echo "~/.config/hey/config.json"
	echo "Done. Happy tracking."
	echo ""
	echo "Usage instructions: https://interrupttracker.com/usage.html"


fi
