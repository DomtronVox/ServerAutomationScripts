#!/usr/bin/env bash

# Import all common files so we have helper functions that keep all scripts consistant.
source "$(dirname "${BASH_SOURCE[0]}")/../common/source_all_common.sh"


###############
#  Script Documentation

# Define the scripts help documentation variables that can be printed if the script is misused
readonly DOC_NAME="Setup NGINX Reverse Proxy Domain"
readonly DOC_DESCRIPTION="Creates the configuration so NGINX redirects traffic for a given FQDN to a localhost port that the application is running on. Also makes usre it is secured with an SSL."
readonly DOC_USAGE=$(cat <<- HEREDOC
	Provide a Fully Qualified Domain Name and localhost Port for an application running on the server.
	  FQDN: Domain including the subdomain that should direct to the application.
	  Port: A localhost port that the target application is running on.
	  Organization: An optional organization that the application lives under. Defaults to general
	
	It is important to note you will need the domain already pointing at this server so we can aquire a SSL certificate.
HEREDOC
)
readonly DOC_EXAMPLE="$0 wiki.example.com 20001 hanson"






####################
#  Process Arguments

#check for needed arguments
if [[  -z "$1" || -z "$2" ]]; then
    log_err "Missing required arguments!"
    help_text "$DOC_DESCRIPTION" "$DOC_USAGE" "$DOC_EXAMPLE"
    exit 1 # general Error
fi

# Define config variables here
readonly FQDN=$1
readonly PORT=$2

## check if optional argument was provided and if not give a default
if [[ -z $3 ]]; then
    readonly ORGANIZATION="general"
else
    readonly ORGANIZATION=$3
fi

## location of the template file we will be using
readonly TEMPLATE_FILEPATH="${APP_FILES_PATH}/nginx/reverse_proxy_template"

## location for the config file to live at
readonly SRV_PATH="/srv/${ORGANIZATION}/nginx/"

## location of nginx config files
readonly NGINX_SITES_ENABLED_PATH="/etc/nginx/sites-enabled/"

## Name of the reverse proxy config file
readonly CONFIG_FILENAME="${FQDN}_RProxy_SSL"






#######################
# Perform Script Tasks


ui_section "$DOC_NAME"

# Task: setup config file 
ui_task_start "Setup reverse proxy config file"
perform_task=$?

setup_proxy_config() {

    ##########################
    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    ## Make sure files don't already exist
    if [[ -e "${SRV_PATH}${CONFIG_FILENAME}" || -e "${NGINX_SITES_ENABLED_PATH}${CONFIG_FILENAME}" ]]; then
        log_warn "Config file already exists at either (or both) ${SRV_PATH}${CONFIG_FILENAME} and ${NGINX_SITES_ENABLED_PATH}${CONFIG_FILENAME}"
        return 1
    fi

    ## make sure template file exists
    if [[ ! -e "${TEMPLATE_FILEPATH}" ]]; then
        log_err "Template file missing from ${TEMPLATE_FILEPATH}"
        return 1
    fi

    ## make sure nginx config directory exists (and that nginx is actually installed
    if [[ ! -d "${NGINX_SITES_ENABLED_PATH}" ]]; then
        log_err "Missing NGINX config directory! Is NGINX not installed? Expected path: ${NGINX_SITES_ENABLED_PATH}"
        return 1
    fi


    ## Make sure the LE nginx configuration info exists (which is needed by the template)
    if [[ ! -e /etc/letsencrypt/options-ssl-nginx.conf ]]; then
        log_err "Missing NGINX's Let's Encrypt config file! Is certbot and the certbot NGINX plugin not installed?"
        return 1
    fi

    ##########
    # Do task
    ui_task_note "Performing Task."


    log_msg "Making sure destination dir exists."
    mkdir --parents "${SRV_PATH}"


    log_msg "Copying template file to '${SRV_PATH}${CONFIG_FILENAME}' ..."
    cp "${TEMPLATE_FILEPATH}" "${SRV_PATH}${CONFIG_FILENAME}"


    log_msg "Replacing template tags with real values..."
    replace_tag "${SRV_PATH}${CONFIG_FILENAME}" "FQDN" "$FQDN" 
    replace_tag "${SRV_PATH}${CONFIG_FILENAME}" "REDIRECT_PORT" "$PORT" 
    replace_tag "${SRV_PATH}${CONFIG_FILENAME}" "ORGANIZATION" "$ORGANIZATION"


    log_msg "Symlinking config file to nginx config directory..."

    #moves us temporarily to the directory so we can do some opterations
    pushd "${NGINX_SITES_ENABLED_PATH}"
        ln -s "${SRV_PATH}${CONFIG_FILENAME}" "${CONFIG_FILENAME}"
    popd


    #################
    # Check for errors
    ui_task_note "Checking for errors."
    
    if [[ ! -e "${SRV_PATH}${CONFIG_FILENAME}" || ! -e "${NGINX_SITES_ENABLED_PATH}${CONFIG_FILENAME}" ]]; then
        log_err "Did not find one or both of ${SRV_PATH}${CONFIG_FILENAME} and ${NGINX_SITES_ENABLED_PATH}${CONFIG_FILENAME}"
        return 1
    fi
    
}
if [ "$perform_task" -eq 0 ]; then 
    setup_proxy_config; 
    is_proxy_config_setup=$?
else
    log_warn "You chose not to run this task."
    is_proxy_config_setup=1
fi
ui_task_end





# Task: setup config file 
ui_task_start "Setup reverse proxy config file"
perform_task=$?

setup_ssl() {

    # Check if safe and needed
    ui_task_note "Checking if task is safe to run and if it is needed."

    # Do task
    ui_task_note "Performing Task."

    # Check for errors
    ui_task_note "Checking for errors."

}
if [ "$perform_task" -eq 0 ]; then
    setup_ssl;
    is_ssl_setup=$?
else
    log_warn "You chose not to run this task."
    is_ssl_setup=1
fi
ui_task_end




#assuming the file got created correctly, we now need to reload nginx for it to take effect.
if [ "$is_proxy_config_setup" -eq 0 ]; then
    sudo service nginx reload
fi





###################
# Cleanup & Summery


ui_section_summery_start "$DOC_NAME" 

if [ "$is_proxy_config_setup" -eq 0 ]; then
    ui_task_note "Proxy redirect config file for $FQDN has been setup at ${SRV_PATH}${CONFIG_FILENAME} with a symlink to ${NGINX_SITES_ENABLED_PATH}${CONFIG_FILENAME} created."
    ui_task_note "NGINX config was reloaded so config file can take effect."
else
    log_warn "The proxy config file had errors while being created. Please see previous messages for why this happened and try to fix it."
fi

log_msg "$(cat <<- HEREDOC
	 
	>Further Instructions<
	Assuming the config file was created, you now need to make sure the application is running using localhost and the port you provided this script. aka 127.0.0.1:$PORT
	 
	HEREDOC
)"

ui_section_summery_end

