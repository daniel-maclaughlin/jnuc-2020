#!/bin/sh

#Part 1, making our audit file
###############################
#Audit Log
audit_log="/Users/Shared/.login_audit.log"

#Get jamf connect Log path
jamf_connect_log="/private/tmp/jamf_login.log"

#Get current date in YYYY-mm-dd_HH:MM:SS format
current_date=$(/bin/date +"%Y-%m-%d_%H-%M-%S")

#check if Local Auth button was pressed
local_auth=$(/bin/cat $jamf_connect_log | grep "Local auth continue pressed.")

#check if there has been a successful network auth
network_auth=$(/bin/cat $jamf_connect_log | grep "OIDC Auth succeded")

#check if network auth was successful, if so we can trash the audit
if [[ $network_auth =~ "OIDC Auth succeded" ]];then
        echo "network login occured"
        /bin/rm $audit_log
fi

#check if local auth button was pressed, if so write out the audit log
if [[ $local_auth =~ "Local auth continue pressed." ]];then
        echo "local login occured at $current_date" >> $audit_log
fi

###############################

#Part 2 - Checking the audit file
###############################

#check for the audit file, if its not present then no need to perform count
if [ ! -f "$audit_log" ]; then
        echo "user has been doing the right thing nothing to do"
        else
        # count how many times the user has clicked everything_is_good
        count=$(cat "$audit_log"| wc -l | tr -d '[:space:]')        
fi


#Part 3 - Taking action
###############################
#first we are going to wait for the desktop to load so that we can display our messages
dockStatus=$(pgrep -x Dock)

while [[ "$dockStatus" == "" ]]
do
        echo "Desktop is not loaded. Waiting."
        sleep 0.5
        dockStatus=$(pgrep -x Dock)
done


#if they are past 3 then we are at the warning stage
if [[ $count -ge 3 ]] && [[ $count -lt 10 ]];then
        
        #apple script message
message=$(
/usr/bin/osascript -e 'tell application "System Events"
activate
display dialog "The system has detected that you have bypassed network login '$count' times, please log out and log back in using the corportate login system, if you have issues please contact IT support, if you continue to bypass the correct login your machine maybe disabled" with title "Security Alert" buttons {"OK"} with icon caution
end tell' 2>/dev/null)

fi

#if they are at 10 or more they need something to be fixed
#be sure with full remediation to clear the audit log
if [[ $count -ge 10 ]];then
        #apple script message
message=$(
/usr/bin/osascript -e 'tell application "System Events"
activate
display dialog "Your machine is going to be disabled, to resolve please login via network method" with title "Security Alert" buttons {"OK"} with icon caution giving up after 5
end tell' 2>/dev/null)
        /usr/bin/pkill loginwindow
fi

#move log to sub folder to prevent duplicate reports
#wait a few moments for the log to complete before miving it
/bin/sleep 10
/bin/mv $jamf_connect_log $jamf_connect_log$current_date.log
