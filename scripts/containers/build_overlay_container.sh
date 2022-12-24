#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"



#####################
# Script Documentation

# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Build Overlay Container"
readonly DOC_DESCRIPTION="Targets a sparse virtual loopfile and adds in custom scripts and configuration that allows it to overlay mount onto other containers."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Provide a path to an empty loopfile that will have the relevant files installed onto.
	  loop_filename: path and name of loopfile. Loopfile must have valid container name.
	  > valid name: For these containers the hierarchy is in the loopfile name like this: base_2nd-level_3rd-level
HEREDOC
)
readonly DOC_EXAMPLE="$0 /chroot/dev/base-container.loop"


#These are all defined in the common/vars.sh
# >CHROOT_DEV_PATH
# >CHROOT_DATA_PATH
# >CHROOT_MNT_PATH



###################
# Process Arguments


#check for needed inputs
if [[  -z "$1" ]]; then
    log_err "Missing required argument!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi


loopfile_path=$(echo "$1" | sed 's+[^(\\/)]*$++g')
loopfile_name=$(echo "$1" | sed 's+.*/++')
container_id=$(echo "$loopfile_name" | sed 's+\.loop++')

loopfile_data_path="${CHROOT_DATA_PATH}/${container_id}/"


#Make sure the given loopfile exists and is a loopfile
if [ ! -e "${loopfile_path}/${loopfile_name}" ]; then
    log_err "The given Loopfile path ${loopfile_path}/${loopfile_name} does not exist. Fix this and run again. Exiting."
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1
fi

if [ $(blkid --output value --match-tag TYPE "${loopfile_path}/${loopfile_name}") == "" ]; then
    log_err "The given loopfile at ${loopfile_path}/${loopfile_name} does not have a filesystem. Fix this and run again. Quitting."
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1
fi





#####################
# Perform Script Tasks


ui_section "$DOC_NAME"


####################
# Non-task prep work


#Make sure the loopfile has a presence in the configured dev directory be it symlink or having the file actually there

#> make symlink for loopfile if the loopfile isn't already in the configured dev directory
ui_task_start_no_query "Creating loopfile symlink"
if [ ! -e "${CHROOT_DEV_PATH}/${loopfilename}" ]; then
    pushd "${CHROOT_DEV_PATH}"
    ln --symbolic "${loopfilepath}/${loopfilename}"
    popd

#> don't need a symlink since the loopfile is in the dev directory
elif [ ! -L "${CHROOT_DEV_PATH}/${loopfilename}" ]; then
    log_warn "Not needed: Loopfile is located in ${CHROOT_DEV_PATH}"

#> something is already named that in dev_dir meaning this loopfile is already mounted or one at another location has the same name.
else
    log_err "Error: Symlink at ${CHROOT_DEV_PATH}/${loopfilename} already exists. Remove symlink if broken or rename one of the loopfiles then re-run. Exiting script."
    exit 1
fi

ui_task_end



#Mount the loopfile using the systems loopfile mount script
ui_task_start_no_query "Mount Loopfile"

# detect if the loopfile is already mounted and skip task if so
if [[ $(mount | grep --count "${CHROOT_DEV_PATH}/$loopfile_name") != 0 ]]; then
    ui_task_note "Loop file already mounted! This task is not needed."

#mount the loop file
else

    pushd "${CHROOT_DEV_PATH}"
    ./lib/mount_loop.sh "${loopfile_name}"
    mount_ok=$?
    popd
    
    #mount succeeded, no issues.
    if [ $mount_ok == 0 ]; then
        ui_task_note "New loop file mounted generically."
    
    #was not able to mount for some reason meaning we cannot proceed
    else
        log_err "Loopfile failed to mount. See above errors and address them then re-run."
        exit 1
    fi
fi

ui_task_end



# Task 1 
ui_task_start "Setup Overlay Mount Scripts and Config"
perform_task=$?

setup_overlay_files() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    if [ -e "${loopfile_data_path}/lib/mount.sh" ] ||
       [ -e "${loopfile_data_path}/lib/unmount.sh" ]; then
        log_err "Found container scripts and folders already setup in loopfile. Will not proceed with task."
        return 1
    fi

    # Do task
    ui_task_note "Performing Task."
   
    # Pop into the mounted loopfile and create the directory structure
    pushd "${loopfile_data_path}"
    mkdir --parents "lib" "config/container" "ol_upper" "ol_work"
    popd

    # copy container scripts into the loopfile
    cp --recursive --preserve=all "container_lib/." "${loopfile_data_path}/lib"

    # Add the container id to the container config for use in scripts
    $(echo "$container_id" > "${loopfile_data_path}/config/container/container_id")


    # Check for errors
    ui_task_note "Checking for errors."

    if [ ! -d "${loopfile_data_path}/lib"      ] ||
       [ ! -d "${loopfile_data_path}/config"   ] ||
       [ ! -d "${loopfile_data_path}/ol_upper" ] ||
       [ ! -d "${loopfile_data_path}/ol_work"  ]; then
        log_err "Container folders not created. See above output for any errors."
        return 1
    fi

    if [ ! -e "${loopfile_data_path}/lib/mount.sh" ]; then
        log_err "Container scripts not added to loopfile. See above output for any errors."
        return 1
    fi

}
if [ "$perform_task" -eq 0 ]; then 
    setup_overlay_files; 
    setup_overlay_files_ok=$?
else
    log_warn "You chose not to run this task."
    setup_overlay_files_ok=1
fi
ui_task_end



###################
# Cleanup & Summery

ui_section_summery_start "$DOC_NAME" 

ui_task_note "Mounted loopfile at ${loopfile_data_path}."

if [ "$setup_overlay_files_ok" -eq 0 ]; then
    ui_task_note "Created container folder structure and moved scripts into loopfile."
else
    log_warn "Could not setup loopfile as an overlay container. See previous messages for reason."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	You can now install whatever you need into the container. If it's a base container, install a rootfs into it. If it's an application container, overlay it onto a base container and go from there.
	 
	HEREDOC
)"

ui_section_summery_end

