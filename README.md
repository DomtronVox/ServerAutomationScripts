Repo containing scripts and custom files needed to setup a server from scratch the Cerval Website server and later maybe other servers later on.

Note that these setup scripts are tested against Ubuntu specifically 20.04 LTS.

# Repo Structure

* docs/: contains and additional documentation needed about this server setup process not already in the scripts themselves.
* scripts/: contains all the scripts that make up the setup process.
  * scripts/common.inc: a collection of functions that all scripts include to make things more unified and a bit easier to do.
  * scripts/setup: scripts to help setup a fresh system.
  * scripts/maintenance: scripts that are either cron'ed or manually run after server setup to make sure everything is maintained. 
* custom_files: Contains folders for each application we use that hold custom, hand made files that will be 'installed' into their respective apps. Things like config files and styling files.


# End Target

When the setup scripts finish running, there should be a complete ecosystem ready to go that includes:
* Init and shutdown scripts to make sure Server resets go smoothly.
* Automatic Let's Encrypt renewal for sitewide SSL.
* OAuth server to allow site-wide single sign-on.
* Nginx proxy that handles routing requests to the right application and serving the webpage portion of the website.
* NodeBB to serve as the forum.
* Veaos to serve as a Q&A board (like stackoverflow).
* Dendrite, a matrix homeserver, to serve as instant messaging and VoIP.
* Our custom CDN for mod distribution.


# Usage

## Prep

You will of course need an ubuntu server ready to go with git installed. Clone the repo and you are done with prep.


## Usage

You will want to navigate to scripts/setup and run the master script "setup_webserver.sh". 
While the script is running you will be prompted with various choices and provided information. You will want to read over everything to make sure each step completes successfully.


# Script Design

Every __script__ is designed to accomplish a specific __job__. For example "install nodebb".

Every __job__ will be broken down into one or more logical __tasks__ that follow a 3 part pattern: Check if safe, do task, check for errors. 

Any Task that multiple scripts may need to perform will be extracted to be it's own script and job.
