#!/usr/bin/env bash

# Creates a loopfile and makes it a moutable filesystem. 
# Used primarily as a base to create containers on, but can have other uses.


# Imports all common files so we have helper functions that keep all scripts consistant.
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"


#The default filesystem type we will use.
readonly DEFAULT_FS_TYPE="ext4"


#####################
# Script Documentation

# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Build Loop Filesystem"
readonly DOC_DESCRIPTION="Creates a loopfile that is a mountable filesystem. The loopfile will be sparse only taking up space as it's filled with a max size based on the given size."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Provide a Filepath+Filename and filesize with an optional Filesystem type.
	  Filename: Path and name of the file
	  Filesize: Number followed by first letter of one of the following words: Megabyte, Gigabyte, Tarra byte
	  [Filesysem_type]: By Deafult uses ${DEFAULT_FS_TYPE} but can be anything supported by the mkefs2 tool.
HEREDOC
)
readonly DOC_EXAMPLE="$0 chroot/Loops/prt_srv.loop 200G"





###################
# Process Arguments


#check for needed inputs
if [[  -z "$1" || -z "$2" ]]; then
    log_err "Missing required arguments!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi


#Process the first argument so we seperate out the filename from the path
loopfile_path=$(echo "$1" | sed 's+[^(\\/)]*$++g')
loopfile_name=$(echo "$1" | sed 's+.*/++')

#Process second argument so we have a number and size denomination
loopfile_denom=$(echo "$2" | sed 's+[0-9]*++g')
loopfile_size=$(echo "$2" | sed 's+[^0-9]*++g')

given_size="$2"

#based on the size denomination, adjust the size to be in kilobytes
if   [ "${loopfile_denom,,}" = "m" ]; then
    let "loopfile_size *= 1024"
elif [ "${loopfile_denom,,}" = "g" ]; then
    let "loopfile_size *= 1024 * 1024"
elif [ "${loopfile_denom,,}" = "t" ]; then
    let "loopfile_size *= 1024 * 1024 * 1024"

#if the given denominator didn't fit anything throw an error
else
    log_err "Invalid file size denominator use one of (M,G,T).\n"
    help_text
    exit 1 #General error
fi

#Check if the optional argument was given and use our default value if not
if [[ -z $3 ]]; then
    fs_type=$DEFAULT_FS_TYPE
else
    fs_type=$3
fi



#####################
# Perform Script Tasks


ui_section "$DOC_NAME"

# Task 1: create_loopfile
ui_task_start "Create Sparse File at ${loopfile_path}${loopfile_name}"
perform_task=$?

create_loopfile() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."
    if [ -e "${loopfile_path}/${loopfile_name}" ]; then
        log_err "A file already exists at ${loopfile_path}/${loopfile_name}. Move/remove the file or choose a different path/name."
	return 1
    fi


    #make sure there is enough disk space (40Mb) for at least the file and a filesystem
    if [ $(df --block-size=1m --output=avail ${loopfile_path} | tail -n 1) -lt 40 ]; then
        log_err "Not enough diskspace for a loopfile and filesystem. Less then 40 Mb."
        return 1
    #Check that there is room on the volume for the full requested sized
    elif [ $(df --block-size=1k --output=avail ${loopfile_path} | tail -n 1) -le ${loopfile_size} ]; then
        log_warn "There is not enough diskspace on the host system to allow the sparse file to reach full capacity."
    fi




    # Do task
    ui_task_note "Performing Task."
    
    ui_task_note "Makeing sure path exists."
    mkdir --parents "$loopfile_path"

    #Makes sparse file of the the given size. 
    #Essentially creates a file claiming it's a certain size, without actually taking up that amount of diskspace.
    ui_task_note "Creating sparse loopfile of ${given_size} at ${loopfile_path}/${loopfile_name}"
    truncate --size="${loopfile_size}k" "${loopfile_path}/${loopfile_name}"




    # Check for errors
    ui_task_note "Checking for errors."
    #TODO Check that filesize is correct so we know no "out of space" issues happened
    if [ ! -e "${loopfile_path}/${loopfile_name}" ]; then
        log_err "Loopfile directory was not created! Check for errors."
        return 1
    fi

}
if [ "$perform_task" -eq 0 ]; then 
    create_loopfile; 
    create_loopfile_ok=$?
else
    log_warn "You chose not to run this task."
    create_loopfile_ok=1
fi
ui_task_end

#Task 2: make_loopfile_filesystem
ui_task_start "Make Loopfile Filesystem"
perform_task=$?

make_loopfile_filesystem() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    #make sure file exists
    if [ ! -e "${loopfile_path}/${loopfile_name}" ]; then
        log_err "File is missing at ${loopfile_path}/${loopfile_name}. Cannot create filesystem in a non-existant file."
        return 1
    fi


    #capture the filesystem type on the target loopfile
    target_fs_type=$(blkid --output value --match-tag TYPE "${loopfile_path}/${loopfile_name}")
    # If the requested FS type and the target's FS type are the same we don't need to do anything
    if [ "$target_fs_type" == "$fs_type" ]; then
        log_warn "Filesystem already created on ${loopfile_path}/${loopfile_name} so this task isn't needed"
        return 1       
    
    #if there is anything except blank or the requested fs type, that is a serious possible error
    elif [ "$target_fs_type" != "" ]; then
        log_err "Filesystem exists at ${loopfile_path}/${loopfile_name}. You may be targeting an existing Filesystem which could lead to loss of data. Stopping task."
        return 1
    fi
    



    # Do task
    ui_task_note "Performing Task."

    ui_task_note "Running mke2fs output is as follows: "

    #N: number of INodes
    mke2fs "-t$fs_type" "-N 400000" "$loopfile_path/$loopfile_name" "${loopfile_size}k"

    #check if task exit code is good or not
    if [ ! $? ]; then
        log_err "Making new filesystem failed. See above output for errors."
        return 1
    fi





    # Check for errors
    ui_task_note "Checking for errors."

    #capture the filesystem type on the target loopfile to see if it was created
    target_fs_type=$(blkid --output value --match-tag TYPE "${loopfile_path}/${loopfile_name}")

    # If the requested FS type and the target's FS type are the same we don't need to do anything
    if [ "$target_fs_type" != "$fs_type" ]; then
        log_err "Failed to make filesystem of type '${fs_type}' on ${loopfile_path}/${loopfile_name}. Detected as a $target_fs_type filesystem instead."
        return 1
    fi

}
if [ "$perform_task" -eq 0 ]; then
    make_loopfile_filesystem;
    make_loopfile_filesystem_ok=$?
else
    log_warn "You chose not to run this task."
    make_loopfile_filesystem_ok=1
fi
ui_task_end







###################
# Cleanup & Summery

ui_section_summery_start "$DOC_NAME" 

if [ "$create_loopfile_ok" -eq 0 ]; then
    log_msg "Created sparse file of $2 size at ${loopfile_path}/${loopfile_name} ."
else
    log_warn "Did NOT create loopfile at ${loopfile_path}/${loopfile_name}. See the task 'Create Sparse File at ${loopfile_path}${loopfile_name}' output above for more info."
fi

if [ "$make_loopfile_filesystem_ok" -eq 0 ]; then
    log_msg "Created filesystem in loopfile ${loopfile_path}/${loopfile_name} of the type $fs_type."
else
    log_warn "Did NOT create filesystem in loopfile ${loopfile_path}/${loopfile_name}. See the task 'Make Loopfile Filesystem' output above for more info."
fi


log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	Loopfile is ready to be mounted via the mount command.
	Example: mount --options 'loop,defaults,nodev,nosuid' $loopfile_path/$loopfile_name /chroot/mnt/$loopfile_name 
	HEREDOC
)"

ui_section_summery_end

