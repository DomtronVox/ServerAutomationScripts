#This include file provides a wrapper to package managers so scripts can call 
#  one function to install packages on any system. Obviously not every package
#  manager is supported, but adding another one should be easy enough.

#Main functions are
# install_package - installs provided package via an installed, supported package manager
# download_pgp_key - fetches a key from a given pgp key url source and installs is with supported PM
# TODO no clue how to implement this- add_repo - adds the given repo to an insatlled, supported package manager


#Supported package managers
# - apt

#Top level function that handles ID'ing which
install_package() {
    local packages="$@"

    ui_task_note "Installing the following package(s): ${packages}."

    ##############
    # Identify what supported package manager is avalible
    local program=$(which_package_manager)

    # no supported package manager was identified
    if ! is_function "install_package_${program}"; then
        log_err "No supported package manager was found on this system!"
	return 404
    fi

    ##########
    # With a package manager program id'ed we can pass in each package to be installed

    ui_task_note "\"${program}\" identified as package manager."

    for package_name in ${packages}; do
        install_package_${program} "$package_name" 
    done
}


#Add a repository key via whatever avalible package manager there is
download_pgp_key() {
    local pgp_url="$1"

    ui_task_note "Adding pgp key from: ${pgp_url}."

    ##############
    # Identify what supported package manager is avalible
    local program=$(which_package_manager)

    # no supported package manager was identified
    if ! is_function "download_pgp_key_${program}"; then
        log_err "No supported package manager was found on this system!"
        return 404
    fi

    download_pgp_key_${program} "$pgp_url"
}




#Figure out which upported ackage manager is avalible.
which_package_manager() {
    local program=

    #apt
    if command -v apt &> /dev/null; then program="apt"; fi

    #return value via echo so it can be captured in a variable
    echo "$program"
}


#Wrapper for apt package installations
install_package_apt() {
    local package=$1
    
    ui_task_note "Installing ${package}."

    apt install --yes "$package"

    ui_task_note "Finished installing."

    return $?
}

#wrapper for apt pgp key additions
download_pgp_key_apt() {
    local pgp_url="$1"

    ui_task_note "Adding pgp key to apt."

    wget -qO - "$pgp_url" | sudo apt-key add -

    ui_task_note "Finished adding pgp key. See messages for errors."
}
