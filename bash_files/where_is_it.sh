	if [ "$(uname)" = "Darwin" ]; then 
		if [ -d "/Applications/hey.app" ]; then
			EXPECTED_PATH="/Applications/hey.app"
		fi
	fi
	if [ "$EXPECTED_PATH" = "" ]; then
		if [ "$(uname)" = "Darwin" ]; then
			echo "Please enter the path to hey.app"
		else
			echo "Please enter the path to the 'hey_libs' folder."
		fi
		echo "It's fine if you renamed it."
		read EXPECTED_PATH
	fi
	if [ "$EXPECTED_PATH" = "" ]; then
		echo "You need to tell me where or I can't do my job. :("
		exit 1
	fi

