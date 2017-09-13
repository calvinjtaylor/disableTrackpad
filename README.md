# disableTrackpad.sh

## Description
A complicated script for a simple problem.  Every ubuntu solution seemed to leave the trackpad enabled on my computer, an ASUS Ultrabook.  Which seems to have the worst trackpad ever.

## Usage

 * disableTrackpad.sh - no args will disable the trackpad if a mouse is connected.
 * disableTrackpad.sh force - disable the trackpad regardless if a mouse is connected or not.
 * disableTrackpad.sh enable - reenable the trackpad if a mouse is not connected.
 * disableTrackpad.sh enable force - reenable the trackpad regardless if a mouse is connected or not.
 * disableTrackpad.sh install - copies script to /usr/local/bin, and writes proper udev rule file to call that script.  Requires root privleges.
 * disableTrackpad.sh --help - show this help screen.

 ## Tested
 This has only been tested on Ubuntu so far.
