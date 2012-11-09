#!/bin/bash

#############################################
# This is a simple battery warning script.  #
# It uses i3's nagbar to display warnings.  #
#                                           #
# @author agribu <agribu[att]online[dott]de>#
#############################################

# lock file location
export LOCK_FILE=/tmp/battery_state.lock

# check if another copy is running
if [[ -a $LOCK_FILE ]]; then

    pid=$(cat $LOCK_FILE | awk '{print $1}')
	ppid=$(cat $LOCK_FILE | awk '{print $2}')
	# validate contents of previous lock file
	vpid=${pid:-"0"}
	vppid=${ppid:-"0"}

    if (( $vpid < 2 || $vppid < 2 )); then
		#echo "Corrupt lock file $LOCK_FILE ... Exiting"
		cp -f $LOCK_FILE ${LOCK_FILE}.`date +%Y%m%d%H%M%S`
		exit
	fi

    # check if ppid matches pid
	ps -f -p $pid --no-headers | grep $ppid >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
		#echo "Another copy of script running with process id $pid"
		exit
	else
		#echo "Bogus lock file found, removing"
		rm -f $LOCK_FILE >/dev/null
	fi

fi

pid=$$
ps -f -p $pid --no-headers | awk '{print $2,$3}' > $LOCK_FILE
#echo "Starting with process id $pid"

# set Battery
BATTERY=/sys/class/power_supply/BAT1

# get battery status
STAT=$(cat $BATTERY/status)

# get remaining energy value
REM=`grep "POWER_SUPPLY_ENERGY_NOW" $BATTERY/uevent | cut -d= -f2`

# get full energy value
FULL=`grep "POWER_SUPPLY_ENERGY_FULL_DESIGN" $BATTERY/uevent | cut -d= -f2`

# get current energy value in percent
PERCENT=`echo $(( $REM * 100 / $FULL ))`

# set error message
MESSAGE="AWW SNAP! I am running out of juice ...  Please, charge me or I'll have to power down."

# set energy limit in percent
LIMIT="30"

    echo $STAT
# set limit and show warning
if [ $PERCENT -le "$(echo $LIMIT)" ] && [ "$STAT" == "Discharging" ]; then
    DISPLAY=:0.0 /usr/bin/i3-nagbar -m "$(echo $MESSAGE)"
fi
