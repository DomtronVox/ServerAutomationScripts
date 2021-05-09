#Include file defining some generic utility functions



#Are we running as the root user
check_root () {
  if [[ $EUID -ne 0 ]]; then
    log_err "This script must be run as root" 
    return 1
  fi
}
