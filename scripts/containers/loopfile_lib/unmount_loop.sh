#!/usr/bin/env bash

# make sure an argument was passed to us
if [[  -z "$1" ]]; then
    echo "Error: Was not provided a loopfile to umount."
fi


loopfile_path="$1"
loopfile_name="${1##*/}"            # extracts file portion from path info.
loopfile_name="${loopfile_name%.*}" # strips off the extetion

# set up location to mount the loopfile to
containers_root_path="/chroot"
target_path="${containers_root_path}/data/${loopfile_name}"




#unmount the loopfile
umount "$target_path"

# Check if umount worked and print a relevant message either way
if [ $? ]; then
    echo "Success: Unmounted $loopfile_path from $target_path"
else
    echo "Error: Failed to unmount $loopfile_path from $target_path"
    exit 1
fi  



#clean up leftover directory only if directory is empty
rmdir "$target_path"
if [ $? ]; then
    echo "Success: Removed $target_path directory"
else
    echo "Error: Could not remove $target_path directory, there is something inside it."
fi
