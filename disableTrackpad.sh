#!/usr/bin/env bash
#author calvin.taylor
#Sept 7, 2017
# a small script to enact some control over rogue trackpads.

#background, I have an asus ultrabook running ubuntu and cinnamon and the trackpad always seemed enabled while typing.
#function;  rerunable script to disable/enable any trackpad

#uses can be put into .bashrc or .profile to permentantly disable trackpad
argIs(){
  #returns true if arg is set to value
  #argIs $1 'enable' returns true
  local expectedArgValue=$1
  local arg=$2
  [ -n "$arg" ] && [ -n "$expectedArgValue" ] && [ "$arg" = "$expectedArgValue" ]
}

SI=$(basename $0)
LOGDIR="/tmp"
LOG="$LOGDIR/$SI.log"

Log() {
	echo "`date` [$SI] $@" >> $LOG
}

PrintAndLog() {
	Log "$@"
	echo "$@"
}

ErrorAndLog() {
	Log "[ERROR] $@ "
	echo "$@" >&2
}

Run() {
	Log "Running '$@' in '`pwd`'"
  $@ 2>&1 | tee -a $LOG
}

showHelp(){
  echo
  echo "$SI - a tool to disable and reenable a trackpad while a mouse is plugged in. "
  echo
  echo " USAGE"
  echo " $SI - no args will disable the trackpad if a mouse is connected."
  echo " $SI force - disable the trackpad regardless if a mouse is connected or not."
  echo " $SI enable - reenable the trackpad if a mouse is not connected."
  echo " $SI enable force - reenable the trackpad regardless if a mouse is connected or not."
  echo " $SI --help - show this help screen."
  echo
  exit 0
}

installMouseInsertRuleFile(){
  #credit here to
  #https://unix.stackexchange.com/questions/65891/how-to-execute-a-shellscript-when-i-plug-in-a-usb-device
  #https://bbs.archlinux.org/viewtopic.php?id=104875
  local VendorInfo=$(lsusb | grep -i "mouse" | grep -oP "ID \S+" | awk '{print $2}' | tr ':' ' ') # 046d c069
  local Vendor=$(echo $VendorInfo | awk '{print $1}')
  local Product=$(echo $VendorInfo | awk '{print $2}')
  # local fullPath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  local scriptName=$(basename "${BASH_SOURCE[0]}" | tr '.' ' ' |  awk '{print $1}')
  local rulesFile="/etc/udev/rules.d/$scriptName.rules"

  #how do i get the user when I need to be root?
  local suUser=$(logname)
  local rule="ACTION==\"add\", ATTRS{idVendor}==\"$Vendor\", ATTRS{idProduct}==\"$Product\", ENV{DISPLAY}=\":0.0\", ENV{XAUTHORITY}=\"/home/$suUser/.Xauthority\", RUN+=\"/usr/local/bin/$scriptName.sh\""
  local rule2="ACTION==\"remove\", ATTRS{idVendor}==\"$Vendor\", ATTRS{idProduct}==\"$Product\", ENV{DISPLAY}=\":0.0\", ENV{XAUTHORITY}=\"/home/$suUser/.Xauthority\", RUN+=\"/usr/local/bin/$scriptName.sh enable force\""

  local action="write"
  [ -f "$rulesFile" ] && action="overwrite"
  PrintAndLog "Attempting action of $rulesFile with $rule"
  printf "$rule\n$rule2" > $rulesFile && PrintAndLog "Wrote new usb mouse insert rule file at $rulesFile" || ( ErrorAndLog "Failed to write rules file at $rulesFile, check if adequate permissions" && exit 2 )
}

installFileToUsrLocalBin(){
  local scriptName=$(basename "${BASH_SOURCE[0]}" | tr '.' ' ' |  awk '{print $1}')
  local fullPath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  local file=$fullPath/$SI
  local target=/usr/local/bin/$scriptName.sh
  local eCode=0
  if [ "$file" = "$target" ] ; then
    ErrorAndLog "Can't install from $fullPath" && exit 1
  fi
  cp -f $file $target  && PrintAndLog "Installed $file to $target" || ( ErrorAndLog "Couldn't install $file to $target" ; exit 2 )
  chmod +x $target && PrintAndLog "Set $target executable" || ( ErrorAndLog "Couldn't set $target executable" ; exit 2 )
  # udevadm trigger
  /etc/init.d/udev stop && /sbin/udevadm control --reload-rules && /sbin/udevadm trigger --attr-match=idVendor='046d' || ( ErrorAndLog "Couldn't trigger udev rule change" ; ((uCode++)) )
  /etc/init.d/udev start
  PrintAndLog "Installation complete"
  exit $uCode
}

FORCE="false"
ENABLETRACKPAD="false"
MOUSEENABLED="false"

PrintAndLog "Running"

parseArgs(){
    for a in $@; do
      argIs "enable" "$a" && ENABLETRACKPAD="true" && PrintAndLog "Attempting to enable trackpad"
      argIs "force" "$a" && FORCE="true" && PrintAndLog "Force Mode Detected"
      argIs "--help" "$a" && showHelp && PrintAndLog "Showing help screen"
      argIs "install" "$a" && installMouseInsertRuleFile && installFileToUsrLocalBin
    done

    local mouseDeviceName=$(/usr/bin/xinput list --name-only | grep -i "mouse")
    [ -n "$mouseDeviceName" ] && MOUSEENABLED="true" && PrintAndLog "Mouse Detected" || PrintAndLog "No mouse detected"
}

isForce(){
  argIs "true" "$FORCE"
}

isEnableTrackpad(){
  argIs "true" "$ENABLETRACKPAD"
}

isMouseEnabled(){
  argIs "true" "$MOUSEENABLED"
}

parseArgs $@

# [ -n "$USER" ] && export USER=$(id -u -n)
# using Run below trapped the stderr messages being given
# Run /usr/bin/xinput --help
# Run /usr/bin/xinput list --name-only

trackpadDeviceName=$(/usr/bin/xinput  list --name-only | grep -i "touchpad")
if [ -n "$trackpadDeviceName" ]; then
  A=$(/usr/bin/xinput  list-props "$trackpadDeviceName" | sed -n -e 's/.*Device Enabled ([0-9]\+):\t\(.*\)/\1/p' )
  if [ -n "$A" ]; then
    if [ "$A" -eq "1" ] && ( isForce || isMouseEnabled ) && ! isEnableTrackpad  ; then
      PrintAndLog "Disabling trackpad $trackpadDeviceName"
      /usr/bin/xinput set-int-prop "$trackpadDeviceName" "Device Enabled" 8 0
    elif [ "$A" -eq "0" ] && ( isForce || ! isMouseEnabled ) && isEnableTrackpad ; then
      PrintAndLog "Enabling trackpad $device"
      /usr/bin/xinput set-int-prop "$trackpadDeviceName" "Device Enabled" 8 1
    fi
  else
    PrintAndLog "No xinput props found for device enabled."
  fi
else
  PrintAndLog "No trackpad detected"
fi
