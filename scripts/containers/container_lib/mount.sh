#!/usr/bin/env bash

################
# Important: Any changes made in this file needs to be mirrored in the unmount script.
################


source "$(dirname "${BASH_SOURCE[0]}")/common.sh"


# Check if this is a root container to mount directly, or if we need to mount on another container
if [[ $CONTAINER_ORIGIN_ID == "0" ]]; then

    # Simple bind mount
    mount_bind "$UPPER_DIR" "$MOUNT_DIR"
   
    # Mount special directories from the Host OS that the base containers will need.
    mount_bind /dev  "${MOUNT_DIR}/dev"
    mount_bind /proc "${MOUNT_DIR}/proc"
    mount_bind /sys  "${MOUNT_DIR}/sys"


elif [[ -d "$PARENT_DIR" ]]; then

    # More complicated mount that overlays one directory over another.
    # In our case this container will share files with a parent container to reduce
    #   diskspace usage while retaining containerization of processes at almost no overhead.
    mount_overlay "$UPPER_DIR" "$LOWER_DIR_MOUNT_EXPR" "$WORK_DIR" "$MOUNT_DIR"

    log_msg "Overlay mounted ${CONTAINER_ID} onto parent container ${PARENT_DIR} ."

fi


# Quick link for this container term
if [ -e "/chroot/q/${CONTAINER_TERM%%-*}" ]; then
    ln -s "$MOUNT_DIR" "$QUICKLINK"
fi

