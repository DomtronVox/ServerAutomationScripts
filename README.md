This repo contains scripts and custom files needed to setup a server from scratch to serve the Cerval Website ecosystem, and later maybe other Cerval related servers as well.

Note that these setup scripts are tested against Ubuntu, specifically ubuntu 20.04 LTS, 64-bit, but we make some effort for them to be portable. Note a big sticking point for portability will be that all install scripts will be using apt. 

# Repo Structure

* docs/: Contains and additional documentation needed about this server setup process not already in the scripts themselves.
* scripts/: Contains all the scripts that make up the setup process.
  * scripts/common/: A collection of include scripts that all scripts include to make scripts more unified and a bit easier to develop.
  * scripts/setup/: Scripts to help setup a fresh system.
  * scripts/maintenance: Scripts that are either cron'ed or manually run after server setup to make sure everything is maintained. 
* custom_files: Contains folders for each application we use that hold custom, hand made files that will be 'installed' into their respective apps. Things like config files and styling files.


# End Target

We aim for these scripts to create and maintain a server to do the following:

* Init and shutdown scripts to make sure Server resets go smoothly.
* Automatic Let's Encrypt renewal for sitewide SSL.
* OAuth server to allow site-wide single sign-on.
* Nginx proxy that handles routing requests to the right application and serving the webpage portion of the website.
* NodeBB to serve as the forum.
* Veaos to serve as a Q&A board (like stackoverflow).
* Dendrite, a matrix homeserver, to serve as instant messaging and VoIP.
* Our custom CDN for mod distribution.
* Everything using a unified style and navigation header.

# Usage

## Prep

You will of course need an ubuntu server ready to go with git installed. Clone the repo (We sugest /root/scripts/) and you are done with prep.


## Using the Scripts

You will want to navigate to scripts/setup and run the master script "setup_webserver.sh". Warning: this script can take a long time so you may want to run it in a 'screen' so you can leave it and come back.

While the script is running you will be prompted with various choices and provided information. You will want to read over everything to make sure each step completes successfully before going onto the next step.


# Script Design

Every __script__ is designed to accomplish a specific __job__. For example "install nginx".

Every __job__ will be broken down into one or more logical __tasks__ that follow a 3 part pattern: Check if safe, do task, check for errors. 

Any Task that multiple scripts may need to run will be extracted to it's own script.

# Scripting Guidlines

* Cyborg, not Robot: Scripts help make processes easier to do, but will still need intellegant choices from the user. Any script that must be fully automatic (cron job triggered scripts) should be likewise denoted in the name.
* Attempted Portability: While portability is not a focus and we will not bend over backwards to make it so, we do attempt to pick portable options where possible.
* Document Your Code: Every script should be well documented, both for the user and anyone who needs to maintain it.


