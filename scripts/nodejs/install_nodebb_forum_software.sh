#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"


# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Install NodeBB Forum Software"
readonly DOC_DESCRIPTION="Installs and configures NodeBB."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Makesure NodeJS, NPM, and Mongodb are installed and configured before running then provide the reqired info.
	  FQDN: the fully qualified domain you want nodebb to be accessed at.
	  organization: Where under /srv should NodeBB be installed. example could be forum or a client's name.
	  
HEREDOC
)
readonly DOC_EXAMPLE="$0 general forum.example.com"


#check for needed inputs
if [[  -z "$1" || -z "$2" ]]; then
    log_err "Missing required arguments!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi

fqdn="$1"
organisation="$2"


#Error out if this script is run without install basic nodejs stuff and git.
if ! which git > /dev/null 2>&1 || ! which node > /dev/null 2>&1 || ! which npm > /dev/null 2>&1; then
    log_err "This script requires Git, Node, and NPM to be installed before it can be run!"
    exit 1
fi


# Define config variables here

readonly NODEBB_MONGO_USERNAME="nodebb"
readonly NODEBB_MONGO_PASSWORD=$(fn_random_hash)

readonly NODEBB_GIT_URL="https://github.com/NodeBB/NodeBB"
readonly NODEBB_GIT_BRANCH="v1.16.x"

readonly ORG_PATH="/srv/${organisation}/"
readonly INSTALL_PATH="${ORG_PATH}${fqdn}/"


ui_section "$DOC_NAME"


# Task: create Mongo user
ui_task_start "Create NodeBB Mongo User"
perform_task=$?

create_nodebb_dbuser() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."


    # Do task
    ui_task_note "Performing Task."

    # Check for errors
    ui_task_note "Checking for errors."


}
if [ "$perform_task" -eq 0 ]; then
    create_nodebb_dbuser;
    is_nodebb_user_created=$?
else
    log_warn "You chose not to run this task."
    is_nodebb_user_created=1
fi
ui_task_end






# Task: download NodeBB
ui_task_start "Download NodeBB"
perform_task=$?

download_nodebb() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    if [[ -e "${INSTALL_PATH}/.git" ]]; then
        log_warn "Something already exists at ${INSTALL_PATH}"
    fi

    # Do task
    ui_task_note "Performing Task."

    log_msg "Creating install location..."
    mkdir --parents "$ORG_PATH"
    pushd "$ORG_PATH"
        log_msg "Cloning git repo $NODEBB_GIT_URL branch $NODEBB_GIT_BRANCH to ${INSTALL_PATH} ..."

	#Note: We use depth 1 since we only care about existing stable and not any past commits. 
	## Benifit is this makes the download go faster and consume less bandwidth.
        git clone --depth 1 -b "$NODEBB_GIT_BRANCH" "$NODEBB_GIT_URL" "$fqdn"
    popd


    # Check for errors
    ui_task_note "Checking for errors."

    if [[ ! -e "${INSTALL_PATH}/.git" ]]; then
        log_err "git repo missing from ${INSTALL_PATH} !"
    fi


}
if [ "$perform_task" -eq 0 ]; then 
    download_nodebb; 
    is_nodebb_downloaded=$?
else
    log_warn "You chose not to run this task."
    is_nodebb_downloaded=1
fi
ui_task_end




#Task: Setup NodeBB
#ui_task_start "Setup NodeBB"
perform_task=$?

setup_nodebb() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    # Do task
    ui_task_note "Performing Task."

    pushd "${INSTALL_PATH}"

        #We will keep doing the etupcommand until user force stops us or it exits sucessfully
        while true; do
            log_msg "Running NodeBB install script"
            sudo ./nodebb install

            if [ "$?" -eq 0 ]; then break; fi #stops loop
            log_warn "Setup failed. Trying again..."

	    npm cache clean --force #clean stuff so we can properly download the needed stuff without issue
        done

	log_msg ""
        ./nodebb setup

    popd

    # Check for errors
    ui_task_note "Checking for errors."

}
#if [ "$perform_task" -eq 0 ]; then 
#    setup_nodebb; 
#    is_nodebb_setup=$?
#else
#    log_warn "You chose not to run this task."
#    is_nodebb_setup=1
#fi
#ui_task_end



# Summery
ui_section_summery_start "$DOC_NAME" 

ui_task_note "First thing that was done."
ui_task_note "Second thing that was done"

if [ "$is_nodebb_downloaded" -eq 0 ]; then
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

