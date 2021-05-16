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
## Needs 1 argument, the message to be printed. Optionally will pass anything in second argument as aditional options to echo.
log_msg() {
    echo -e "$2" "$1"
}


# Logs an error using a red prefix to denote it as such.
## Needs 1 argument, the message to be printed.
log_err() {
    echo -e "${RED}/!\\ ERROR /!\\: $1 ${NOCLR}"
}


# Logs a warning. Message that is colored and formatted to draw attention to itself but is not nessisarily bad.
## Needs 1 argument, message to print
log_warn(){
    echo -e "${YELLOW} [WARNING]: $1 ${NOCLR}"
}


# Logs some information about a script.
## Needs 3 arguments, description, usage, and example text.
help_text() {
    #Note: -r means readonly. There is no long arg so had to use the short one.
    local -r DESCRIPTION=$1
    local -r USAGE=$2
    local -r EXAMPLE=$3

    #Describes highlevel use for the script
    log_msg "${GREEN}Description: $DESCRIPTION"

    echo "" # newline spacer

    #Explaining what each argument does.
    log_msg "Usage: $USAGE"

    echo "" # newline spacer

    #Example command(s) to show how to use the scripts.
    log_msg "Example: $EXAMPLE${NOCLR}"
}


################
# User Input Functions
################

# Simple function that waits for a key press to continue.
## Needs no arguments.
ui_press_any_key() {
    log_msg ">>> Press any key to continue <<<"
    local proceed
    read -n 1 -s proceed 
    # -n x reads x characters instead of waiting for a newline. so triggers after pressing any keys 
    # -s makes read no echo typed characters
}


# Requests a Y/n answer and returns fail or sucess based on the answer
## Optionally needs 2 args, a string that is a msg to print and a optional letter (y or n) that indicates the default
##Returns 0 if yes was selected and 1 if no was selected
ui_query_yn() {
    local msg=$1
    local default_choice=$2
    
    #First define what the option string should be and make the default choice a returnable value (exit code)
    if [[ "$default_choice" == "y" || "$default_choice" == "yes" ]]; then
        local option_str="[Y/n]"
	default_choice=0
    else
        local option_str="[y/N]"
	default_choice=1
    fi
    
    local answer

    #Next do a loop where we look for a specific answer. We keep going until we return from the function
    while true; do
        #tell user what they are inputing for, and the default answer. Also don't add a new line.
        log_msg ">>> ${msg} ${option_str}: " "-n"

        read answer

	#force input to be lower case so we have to test against fewer options
        answer="$(echo "$answer" | tr "[:upper:]" "[:lower:]" )"

	#determin what the answer is and return the appropriate exit code
        if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
            log_msg "<<< Ok, you said $answer"
            return 0
        elif [[ "$answer" == "n" || "$answer" == "no" ]]; then
            log_msg "<<< Ok, you said $answer"
            return 1
	elif [[ -z $answer ]]; then
            log_msg "<<< Ok, you picked the default choice."
            return "$default_choice"
        fi

	#if we get here without returning from the function the entered answer was invalid.
	## Tell the user then start the loop again.
	log_err " Try again. Invalid entry: $answer "
    done
}


# Prompts user to input hidden text for something like a password.
## Needs 2 arguments. fisrt argument is the message used to prompt the input, second is variable name to store the password in
ui_query_hidden_input() {
    local msg=$1
    local output_var_name=$2
    local input=""
    log_msg "$msg" "-n" #-n so we don't print a new line
    read -s input

    #prints the passward with all characters replaced with *'s
    echo "$input" | sed --regexp-extended 's/./*/g'

    #Basically uses ui_query_hidden_input's 2nd argument as the name for a new variable where we then store the input text.
    #Since this new variable isn't defined as local it escapes the function's scope and can be used by the calling script.
    #Note: The -g makes the declaration global instead of local to the function.
    declare -g "${output_var_name}"="$input"
}


################
# Section and Task Relate UI Functions
################


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


# Prints beginning section summery header
## Needs 1 argumet, string dennoting section name
ui_section_summery_start() {
    local title=$1
    log_msg "$(cat <<- HEREDOC
	#################
	#
	# Summery for $title
	#

	HEREDOC
    )"
}


# Prints section summery end and waits for user input before continuing.
## Needs no arguments.
ui_section_summery_end() {
    log_msg "################"
    ui_press_any_key
}


# Prints out a start task lable and prompts user whether to perform the task or not
## Needs 1 argument, string with name describing the task
## Returns 0 for perform task and 1 for do not perform task.
ui_task_start() {
    local title=$1
    log_msg "$(cat <<- HEREDOC
	
	-------------------------------------------
	... Begining Task: ${GREEN}${title}${NOCLR} ...
	HEREDOC
    )"

    ui_query_yn "Perform task ${title}?" "n"
    return $?
}


# Prints out text dennoting a task has ended
## Needs no arguments
ui_task_end() {
    log_msg "$(cat <<- HEREDOC
	
	... ${BLUE}Ending Task${NOCLR} ...
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
