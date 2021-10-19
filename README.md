This repo contains scripts and other files needed to setup and maintain services for a web server.

Note that these setup scripts are tested against Ubuntu, specifically ubuntu 20.04 LTS, 64-bit, but I will make some effort for them to be portable. Note that a big sticking point for portability will be that all install scripts will be using apt. 

# Repo Structure

* docs/: Contains any additional documentation needed about this server setup process not already in the scripts themselves.
* scripts/: Contains all the scripts that make up the setup process.
  * scripts/common/: A collection of include scripts that all other scripts include to make everything more unified and make developing a bit easier (i.e. ui functions).
  * scripts/setup/: Scripts to help setup a fresh system.
  * scripts/maintenance: Scripts that are either cron'ed or manually run after server setup to make sure everything is maintained. 
* app\_files: Contains folders for each application we have a setup script. These folders hold files needed by scripts to setup each application. So configuration templates and the like. Also contains files that will overwright default application files for my own purposes, like making stying unified across several applications.


# Design

## Guidelines

Scripts should follow, in not particular order, these guidelines:

* Cyborg, not Robot: Scripts are extentions of the sysadmin that are essentially runable documentation.
* Attempted Portability: While portability is not a focus and we will not bend over backwards to make it so, we do attempt to pick portable options where possible.
* Good Documentation: Every script should be well commented and readable. Each script should have usage instructions.
* Any Task that multiple scripts may need to run will be extracted to it's own script.
* Use Full Argument Names: Whenever possible, scripts should use the full opt names for commands (I.e. --help instead of -h, --follow instead of -f). Short opts are useful when you're running a command one off, but for scripts using the full name makes things more readable.
* Unified Look: Scripts should configure applications to have a unified style and navigation header.
* Chroot Compatible: Scripts should be able to target a chroot container as well as the base OS.
* Centralized File Access: Scripts should configure applications to centralize their files (app files, logs, etc) in /srv either by storing files there or symlinking.
* Scripts will follow this design scheme:
    * Every __script__ is designed to accomplish a specific __job__. For example "install nginx".
    * Every __job__ will be broken down into one or more logical __tasks__ that follow a 3 part pattern: Check if safe, do task, check for errors.


## Services and Applications Used

Scripts should be able to do the following using the listed applications:

* Init and shutdown scripts to make sure server restarts go smoothly.
* [**Certbot**](https://github.com/certbot) for automatic Let's Encrypt renewal for sitewide SSL.
* [**ORY Hydra**](https://github.com/ory/hydra) OAuth server to allow site-wide single sign-on.
* [**Nginx**](https://nginx.org/) proxy that handles routing requests to the right application and serving the webpage portion of the website.
* [**NodeBB**](https://nodebb.org/) to serve as the forum.
* [**Veaos**](https://github.com/veaos/veaos) to serve as a Q&A board (like stackoverflow).
* [**Conduit**](https://conduit.rs/), a matrix homeserver, to serve as instant messaging and VoIP.


# Installation and Usage

## Prep

You will need an ubuntu server ready to go with git installed. Clone the repo into your /root/scripts/ folder and you are done with prep.

## Using the Scripts

You may want to navigate to the scripts folder in this repo and run the master script "setup_webserver.sh" which will guide you through setting up a server. 
Warning: this script can take a long time so you may want to run it in a 'screen' so you can leave it and come back without interruption.

While the script is running you will be prompted with various choices and provided information. You will want to read over everything to make sure each step completes successfully before going onto the next step.


**Alternatively** feel free to look throught the scripts and check out their usage information.
