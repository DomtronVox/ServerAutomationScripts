#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
## IMPORTANT TODO: make sure path is relative from the script and goes to the common directory
source "$(dirname "${BASH_SOURCE[0]}")/common/source_all_common.sh"


# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Template Script"
readonly DOC_DESCRIPTION="What this script does."
readonly DOC_USAGE=$(cat <<- HEREDOC
	How to use this script
	  arg1: description
	  arg2: description
HEREDOC
)
readonly DOC_EXAMPLE="$0 example_arg"


# Define config variables here




#check for needed inputs
if [[  -z "$1" || -z "$2" ]]; then
    log_err "Missing required arguments!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi


ui_section "$DOC_NAME"

# Task 1 
ui_task_start "Task 1"
perform_task=$?

task_1() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    # Do task
    ui_task_note "Performing Task."

    # Check for errors
    ui_task_note "Checking for errors."

}
if [ "$perform_task" -eq 0 ]; then 
    task_1; 
    sucessfuly_compleated_task_1=$?
else
    log_warn "You chose not to run this task."
    sucessfuly_compleated_task_1=1
fi
ui_task_end

#Task 2
#...


# Summery
ui_section_summery_start "$DOC_NAME" 

ui_task_note "First thing that was done."
ui_task_note "Second thing that was done"

if [ "$sucessfuly_compleated_task_1" -eq 0 ]; then
    ui_task_note "Optional thing that was done."
else
    log_warn "Did not successfully complete task 1. See above messages for reason."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	Explanation of what should be done next.
	 
	HEREDOC
)"

ui_section_summery_end

