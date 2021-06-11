#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"


# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Install Basic Nodejs Ecosystem"
readonly DOC_DESCRIPTION="Installs NPM, node, and mongodb."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Needs an admin name and password for the mongodb admin.
	  name: Name of the mongodb admin user.
	  password: Optional, password for the mongodb admin. If left off you will need to enter it during the script runtime.
HEREDOC
)
readonly DOC_EXAMPLE="$0 admin secretcat"


# Define config variables here

##MongoDB related values
##values based on https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/ refer to it when updating for other versions or OS'
readonly MONGODB_USER="mongodb"
readonly MONGODB_APT_SOURCES_PATH="/etc/apt/sources.list.d/mongodb-org-4.4.list"
readonly MONGODB_PGP_KEY="https://www.mongodb.org/static/pgp/server-4.4.asc"
readonly MONGODB_APT_Entry="deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse"
readonly MONGODB_CONFIGFILE_PATH="/etc/mongod.conf"


#check for needed inputs
if [[  -z "$1" ]]; then
    log_err "Missing required arguments!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi

mongodb_admin_name="$1"


ui_section "$DOC_NAME"

if [[ -z "$2" ]]; then
    log_msg "Need to get missing password argument before continuing."
    ui_query_hidden_input "Enter Password: " "mongodb_admin_password"
else
    mongodb_admin_password=$2
fi


# Task: Setup nodejs and npm
ui_task_start "Setup NodeJS and NPM"
perform_task=$?

setup_nodejs() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    if which nodejs > /dev/null 2>&1 && which npm > /dev/null 2>&1; then
        log_warn "Nodejs and npm are already installed."
	return 1
    fi

    # Do task
    ui_task_note "Performing Task."

    log_msg "Installing nodejs and npm..."
    sudo apt install --yes nodejs npm

    log_msg "Backtracking NPM to version 6 because some apps require an older NPM (NodeBB)."
    npm install --global npm@6

    # Check for errors
    ui_task_note "Checking for errors."
    
    if ! which nodejs > /dev/null 2>&1 || ! which npm > /dev/null 2>&1; then
        log_err "Nodejs and npm was not installed!"
        return 1
    fi

}
if [ "$perform_task" -eq 0 ]; then 
    setup_nodejs; 
    is_nodejs_setup=$?
else
    log_warn "You chose not to run this task."
    is_nodejs_setup=1
fi
ui_task_end



#Task: install and configure mongodb
ui_task_start "Install and Configure MongoDB"
perform_task=$?

install_mongodb() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    if which mongod > /dev/null 2>&1; then
        log_warn "Nodejs and npm are installed"
        return 1
    fi

    # Do task
    ui_task_note "Performing Task."


    ##only add the apt repo if it doesn't already exist
    if [[ ! -e "$MONGODB_APT_SOURCES_PATH" ]]; then
        log_msg "Adding MongoDB PGP Key..."
        wget -qO - "$MONGODB_PGP_KEY" | sudo apt-key add -

        log_msg "Adding MongoDB Package repo..."
        echo "$MONGODB_APT_Entry" | sudo tee "$MONGODB_APT_SOURCES_PATH"
	sudo apt update
    fi




    log_msg "Installing Mongodb..."
    sudo apt install --yes mongodb-org




    log_msg "Adjusting ulimit for MongoDB..."

    #Note that the short opt letters might be different on other linux distros so you need to check ulimit -a
    #These are recomended values based on https://docs.mongodb.com/manual/reference/ulimit/
    ulimit \
        -f unlimited  `#file size` \
        -t unlimited  `#cpu time` \
        -v unlimited  `#virtual memory` \
        -l unlimited  `#locked-in-memory size` \
        -n 64000      `#open files` \
        -m unlimited  `#memory size` \
 	-u 64000      `#processes/threads` \
        "$MONGODB_USER" #user to apply these settings to




    log_msg "Starting MongoDB..."
    sudo systemctl daemon-reload #make sure the newly installed mongodb stuff is loaded into systemd
    sudo systemctl start mongod


    
    log_msg "Creating admin user using arguments..."
    ##See this site about heredocs and mongo: https://pauldone.blogspot.com/2019/05/mongo-shell-script-inside-bash.html
    mongo <<-HEREDOC
	db=db.getSiblingDB('admin');
	db.createUser( { user: "$mongodb_admin_name", pwd: "$mongodb_admin_password", roles: [ { role: "root", db: "admin" } ] } )
	HEREDOC


    log_msg "Adding to MongoDB configuration..."
    cat <<-HEREDOC >> "$MONGODB_CONFIGFILE_PATH"
	 
	security:
	  authorization: enabled
	HEREDOC


    log_msg "Making logs easily accessable..."
    mkdir --parents "/srv/log/"
    pushd "/srv/log/"
        ln -s "/var/log/mongodb/mongod.log" "mongod.log"
    popd




    # Check for errors
    ui_task_note "Checking for errors."

    if ! which mongod > /dev/null 2>&1; then
        log_warn "Nodejs and npm are installed"
        return 1
    fi

    ##TODO: Should check that admin user and password works to log in. 
    ##TODO: Might be worth it to pull out setting up the admin as another task just so it is easier to run again if it fails for some reason.

}
if [ "$perform_task" -eq 0 ]; then
    install_mongodb;
    is_mongodb_installed=$?
else
    log_warn "You chose not to run this task."
    is_mongodb_installed=1
fi
ui_task_end



# Summery
ui_section_summery_start "$DOC_NAME" 

if [ "$is_nodejs_setup" -eq 0 ]; then
    ui_task_note "Basic NodeJS ecosystem was setup (interpreter, NPM, etc)."
else
    log_warn "Did not set up NodeJS ecosystem. See above messages for reason."
fi

if [ "$is_mongodb_installed" -eq 0 ]; then
    ui_task_note "MongoDB was installed and configured."
else
    log_warn "Did not install MongoDB. See above messages for reason."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	Assuming the above indicates success, MongoDB is now installed and configured. You can direct applications to connect to it via localhost:27017
	 
	HEREDOC
)"

ui_section_summery_end

