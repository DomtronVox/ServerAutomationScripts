#!/usr/bin/env bash

# Defines a number of common variables and functions for the mount and unmount scripts. Running directly will have no effect.



# absolute path to this script's directory 
readonly CURRENT_PATH="$(dirname "${BASH_SOURCE[0]}")"




# CONTAINER_ID: this is the main name of the container (e.g., centos6_ssh)
# - Pulled from the file container_id, assumed to be in ../config/container
readonly CONTAINER_ID="$(cat ${CURRENT_PATH}/../config/container/container_id)"


#See if the container ID indicates a parent container.
# Container id's use underscores to indicated "parentage" or containers they should be overlaied onto.
# I.E. if a container is called centos6_apache-24_the-client then it should be overlaied onto a container named centos6_apache-24

#If trimming the ID changes nothing then this container will be mounted normally
if [[ "$CONTAINER_ID" == "${CONTAINER_ID%_*}" ]]; then
    readonly CONTAINER_PARENT_ID="0"

#If trimming does work, then we indicate what parent container will be overlaied onto
else
    readonly CONTAINER_PARENT_ID="${CONTAINER_ID%_*}"
fi


# Name is the last (terminating) segment of the name, identifying the specific container
readonly CONTAINER_NAME="${CONTAINER_ID##*_}"


# Path variables

readonly CHROOT_BASE_PATH="/chroot"

readonly LOOPFILE_PATH="${CHROOT_BASE_PATH}/dev/${CONTAINER_ID}.loop"
readonly DATA_DIR="${CHROOT_BASE_PATH}/data/${CONTAINER_ID}"      #container data mount location
readonly CONFIG_DIR="${DATA_DIR}/config"                          #container configuration files path

readonly UPPER_DIR="${DATA_DIR}/ol_upper"
readonly WORK_DIR="${DATA_DIR}/ol_work"

readonly MOUNT_DIR="${CHROOT_BASE_PATH}/mnt/${CONTAINER_ID}"
readonly QUICKLINK="${CHROOT_BASE_PATH}/q/${CONTAINER_TERM%%-*}"

# Path to container specific mount script
readonly ADDITIONAL_MOUNT_SCRIPT="${CONFIG_DIR}/container/mount.sh"



# Setup variables for anything not an Origin container. i.e. sets up variables for upper layers of an overlay
if [[ $CONTAINER_PARENT_ID != "0" ]]; then

    # Get lowerdir's needed by mount -t overlay
    declare -a LOWER_DIRS
    for origin in "${CONTAINER_ALL_ORIGINS[@]}"; do
      if [[ $origin != $CONTAINER_ID ]]; then
        LOWER_DIRS+=( "${CHROOT_BASE_PATH}/data/${origin}/ol_upper" )
      fi
    done

    # Join lower directory in format compatible with mount -t overlay
    readonly LOWER_DIR_MOUNT_EXPR="$(join_args ':' "${LOWER_DIRS[@]}")"
    readonly PARENT_DIR="${LOWER_DIRS[-1]}"
fi




#join paths so they don't have double /
join_path() {
  echo "${$1%/}/${$2#/}"
}



##############
# Logging Functions
#############

#Some simple functions to make logging/message printing easyer to adjust.

log_err() {
    local NOCLR='\033[0m' #No color
    local RED='\033[31m'  #Red color
    echo "${RED}/!\\Error/!\\: ${1}${NOCLR}"
}

log_msg() {
 echo "$1"
}




################
# Mounting functions
################

# mount_bind: bind an existing source directory (first parameter) to a second target path (second parameter)
mount_bind() {

    local readonly source="$1"
    local readonly target="$2"


    #Make sure the target directory doesn't exist
    if [ -e "$target" ]; then
        log_err "Target path ${target} exists. Cannot mount bind to that path. Exiting."
        exit 1
    fi

    mkdir --parents "$target" \
      && mount --bind "$source" "$target"

    #grab exit status and print a message based on it
    local readonly result="$?"
    if [[ $result == 0 ]]; then
        log_msg "Mounted directory: $source onto ${target}."
    else
        log_err "Could not mount $source onto ${target}. See above output for possible errors."
    fi

    return "$result"

}


# mount_overlay: overlay an upper directory (first parameter) onto a lower directory
#  (second parameter) then mount them at a target location (third parameter).
mount_overlay() {
    
    local readonly upper_dir="$1"
    local readonly lower_dir="$2"
    local readonly work_dir="$3"
    local readonly mount_dir="$4"
    
    
    
    #Make sure the target directory doesn't exist.
    local error=false
    if [ -e "$mount_dir" ]; then
        log_err "Target path ${mount_dir} exists. Cannot overlay mount to that path."
        error=1
    fi

    #Make sure the lower, upper, and work directories exist.
    if [ ! -e "$upper_dir" ]; then
        log_err "Lower directory ${upper_dir} does not exist. Cannot overlay mount with a missing lower directory."
        error=1
    fi

    if [ ! -e "$lower_dir" ]; then
        log_err "Lower directory ${lower_dir} does not exist. Cannot overlay mount with a missing lower directory."
        error=1
    fi

    if [ ! -e "$work_dir" ]; then
        log_err "Work directory ${work_dir} does not exist. Cannot overlay mount with a missing work directory."
        error=1
    fi

    #check and print ALL possible breaking points first, only exit if at least one error has occured.
    if "$error"; then
        log_err "Overlay mount pre-check failed. See above for errors."
        exit 1
    fi


    #Make sure a directory exists at the mount point then overlay mount
    mkdir --parents "$mount_dir" \
      && mount --types overlay \
             --options lowerdir="${lower_dir}",upperdir="${upper_dir}",workdir="${work_dir}" \
             --source overlay \
             --target "${mount_dir}"


    #grab exit status and print a message based on it
    local readonly result="$?"
    if [[ $result == 0 ]]; then
        log_msg "Overlay mount completed. Upper: ${upper_dir} ; Lower: ${lower_dir} ; Work: ${work_dir} ; Mount Point: ${mount_dir} ;"
    else
        log_err "Could not mount $source onto ${target}. See above output for possible errors."
    fi

    return "$result"
}


##################
# Unmounting functions
##################

# Squelch lsof errors
lsof_no_error() {
  lsof 2>/dev/null "$@"
}


# umount_dir: unmount a directory
umount_target() {

    local readonly target="$1"

    #Make sure something is mounted there.
    if [[ `mount | grep -c " $target[ /]"` == 0 ]]; then
        log_msg "Nothing is mounted at $target so there is nothing to do. Exiting."
        exit 0
    fi

    #Make sure it is safe to unmount (no processes are running)
    if [[ `lsof_no_error +D "$target"` != 0 ]]; then
        lsof +D "$target"
        log_err "Could not unmount \"${target}\". Files still open by running processes, please close them then try to unmount again. See above for list of offending processes."
        exit 1
    fi

    umount "$target"

    # Clean up directory the mount bind was on if it's empty.
    rmdir "$target"

    #Make sure it is safe to remove target directory
    if [ $? ]; then
        log_msg "Removed ${target_path} directory safely."
    else
        log_msg "Warning: Could not remove ${target_path} directory, there is something inside it. Mount HAS been umounted so this is a minor issue."
    fi

}

