#Include file containing some common variables like paths and such that are used throughout the script ecosystem.

readonly APP_FILES_PATH="$(cd ${COMMON_DIR}/../../app_files; pwd)"


#Container related variables
readonly CHROOT_BASE_PATH="/chroot"
readonly CHROOT_DEV_PATH="${CHROOT_BASE_PATH}/dev"
readonly CHROOT_DATA_PATH="${CHROOT_BASE_PATH}/data"
readonly CHROOT_MNT_PATH="${CHROOT_BASE_PATH}/mnt"
readonly CHROOT_ROOTFS_TARS_PATH="${CHROOT_BASE_PATH}/rootfs_tars"

