#!/usr/bin/env bash

# make sure an argument was passed to us
if [[  -z "$1" ]]; then
    echo "Error: Was not provided a loopfile to mount."
fi

loopfile_path="$1"
loopfile_name="${1##*/}"            # extracts file portion from path info.
loopfile_name="${loopfile_name%.*}" # strips off the extetion

# set up location to mount the loopfile to
containers_root_path="/chroot"
target_path="${containers_root_path}/data/${loopfile_name}"



#make sure the target path doesn't exist and then create an empty directory there.
if [ ! -d "$target_path" ]; then
    #make sure the mount path exists so something can be mounted there
    mkdir --parents "$target_path"
else
    echo "Error: $target_path already exists. Remove and try again."
    exit 1
fi



# Mount the loopfile to the data sub-folder
mount \
  --options 'loop,defaults,nodev,nosuid' \
  --source "$loopfile_path" \
  --target "$target_path"

# Check if mount worked and print a relevant message either way
if [ $? ]; then
    echo "Success: Mounted $loopfile_path at $target_path"
else
    echo "Error: Failed to mount $loopfile_path at $target_path"
fi
