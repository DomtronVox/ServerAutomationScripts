#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
## IMPORTANT TODO: make sure path is relative from the script and goes to the common directory
source "$(dirname "${BASH_SOURCE[0]}")/common/source_all_common.sh"


# Define the scripts help documentation variables that can be printed if the script is misused
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
if [[ ! -z $1 || -z $2 ]]; then
    log_err "Missing required arguments!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi


# Task 1

# Check if safe

# Do task

# Check for errors





# Summery
