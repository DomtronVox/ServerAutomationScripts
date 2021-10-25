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

container_root_path="/chroot"
container_dev_path="${container_root_path}/dev"
container_data_path="${container_root_path}/data"
container_mnt_path="${container_root_path}/mnt"
container_rootfs_path="${container_root_path}/rootfs_tars"


###################
# Process Arguments

# None



#####################
# Perform Script Tasks


ui_section "$DOC_NAME"

# Task 1: create container directory structure 
ui_task_start "Create Container Directory Structure at $container_root_path"
perform_task=$?

create_container_directories() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."
    
    if [ -d "$container_dev_path"  ] &
       [ -d "$container_data_path" ] &
       [ -d "$container_mnt_path"  ] &
       [ -d "$container_rootfs_path" ] &
       [ -d "${container_dev_path}/lib" ]; then
        log_warn "Container ecosystem folders already exist. Stopping task."
        return 1
    fi

    #make sure out loopfile lib files are accessible
    if [ ! -d "$loopfile_lib_path" ]; then
        log_err "Expected loopfile mountscripts at $loopfile_lib_path but they are missing! Stopping task."
        return 1
    fi





    # Do task
    ui_task_note "Performing Task."

    ui_task_note "Creating container ecosystem directory structure."
    mkdir --parents "$container_dev_path" "$container_data_path" "$container_mnt_path" "$container_rootfs_path"

    
    if [ ! -d "${container_dev_path}/lib" ]; then

        ui_task_note "Copying Loopfile mount scripts to ${container_dev_path}/lib"
        
        mkdir --parents "${container_dev_path}/lib"
        cp --recursive --preserve=all "${loopfile_lib_path}/." "${container_dev_path}/lib/"
    
    else
        log_warn "Something is already at ${container_dev_path}/lib so not copying loopfile mount scripts. You may need to manually do this if this is an error."
    fi




    # Check for errors
    ui_task_note "Checking for errors."
    
    if [ ! -d "$container_dev_path"   ] ||
       [ ! -d "$container_data_path" ] ||
       [ ! -d "$container_mnt_path"  ] ||
       [ ! -d "$container_rootfs_path" ] ||
       [ ! -d "${container_dev_path}/lib" ]; then
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
    ui_task_note "Created container directory structure at $container_root_path and installed loopfile mount scripts."
else
    log_warn "We were unable to create the container directory structure. See above messages for any errors."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	You can now create containers using the container setup scripts.
	 
	HEREDOC
)"

ui_section_summery_end

