#!/bin/sh

EXPECTED_PATH="/Applications/hey.app"
FOUND_AT_DEFAULT=false

eval "$(cat "bash_files/ask.sh")"

source bash_files/install_cli_tool.sh


function test_app_at_default_loc {
	if [ -d "$EXPECTED_PATH" ]; then
		FOUND_AT_DEFAULT=true
	else
		FOUND_AT_DEFAULT=true
	fi
}

if ! ask "Ready to install hey?"; then
	echo "Oh, well. I'll wait until you are."
	exit 0
else
	eval "$(cat "bash_files/where_is_it.sh")"
	if [ -d $EXPECTED_PATH ]; then
		echo "Um. I was expecting to find it at $EXPECTED_PATH"
		echo "I'm not sure where it is. "
		if [ "$(uname)" = "Darwin" ]; then
			echo "Please enter the path to hey.app"
		else
			echo "Please enter the path to the 'hey_libs' folder."
		fi
		read EXPECTED_PATH
		echo "Thanks. Moving on..."
	fi

	install_cli_tool $EXPECTED_PATH
	
	mkdir -p $HOME/.config/hey
	if [ "$(uname)" = "Darwin" ]; then
		if [[ $EXPECTED_PATH == *"hey.app"* ]]; then
			DB_PATH=$EXPECTED_PATH/Contents/MacOS/database.db
		fi
	else
		DB_PATH=$EXPECTED_PATH/database.db
	fi

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
		cp default.db $DB_PATH
	else
		echo "---------------------------------------------------------------"
		echo "DB already exists at $DB_PATH"
		echo "I won't overwrite." 
		echo "If you'd like to replace it with an empty one, run this command:"
		echo "cp default.db $DB_PATH"
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
