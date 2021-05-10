#This include file contains functions related to UI, so functions that help print information to the terminal, poll the user for info, or both.

###########
# Colors
##########

#See https://www.shellhacks.com/bash-colors/ for more colors and other effects.

#FYI, colors in bash is wonky and uses a special escape code to get it to work.
# Escape code denoting a color: \033[  then the color code, then end the escape sequence with 'm'
# Color will effect everything until you use the NOCLR code, so make sure to end the coloring.
NOCLR='\033[0m'     #code: 0
GREEN='\033[32m'    #code: 32
RED='\033[31m'      #code: 31
YELLOW='\033[1;33m' #code: 33 Note: the 1 allows yellow to be bolded making it show up a bit better on terminals.
BLUE='\033[34m'     #code: 34


############
# Logging Functions
###########


# Logs a simple message to StdOut. May have it write to a log or be colored at some point so nice to have a centeral function handle this.
## Needs 1 argument, the message to be printed.
log_msg() {
    echo -e "$1"
}


# Logs an error using a red prefix to denote it as such.
## Needs 1 argument, the message to be printed.
log_err() {
    echo -e "${RED}/!\\ Error /!\\: $1 $NOCLR"
}


# Logs some information about a script.
## Needs 3 arguments, description, usage, and example text.
help_text() {
    #Note: -r means readonly. There is no long arg so had to use the short one.
    local -r DESCRIPTION=$1
    local -r USAGE=$2
    local -r EXAMPLE=$3

    #Describes highlevel use for the script
    log_msg "${YELLOW}Description: $DESCRIPTION"

    echo "" # newline spacer

    #Explaining what each argument does.
    log_msg "Usage: $USAGE"

    echo "" # newline spacer

    #Example command(s) to show how to use the scripts.
    log_msg "Example: $EXAMPLE${NOCLR}"
}



################
# Task Relate UI Functions
################

# Simple function that waits for a key press to continue.
## Needs no arguments.
ui_press_any_key() {
    log_msg ">>> Press any key to continue <<<"
    local proceed
    read proceed
}

# Prints out a "Section" label and waits for user input before continuing.
## Needs 1 argument, a string dennoting the section's name.
ui_section() {
    local title=$1
    log_msg "$(cat <<- HEREDOC
	###############
	#
	# $title
	#
	##############
	HEREDOC
    )"

    ui_press_any_key
}


# Prints out a start task lable and waits for user input to continue
## Needs 1 argument, string with name describing the task
ui_start_task() {
    local title=$1
    log_msg "$(cat <<- HEREDOC
	-------------------------------------------
	... Begining Task: ${GREEN}${title}${NOCLR} ...
	HEREDOC
    )"

    ui_press_any_key
}

# Prints out text dennoting a task has ended
## Needs no arguments
ui_end_task() {
    log_msg "$(cat <<- HEREDOC

	... ${BLUE}Task Done${NOCLR} ...
	------------------------------------------
	HEREDOC
    )"
}

# Prints out a note formated to look like it's part of the task
## Needs 1 argument, string containing the note to print.
ui_task_note() {
    local note=$1
    log_msg "--- ${BLUE}${note}${NOCLR}"
}
