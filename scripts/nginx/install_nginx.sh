#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
## IMPORTANT TODO: make sure path is relative from the script and goes to the common directory
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"


# Define the scripts help documentation variables that can be printed if the script is misused
##Note these are never really used since there is no improper input.
readonly DOC_NAME="Install NGINX"
readonly DOC_DESCRIPTION="Installs nginx."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Run it directly no arguments needed.
HEREDOC
)
readonly DOC_EXAMPLE="$0 "


# Define config variables here
# None needed


ui_section "Script '$DOC_NAME' starting."

# Task: install nginx 
ui_task_start "Install NGINX"
perform_task=$?

install_nginx() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    if which nginx > /dev/null 2>&1; then
        log_warn "nginx already installed."
        return 1	
    fi

    # Do task
    ui_task_note "Performing Task."

    sudo apt install -y nginx

    # Check for errors
    ui_task_note "Checking for errors."
    if ! which nginx > /dev/null 2>&1; then
        log_err "nginx failed to install. See the apt output above for errors."
        return 1
    else
        log_msg "No errors detected."
    fi


    return 0
}
if [ "$perform_task" -eq 0 ]; then 
    install_nginx
    installed_nginx=$?
else
    log_warn "You chose not to run this task."
    installed_nginx=1
fi

ui_task_end


#Task: setup lets encrypt for nginx
ui_task_start "Setup Let's Encrypt for NGINX"
perform_task=$?

setup_letsencrypt() {
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    if which certbot > /dev/null 2>&1 && [[ -e /etc/letsencrypt/options-ssl-nginx.conf ]]; then
        log_warn "Both certbot and the nginx plugin are installed so it is not needed."
	return 1
    fi

    # Do task
    ui_task_note "Performing Task."
    
    log_msg "Install certbot and the NGINX certbot plugin..."
    sudo apt install --assume-yes certbot python3-certbot-nginx

    log_msg "Tell certbot to create the nginx specific config files we will use in nginx config files..."
    # c is for cancel since we don't want to enter any domains for this
    echo "c" | sudo certbot --nginx --register-unsafely-without-email --agree-tos
    
    # Check for errors
    ui_task_note "Checking for errors."

    if ! which certbot > /dev/null 2>&1 || [[ ! -e /etc/letsencrypt/options-ssl-nginx.conf ]]; then
        log_err "Still missing certbot and/or the nginx plugin!"
        return 1
    fi


}
if [ "$perform_task" -eq 0 ]; then
    setup_letsencrypt
    installed_letsencrypt=$?
else
    log_warn "You chose not to run this task."
    installed_letsencrypt=1
fi

ui_task_end



# Summery
ui_section_summery_start "Script $DOC_NAME" 

if [ "$installed_nginx" == 0 ]; then
    ui_task_note "Installed nginx."
else
    log_warn "Could not install nginx read output for errors or warnings why."
fi

if [ "$installed_letsencrypt" == 0 ]; then
    ui_task_note "Installed letsencrypt and plugin for nginx."
else
    log_warn "Could not install letsencrypt for nginx read output for errors why."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	Assuming no errors are listed above, NGINX is now ready to use. 
	You will need to configure the server for what you need it for. However, a basic default page should be avalible on port 80 right now.
	 
	HEREDOC
)"

ui_section_summery_end

