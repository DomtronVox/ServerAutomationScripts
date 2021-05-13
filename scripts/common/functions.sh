#Include file defining some generic utility functions




###########
# Functions that check on user privlages
###########

#Are we running as the root user
check_root () {
  if [[ $EUID -ne 0 ]]; then
    log_err "This script must be run as root" 
    return 1
  fi
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
