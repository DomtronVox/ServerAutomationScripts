#Include file defining some generic utility functions


###########
# Functions that check variable types
###########

#Tests if a given string exists as a function
is_function() { declare -Ff "$1" >/dev/null; }





###########
# Functions that check on user privlages
###########

#Are we running as the root user
fn_check_root () {
  if [[ $EUID -ne 0 ]]; then
    log_err "This script must be run as root" 
    return 1
  fi
}



###########
# Functions for file path manipulation
###########

#Fix path string to remove extra / and resolve .. characters so //tmp/../tmp becomes /tmp
fix_filesystem_path() {
  echo $(readlink -m "$1")
}

#join paths so they don't have double /
join_path() {
  echo "${$1%/}/${$2#/}"
}



###########
# Functions for Template Manipulation
###########

#Define the open and close delimiters for tags
OPEN_TEMPLATE_TAG="<<"
CLOSE_TEMPLATE_TAG=">>"


# Replaces all intances of a given tag name in a given file with the given data
## Needs 3 argumenst. 1st is the filepath of the file to replace in,
##                    2nd is the name of the tag to replace
##                    3rd is the data to replace it with
replace_tag() {
    local filepath="$1"
    local tag="${OPEN_TEMPLATE_TAG}${2}${CLOSE_TEMPLATE_TAG}"
    local replace_text="$3"

    #Uses a global substitution regex to replace all instances of tag with replace_text
    sed --in-place "s+${tag}+${replace_text}+g" "$filepath"
}


###########
# Redefine pushd/popd to be quiet
##########

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}



#########
# Functions for string generation
########

# Creates a string of characters x long containing any of the given characters (using regex notation)
fn_random_hash() {
    local length="$1"
    local valid_characters="$2"

    #Length is to be a number only otherwise the function fails.
    if ! [[ $length =~ "^[0-9]+$" ]] ; then
	exit 1
    fi

    #if valid characters is blank default to alphanumeric
    if [[ -z "$valid_characters" ]] ; then
        valid_characters="[:alnum:]"
    fi

    #Now generate the password
    echo tr --complement --delete "$valid_characters" < /dev/urandom | fold --width="${length}" | head --lines=1
}

