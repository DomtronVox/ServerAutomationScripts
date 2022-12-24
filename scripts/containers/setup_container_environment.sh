#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"



#####################
# Script Documentation

# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Setup Container Environment"
readonly DOC_DESCRIPTION="Setup a host system for chroot overlay containers. This involves creating some folders, and installing some programs."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Run directly, no arguments needed.
HEREDOC
)
readonly DOC_EXAMPLE="$0"



loopfile_lib_path="$(dirname "${BASH_SOURCE[0]}")/loopfile_lib"

#These are all defined in the common/vars.sh
#CHROOT_BASE_PATH
#CHROOT_DEV_PATH
#CHROOT_DATA_PATH
#CHROOT_MNT_PATH
#CHROOT_ROOTFS_TARS_PATH


###################
# Process Arguments

# None



#####################
# Perform Script Tasks


ui_section "$DOC_NAME"

# Task 1: create container directory structure 
ui_task_start "Create Container Directory Structure at $CHROOT_BASE_PATH"
perform_task=$?

create_container_directories() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."
    
    if [ -d "$CHROOT_DEV_PATH"  ] &
       [ -d "$CHROOT_DATA_PATH" ] &
       [ -d "$CHROOT_MNT_PATH"  ] &
       [ -d "$CHROOT_ROOTFS_TARS_PATH" ] &
       [ -d "${CHROOT_DEV_PATH}/lib" ]; then
        log_warn "Container ecosystem folders already exist. Stopping task."
        return 1
    fi

    #make sure our loopfile library scripts folder is accessible
    if [ ! -d "$loopfile_lib_path" ]; then
        log_err "Expected loopfile mountscripts at $loopfile_lib_path but they are missing! Stopping task."
        return 1
    fi





    # Do task
    ui_task_note "Performing Task."

    ui_task_note "Creating container ecosystem directory structure."
    mkdir --parents "$CHROOT_DEV_PATH" "$CHROOT_DATA_PATH" "$CHROOT_MNT_PATH" "$CHROOT_ROOTFS_TARS_PATH"

    
    if [ ! -d "${CHROOT_DEV_PATH}/lib" ]; then

        ui_task_note "Copying Loopfile mount scripts to ${CHROOT_DEV_PATH}/lib"
        
        mkdir --parents "${CHROOT_DEV_PATH}/lib"
        cp --recursive --preserve=all "${loopfile_lib_path}/." "${CHROOT_DEV_PATH}/lib/"
    
    else
        log_warn "Something is already at ${CHROOT_DEV_PATH}/lib so not copying loopfile mount scripts. You may need to manually do this if this is an error."
    fi




    # Check for errors
    ui_task_note "Checking for errors."
    
    if [ ! -d "$CHROOT_DEV_PATH"   ] ||
       [ ! -d "$CHROOT_DATA_PATH" ] ||
       [ ! -d "$CHROOT_MNT_PATH"  ] ||
       [ ! -d "$CHROOT_ROOTFS_TARS_PATH" ] ||
       [ ! -d "${CHROOT_DEV_PATH}/lib" ]; then
        log_err "Container ecosystem folders not created. See above output for any errors."
        return 1
    fi


}
if [ "$perform_task" -eq 0 ]; then 
    create_container_directories; 
    create_container_directories_ok=$?
else
    log_warn "You chose not to run this task."
    create_container_directories_ok=1
fi
ui_task_end







###################
# Cleanup & Summery

ui_section_summery_start "$DOC_NAME" 

if [ "$create_container_directories_ok" -eq 0 ]; then
    ui_task_note "Created container directory structure at $CHROOT_BASE_PATH and installed loopfile mount scripts."
else
    log_warn "We were unable to create the container directory structure. See above messages for any errors."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	You can now create containers using the container setup scripts.
	 
	HEREDOC
)"

ui_section_summery_end

