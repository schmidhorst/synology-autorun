#!/bin/bash
# called from udev. Attention: Environment (e.g. PATH) is not set!
# https://raw.githubusercontent.com/reidemei/synology-autorun/main/package/autorun
# re-written Horst Schmid 2022...2023

# default settings
TRIES=20
WAIT=0 # wait (seconds) time after mountpoint found
ADD_NEW_FINGERPRINTS=1 # allow changed or new scripts
FINGERPRINTS_INCL_DRIVE=0 # 0: allow script from any drive
SCRIPT_AFTER_EJECT=""

# $1 is e.g. 'usb1p1'

# if the last line in "$SCRIPT_EXEC_LOG" contains $1, then replace that line by $2, else append $2
# This is to reduce the number of entries in $SCRIPT_EXEC_LOG
replaceLastLogLineIfSimilar() {
  latestEntry="$(/bin/tail -1 "$SCRIPT_EXEC_LOG")"
  if [[ "$latestEntry" == *"$1"* ]]; then
    lineCount=$(/bin/wc -l < "$SCRIPT_EXEC_LOG")
    /bin/sed -i -e "$lineCount,\$d" "$SCRIPT_EXEC_LOG"
    /bin/echo "$(date "$DTFMT"): $2" >> "$SCRIPT_EXEC_LOG"
    logInfo 8 "Last Entry in SCRIPT_EXEC_LOG replaced"
  else
    /bin/echo "$(date "$DTFMT"): $2" >> "$SCRIPT_EXEC_LOG"
    logInfo 8 "Item '$1' not found in SCRIPT_EXEC_LOG last line: '$latestEntry'"
  fi # if [[ "$latestEntry" == *"$diskName"* ]]
}

executeConfiguredScript(){
  # $1 is e.g. 'usb1p1'
  # run it:
  logInfo 3 "starting now '$scriptFullPathName' ..."
  dateStart_s=$(/bin/date +"%s")
  dateStart_string=$(/bin/date "$DTFMT")
  /bin/echo "$(/bin/date "$DTFMT"): The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was started and is running ..." >> "$SCRIPT_EXEC_LOG"
  if (((LED & 1)!=0)); then  # by default this LED is OFF of GREEN
    beep LED_STATUS_GREEN
  elif (((LED & 2)!=0)); then
    beep LED_STATUS_GREEN_FLASH
  fi
  if (((LED_COPY & 1)!=0)); then
    beep LED_COPY_ON
  elif (((LED_COPY & 2)!=0)); then
    beep LED_COPY_FLASH
  fi
  /bin/sh "$scriptFullPathName" "$MOUNTPATH" "$1" 2>&1 | /bin/tee -a "$LOGFILE"; RESULT=${PIPESTATUS[0]}
  lastScriptMsg=$(/bin/tail -n 1 "$LOGFILE")
  # /bin is a link to /usr/bin. And /bin/sh is a link to /usr/bin/bash.
  /bin/echo "Back in $scriptThisFullPhysicalPathName from $scriptFullPathName with result='$RESULT'"
  dateFinished_s=$(/bin/date +"%s")
  if [[ "$LED" == "1" ]]; then
    beep LED_STATUS_GREEN_FLASH
  fi
  if (((LED_COPY & 7)!=0)); then
    beep LED_COPY_OFF # Copy LED off
    if [[ "$RESULT" != 0 ]] && [[ "$RESULT" != 100 ]]; then
      if (((LED_COPY & 4)!=0)); then
        beep LED_COPY_FLASH
      fi
    fi
  fi # if LED_COPY
  execTime_s=$(( dateFinished_s - dateStart_s ))
  if ((execTime_s > 60 )); then
    (( execTime_min = execTime_s / 60 ))
    (( execTime_s = execTime_s % 60 ))
    execTime="${execTime_s}s"
    if ((execTime_min > 60 )); then
      (( execTime_h = execTime_min / 60 ))
      (( execTime_min = execTime_min % 60 ))
      execTime="${execTime_h}h ${execTime_min}min $execTime"
    else
      execTime="${execTime_min}min $execTime"
    fi
  else
    execTime="$execTime_s seconds"
  fi
  #/bin/echo "$(date "$DTFMT"): The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was finished after $execTime with return code $RESULT" >> "$SCRIPT_EXEC_LOG"
  # get the free space
  FREE=$(/bin/df -h "$MOUNTPATH" | /bin/grep "$MOUNTPATH" | /bin/awk '{ print $4 }')  # e.g. "2.1T"
  ejected=0 # 0: no eject, 1: ejecting, 2: eject success, 3: eject fail
  # unmount when the result is 100
  if [ "$RESULT" == "100" ]; then
    /bin/echo "Result 100 detected"
    if [ "$LED" = "1" ];then
      # beep 5 # Power LED flashing
      beep LED_STATUS_GREEN_FLASH
    fi
    logInfo 2 "device '$1' - script '$scriptFullPathName' finished with $RESULT ($FREE left on device), starting unmount"
    d1=$(/bin/echo "$1" | /bin/sed 's:/dev/::' | /bin/sed 's:p.*::') # # $1 is e.g. 'usb1p1' or '/dev/usb1p1', d1 is now e.g. 'usb1'
    info=$(/usr/syno/bin/synousbdisk -info "$d1")
    sn=$(/bin/echo "$info" | /bin/grep "Share Name:") # catch line with the share name
    sn=${sn#*:} # remove the label
    sn=$(/bin/echo "$sn") # remove blanks, so we get e.g. usbshare4
    ejected=1  #1: ejecting, 2: eject success, 3: eject fail
    endTime=$(($(/bin/date +%s) + EJECT_TIMEOUT))
    k=$TRIES # $TRIES is from the config file
    while [[ $(/bin/date +%s) -le $endTime ]]; do # loop with counter as the external drive may be in use ...
      # try to do the unmount
      logInfo 8 "till eject timeout left $(( endTime - $(date +%s) ))"
      /bin/sleep 3
      /bin/sync
      /bin/sleep 6
      /usr/syno/bin/synousbdisk -rcclean
      /bin/sleep 6

      # /bin/umount $MOUNTPATH
      resultd=$(/usr/syno/bin/synousbdisk -umount "$d1")
      retvald=$?
      if [ $retvald -eq 0 ];then # success
        # 2nd Part of umount (neccessary?)
        results=$(/usr/syno/bin/synousbdisk -umount "$sn")
        retvals=$?
      fi
      /bin/sleep 45
      logInfo 7 "Loop $k: synousbdisk -umount $d1 was $retvald ($resultd), synousbdisk -umount $sn was $retvals ($results)"
      # check whether now realy no more mounted:
      resultm=$(/bin/mount 2>&1 | /bin/grep "/dev/$1" | /bin/cut -d ' ' -f3)
      if [ -z "$resultm" ]; then # synousbdisk -umount was really successfull
        logInfo 5 "Updating now /tmp/usbtab ..."
        ejected=2 # 0: no eject, 1: ejecting, 2: eject success, 3: eject fail
        # Remove it now from the 'gui' list:
        /bin/cp /tmp/usbtab /tmp/usbtab.old
        /bin/grep -v "$d1" /tmp/usbtab.old > /tmp/usbtab  # copy all non-matching lines
        /bin/rm -f /tmp/usbtab.old
        # unbind ??? # Optional !!!????
        logInfo 3 "device '$1' successfully unmounted and removed from GUI!"
        break
      fi
      if [[ $ejected -eq 1 ]]; then
        logInfo 4 "Drive seems busy! k=$k Please wait ..."
      fi
      /bin/sleep 60
      ((k--))
    done # while not timeout
    if [[ -z "$details" ]]; then # not in lang.txt
      details="Details"
    fi
    detailLink="<a href='/usr/syno/synoman/webman/3rdparty/$SYNOPKG_PKGNAME/index.cgi'> details </a>" # is the token needed?
    if [[ $ejected -eq 1 ]]; then
      /bin/echo "$(date "$DTFMT"): The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was finished after $execTime with return code $RESULT. Attention: The requested ejection of the device failed!!" >> "$SCRIPT_EXEC_LOG"
      ejected=3 # failed
    fi
    logInfo 4 "Eject part finisched with $ejected. (2: eject success, 3: eject fail) "
    if [[ -n "$SCRIPT_AFTER_EJECT" ]]; then
      if [ -x "$SCRIPT_AFTER_EJECT" ]; then
        if [[ "$ejected" -eq "2" ]]; then
          logInfo 5 "Script '$SCRIPT_AFTER_EJECT' will be started without parameter!"
          /bin/sh "$SCRIPT_AFTER_EJECT"
          res="$?"
          replaceLastLogLineIfSimilar "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH" "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was started $dateStart_string and finished after $execTime with return code $RESULT ($lastScriptMsg). Device successfully ejected and the script '$SCRIPT_AFTER_EJECT' done with return code $res. ${FREE}Bytes free"
        else
          # if $ejected != 2
          logInfo 3 "Script '$SCRIPT_AFTER_EJECT' will be started with 'Ejection failed'!"
          /bin/sh "$SCRIPT_AFTER_EJECT" "Ejection failed"
          /bin/echo "$(date "$DTFMT"): The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was finished after $execTime with return code $RESULT. Device ejecting was failing. The script '$SCRIPT_AFTER_EJECT' with parameter 'Ejection failed' done." >> "$SCRIPT_EXEC_LOG"
        fi # if [[ "$ejected" -eq "2" ]] else
      else
        logInfo 0 "The script '$SCRIPT_AFTER_EJECT' is not executable for actual user"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg10" "$SYNOPKG_PKGNAME" "$scriptFullPathName" "$SCRIPT_AFTER_EJECT" "$detailLink"
                                        # $dsmappname is setup in INFO file, e.g. "SYNO.SDS._ThirdParty.App.autorun"
        fi
      fi # if [ -x "$SCRIPT_AFTER_EJECT" ] else
    else
      logInfo 6 "No SCRIPT_AFTER_EJECT specified"
      replaceLastLogLineIfSimilar "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH" "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was started $dateStart_string and finished after $execTime with return code $RESULT ($lastScriptMsg). ${FREE}Bytes free."
    fi # if [[ -n "$SCRIPT_AFTER_EJECT" ]] else

    if [[ $ejected -eq 3 ]]; then
      # Ejection of device failed!
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg7" "$scriptFullPathName" "$MOUNTPATH" "$RESULT" "$detailLink"
      fi
      /bin/echo "$(date "$DTFMT"): Ejection of '$diskName', mounted as $MOUNTPATH failed!" >> "$SCRIPT_EXEC_LOG"
    else
      if [[ -n "$NOTIFY_USERS" ]] && [[ ";$NO_DSM_MESSAGE_RETURN_CODES;" != *";$RESULT;"* ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg8" "$scriptFullPathName" "$MOUNTPATH" "$RESULT" "$detailLink" "$FREE"
      fi
    fi
  else # result != 100
    replaceLastLogLineIfSimilar "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH" "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was started $dateStart_string and finished after $execTime with return code $RESULT. ${FREE}Bytes free."
    /bin/echo "Result $RESULT != 100"
    logInfo 5 "device '$1' - script '$scriptFullPathName' finished with $RESULT ($lastScriptMsg) ($FREE left on device), no unmount requested"
    if [[ -n "$NOTIFY_USERS" ]] && [[ ";$NO_DSM_MESSAGE_RETURN_CODES;" != *";$RESULT;"* ]]; then
      /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg9" "$scriptFullPathName" "$MOUNTPATH" "$RESULT" "$detailLink" "$FREE"
    fi
  fi # if [ "$RESULT" == "100" ] else

  if [[ "$LED" -ne "0" ]]; then
    if [[ $ejected -eq 3 ]]; then  # failure during ejection
      beep LED_STATUS_ORANGE_FLASH
    elif [[ "$LED" == "2" ]]; then
      if [[ "$RESULT" == "100" ]] || [[ "$RESULT" == "0" ]]; then
        beep LED_STATUS_GREEN
      else
        beep LED_STATUS_ORANGE_FLASH
      fi
    else
      if [[ "$RESULT" == "100" ]] || [[ "$RESULT" == "0" ]]; then
        beep LED_STATUS_OFF
      else
        beep LED_STATUS_ORANGE_FLASH
      fi
    fi
  fi
  if (((LED & 1)!=0)); then
    beep LED_STATUS_GREEN
  fi
  if (((LED_COPY & 3)!=0)); then
    beep LED_COPY_OFF
  fi
} # executeConfiguredScript()


########################################### start point #####################
# environment PATH is empty when started via event!!!

SCRIPTPATHTHIS="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" # e.g. /volumeX/@appstore/<app>
baseNameThis="$(basename "$0")"
scriptThisFullPhysicalPathName=$SCRIPTPATHTHIS/$baseNameThis # with physical path
if [[ -z "$SYNOPKG_PKGNAME" ]]; then
  SYNOPKG_PKGNAME=${SCRIPTPATHTHIS##*/}
  myMsg="SYNOPKG_PKGNAME='$SYNOPKG_PKGNAME' extracted from SCRIPTPATHTHIS"
else
  myMsg="SYNOPKG_PKGNAME='$SYNOPKG_PKGNAME' was available"
fi
source "/var/packages/$SYNOPKG_PKGNAME/var/config" # import our config

# import helper functions logInfo(), beepError() and beep() (also used for LED control):
if [[ ! -x "/var/packages/$SYNOPKG_PKGNAME/target/common" ]]; then
  /bin/echo "###########################################################################"
  /bin/echo "Error: File '/var/packages/$SYNOPKG_PKGNAME/target/common' not available or not executable!" | tail -a "/var/log/packages/$SYNOPKG_PKGNAME.log"
  /bin/echo "###########################################################################"
  exit 1
fi
source "/var/packages/$SYNOPKG_PKGNAME/target/common" "$SYNOPKG_PKGNAME" # lngUser, lngMail (for Logfile) set, $APPDATA/config read
/bin/echo -e "" >> "$LOGFILE" # empty row
user=$(whoami) # EnvVar $USER may be not well set
versShell="$($SHELL --version | sed -n '1p')"
logInfo 3 "Start of $0 as user '$user' with SHELL='$SHELL' ($versShell) ..."
logInfo 6 "$myMsg"
if [ -z "$1" ]; then
  /bin/echo "incorrect '\$1' - aborting ..."
  logInfo 0 "Error: Parameter 1 missing in $0"
  beepError
  exit 1
fi

MOUNTPATH="" # external Disk
scriptFullPathName="" # internal $SCRIPT or $MOUNTPATH/$SCRIPT
eval "$(grep "dsmappname=" "/var/packages/$SYNOPKG_PKGNAME/INFO")"
logInfo 6 "The 'dsmappname', the class for synodsmnotify is '$dsmappname'"
# dsmappname needs to match the .url in ui/config. Otherwise synodsmnotify will not work
# used as CLASS in synodsmnotify
COUNT=0
SCRIPT_EXEC_LOG="$APPDATA/execLog" # logfile with 1 ..2 lines per executed script
if [[ -f "$SCRIPT_EXEC_LOG" ]]; then
  logInfo 6 "File $SCRIPT_EXEC_LOG exists"
  lineCount=$(/bin/wc -l < "$SCRIPT_EXEC_LOG")
  logInfo 6 "The log file '$SCRIPT_EXEC_LOG' has $lineCount lines, configured maximum is $LOG_MAX_LINES"
  # /bin/echo "lineCount=$lineCount"
  if [[ "$lineCount" -gt "$LOG_MAX_LINES" ]]; then
    newLineCount=$((LOG_MAX_LINES / 2))
    delLines=$((lineCount - newLineCount))
    /bin/sed -i -e "1,${delLines}d" "$SCRIPT_EXEC_LOG"
    logInfo 4 "The log file '$SCRIPT_EXEC_LOG' was trimmed from $lineCount to $newLineCount lines"
  fi
else
  /bin/touch "$SCRIPT_EXEC_LOG" # created an empty file
  /bin/chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "$SCRIPT_EXEC_LOG" # make it accessable & readable for the cgi scripts
  /bin/chmod 644 "$SCRIPT_EXEC_LOG"
fi

if [[ -f "$LOG" ]]; then
  lineCount=$(/bin/wc -l < "$LOG")
  logInfo 6 "The log file '$LOG' has $lineCount lines, configured maximum is $LOG_MAX_LINES"
  if [[ $lineCount -gt "$LOG_MAX_LINES" ]]; then
    newLineCount=$((LOG_MAX_LINES / 2))
    delLines=$((lineCount - newLineCount))
    /bin/sed -i -e "1,${delLines}d" "$LOG"
    logInfo 4 "The log file '$LOG' was trimmed from $lineCount to $newLineCount lines"
  fi
else
  /bin/touch "$LOG"
  /bin/chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "$LOG"
  /bin/chmod 644 "$LOG"
fi

# try to get the mount path
logInfo 5 "device '$1' - inserted, trying to find mount point"
COUNT=0
while [ -z "$MOUNTPATH" ] && [ $COUNT -lt $TRIES ] ; do
  MOUNTPATH=$(/bin/mount 2>&1 | /bin/grep "/dev/$1" | /bin/cut -d ' ' -f3)
  if [ -z "$MOUNTPATH" ]; then
    COUNT=$((COUNT+1))
    /bin/sleep 1s  # V1.8.1: 4s
  fi
done

# abort when nothing is found
if [ -z "$MOUNTPATH" ]; then
  logInfo 0 "device '$1' - unable to find mount point within $COUNT seconds, aborting"
  beepError
  exit 1
fi
logInfo 3 "device '$1' - mount point '$MOUNTPATH' found after $COUNT seconds"

# sleep some time because Synology does some crazy stuff like un- and remounting on SATA
/bin/sleep $WAIT
bError=0
usbNo=${MOUNTPATH%/*} # remove /usbshare from e.g. /volumeUSB2/ussbshare
usbNo=${usbNo#*volumeUSB}
# /bin/echo "usbNo=$usbNo"
diskID=$(/bin/grep "${usbNo}=" "/usr/syno/etc/usbno_guid.map") # e.g. 14="20190123456780"
diskID=${diskID%0\"}  # remove trailing '0"'
diskID=${diskID#*=\"} # Remove leading Quote, now e.g. "2019012345678"
# /bin/echo "diskID=$diskID"
diskName=$(/usr/syno/bin/lsusb | /bin/grep "$diskID") # e.g. "|__2-2.2 1234:5678:90AB 00 3.00 5000MBit/s 8mA 1IF (...)"
diskName=${diskName#*(}
diskName=${diskName%)*}
# /bin/echo "diskName=$diskName" # e.g. "Intenso external USB 3.0 2019012345678"

# is there the script according to SCRIPT="..." in the config file on our DSM or external drive?
if [[ "$SCRIPT" == *"/"* ]]; then
  scriptFullPathName="$SCRIPT"  # script on DSM, not at external storage
  scriptExternal=0
  # check for file with other upper/lower case already done in start-stop-status
else
  scriptFullPathName="$MOUNTPATH/$SCRIPT" # script on external storage
  scriptExternal=1
  if [ -x "$scriptFullPathName" ];then
    logInfo 5 "device '$1' - executable script '$scriptFullPathName' found"
  elif [[ -f "$scriptFullPathName" ]]; then
    logInfo 1 "device '$1' - script '$scriptFullPathName' found, but not executable!"
  else
    res="$(/bin/find -L "$MOUNTPATH" -maxdepth 1 -iname "$SCRIPT" -type f)" # -L Follow symbolic links
    if [[ -n "$res" ]]; then
      logInfo 1 "device '$1' - script '$res' found, but it's different in upper/lower case and will not ignored!"
      /bin/echo "$(date "$DTFMT"): Suspicous: There is a script '$res', but it's name is different in upper/lower case and therefore will be ignored!" >> "$SCRIPT_EXEC_LOG"
    fi
  fi
fi
if [ -x "$scriptFullPathName" ];then
  if [ "$BEEP" == "true" ]; then
    beep "$BEEP_SHORT"
  fi
  if [ "$LED" = "1" ]; then
    beep "$LED_STATUS_ORANGE"
  fi

  # Security feature (check checksum of script), similar to
  # https://github.com/JC-23/synology-autorun/releases/tag/v1.9-beta
  ####################################################################
  KNOWNSCRIPTSFILEPATHNAME=$APPDATA/FINGERPRINTS
  ENTRY_COUNT=0
  if [ -f "$KNOWNSCRIPTSFILEPATHNAME" ]; then  # FingerprintFile is available
    ENTRY_COUNT=$(wc -l < "$KNOWNSCRIPTSFILEPATHNAME")
    logInfo 6 "Fingerprint file '$KNOWNSCRIPTSFILEPATHNAME' has $ENTRY_COUNT lines"
  else
    logInfo 8 "No fingerprint file '$KNOWNSCRIPTSFILEPATHNAME' available yet"
  fi

  # Calculate the hash of the scriptfile on USB disk:
  FINGERPRINT=$(/bin/sha256sum "$scriptFullPathName" | /bin/awk '{print $1}')
  logInfo 5 "Fingerprint of '$scriptFullPathName' is $FINGERPRINT"

  scriptDateLastChange=$(date -r "$scriptFullPathName" '+%Y-%m-%d %H:%M:%S')
  bExec=0 # preset: don't execute the script
  if [[ "$ADD_NEW_FINGERPRINTS" -eq "0" ]]; then
    bExec=1 # execute any script matching the configured name
  fi

  # Is the fingerprint of the actual script file already registered?
  line=""
  if [ -f "$KNOWNSCRIPTSFILEPATHNAME" ]; then  # FingerprintFile is available
    # check whether the hash of the actual script on USB is already registerd
    line=$(/bin/grep "$FINGERPRINT" "$KNOWNSCRIPTSFILEPATHNAME")
    logInfo 6 "Matching Fingerprint line: '$line'"
    line=${line%%#*} # remove comments
    line=${line%% } # trim
    logInfo 8 "Fingerprint line, comment removed: '$line'"
  fi

  logInfo 8 "Setting ADD_NEW_FINGERPRINTS is '$ADD_NEW_FINGERPRINTS'"
  if [[ "$ADD_NEW_FINGERPRINTS" -eq 1 ]]; then
    if [[ "$ENTRY_COUNT" -eq 0 ]]; then
      # no old fingerprints: Create file and add the new one including some details as comment ...
      if [[ "$scriptExternal" -eq "1" ]]; then
        /bin/echo "$FINGERPRINT # $(date "$DTFMT") added from $diskName for $SCRIPT ($scriptDateLastChange)" > "$KNOWNSCRIPTSFILEPATHNAME"
      else
        /bin/echo "$FINGERPRINT # $(date "$DTFMT") added for $scriptFullPathName ($scriptDateLastChange)" > "$KNOWNSCRIPTSFILEPATHNAME"
      fi
      /bin/chmod 644 "$KNOWNSCRIPTSFILEPATHNAME"
      /bin/chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "$KNOWNSCRIPTSFILEPATHNAME"  # allow postuninst and postinst to delete the file
      if [ -f "$KNOWNSCRIPTSFILEPATHNAME" ]; then
        logInfo 4 "New fingerprint of '$scriptFullPathName' registered"
        if [[ "$scriptExternal" -eq "1" ]]; then
          /bin/echo "$(date "$DTFMT"): The fingerprint of the script '$SCRIPT' ($scriptDateLastChange) on '$diskName', mounted as $MOUNTPATH was now registered as allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
        else
          /bin/echo "$(date "$DTFMT"): The fingerprint of the script '$scriptFullPathName' ($scriptDateLastChange) was now registered as allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
        fi
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg3" "$SCRIPT" "$scriptDateLastChange"
        fi
      else
        logInfo 1 "Failed to register fingerprint of '$scriptFullPathName' in '$KNOWNSCRIPTSFILEPATHNAME'"
      fi
      bExec=1
    elif [[ "$line" != "" ]]; then # this is the already registered skript
      bExec=1
      logInfo 6 "Setting ADD_NEW_FINGERPRINTS is 1 and the registered fingerprint '$line' matches the script file: will be executed!"
    fi
  fi # if [[ "$ADD_NEW_FINGERPRINTS" -eq 1 ]]

  if [[ "$ADD_NEW_FINGERPRINTS" -eq "2" ]]; then
    bExec=1 # execute any script matching the configured name and add the fingerprint if not already available
    if [[ "$line" == "" ]]; then
      logInfo 3 "New fingerprint of '$scriptFullPathName' registered"
      if [[ "$scriptExternal" -eq "1" ]]; then
        /bin/echo "$FINGERPRINT # $(date "$DTFMT") added from $diskName for $SCRIPT ($scriptDateLastChange)" >> "$KNOWNSCRIPTSFILEPATHNAME"
        /bin/echo "$(date "$DTFMT"): The fingerprint of the script '$SCRIPT' on '$diskName' ($scriptDateLastChange), mounted as $MOUNTPATH was now registered as additionally allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
      else
        /bin/echo "$FINGERPRINT # $(date "$DTFMT") added for $scriptFullPathName ($scriptDateLastChange)" >> "$KNOWNSCRIPTSFILEPATHNAME"
        /bin/echo "$(date "$DTFMT"): The fingerprint of the script '$scriptFullPathName' ($scriptDateLastChange) was now registered as additionally allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
      fi
      if [[ "$ENTRY_COUNT" -eq 0 ]]; then # file was just created with owner root:root
        /bin/chmod 644 "$KNOWNSCRIPTSFILEPATHNAME"
        /bin/chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "$KNOWNSCRIPTSFILEPATHNAME"  # allow postuninst and postinst to delete the file
      fi
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg3" "$scriptFullPathName" "$scriptDateLastChange"
      fi
    fi
  elif [[ "$ADD_NEW_FINGERPRINTS" -eq "3" ]]; then
    # allow only previously registerd fingerprints
    if [[ "$line" != "" ]]; then
      logInfo 4 "Fingerprint of '$scriptFullPathName' already known"
      bExec=1
    fi
  fi

  bError=0
  if [[ "$bExec" == "1" ]];then
    # checkCoding needs the 'file' command, which is e.g. in "SynoCli File Tools":
    rFile=$(/bin/which "file")
    if [[ -z "$rFile" ]]; then
      logInfo 3 "Linux command 'file' is not available. Checking source files for correct line terminator and UTF-8-coding skipped! The 'file' command is part of the package 'SynoCli File Tools'! You may install that from https://packages.synocommunity.com/"
    else
      res=$($rFile -b "$scriptFullPathName")
      ret=$?
      logInfo 5 "File coding check '$scriptFullPathName' result $ret: $res"
      if [[ $res == *"CRLF line terminators"* ]]; then # Windows Format
        bExec=0 # don't try to execute the script
        logInfo 1 "######## Windows line terminator need to be converted to Unix! #########"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg14" "$scriptFullPathName"
        fi
        /bin/echo "$(date "$DTFMT"): Error: The Skript '$scriptFullPathName', which should be executed, uses the wrong line break CR/LF (Windows). Please use a siutable Editor (Linux oder Windows Notepad++, PSPad, ...) to change it to LF (UNIX)!" >> "$SCRIPT_EXEC_LOG"
        bError=1
      elif [[ $res == *"CR line terminators"* ]]; then # MAC format
        bExec=0 # don't try to execute the script
        logInfo 1 "######## MAC line terminator need to be converted to Unix! #########"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg16" "$scriptFullPathName"
        fi
        /bin/echo "$(date "$DTFMT"): Error: The Skript '$scriptFullPathName', which should be executed, uses the wrong line break CR (MAC). Please use a siutable Editor to change it to LF (UNIX)!" >> "$SCRIPT_EXEC_LOG"
        bError=1
      elif [[ "$res" == *"ISO-8859 text"* ]]; then
        bExec=0 # don't try to execute the script
        logInfo 1 "File coding check '$scriptFullPathName' result $ret: $res"
        logInfo 1 "######## Please convert to UTF-8! ##########"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg15" "$scriptFullPathName"
        fi
        /bin/echo "$(date "$DTFMT"): Error: The Skript '$scriptFullPathName', which should be executed, uses the wrong coding (Windows ISO-8859). Please use a siutable Editor (Linux oder Windows Notepad++, PSPad, ...) to change it to UTF-8!" >> "$SCRIPT_EXEC_LOG"
        bError=1
      fi
    fi # if [[ -z "$res" ]] else
  fi # if [[ "$bExec" == "1" ]]
  if [[ "$bExec" == "1" ]]; then
    # execute the script, $1 = mount path
    executeConfiguredScript "$1"
  else
    if [[ "$bError" == "0" ]]; then # not yet error message done
      if [[ "$scriptExternal" -eq "1" ]]; then
        /bin/echo "$(date "$DTFMT"): The script '$SCRIPT' ($scriptDateLastChange) on '$diskName' with fingerprint $FINGERPRINT, mounted as $MOUNTPATH does not match registered fingerprints" >> "$SCRIPT_EXEC_LOG"
        logInfo 2 "This skript '$SCRIPT' ($scriptDateLastChange) on '$diskName' with fingerprint $FINGERPRINT with it's fingerprint is not permitted to run. No autorun!"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg4" "$SYNOPKG_PKGNAME" "$SCRIPT" "$scriptDateLastChange"
        fi
      else
        /bin/echo "$(date "$DTFMT"): The script '$scriptFullPathName' ($scriptDateLastChange) with fingerprint $FINGERPRINT does not match registered fingerprints" >> "$SCRIPT_EXEC_LOG"
        logInfo 2 "This skript '$scriptFullPathName' ($scriptDateLastChange) with fingerprint $FINGERPRINT with it's fingerprint is not permitted to run. No autorun!"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg4" "$SYNOPKG_PKGNAME" "$scriptFullPathName" "$scriptDateLastChange"
        fi
      fi
      if [[ FINGERPRINTS_INCL_DRIVE -eq 1 ]]; then
        logInfo 2 "This skript on '$diskName' ($scriptDateLastChange) with fingerprint $FINGERPRINT is not permitted to run from $scriptFullPathName. No autorun!"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg5" "$SYNOPKG_PKGNAME" "$scriptFullPathName" "$MOUNTPATH"
        fi
      fi
    fi
    bError=1
  fi # if [[ "$bExec" == "1" ]]

  if [ "$BEEP" == "true" ];then
    if [ "$bError" == 1 ];then
      beepError
    else
      beep BEEP_SHORT  # short beep
    fi
  fi
  if [ "$LED" == 1 ];then
    if [ "$bError" == 1 ];then
      beep LED_STATUS_ORANGE_FLASH
    else
      beep LED_STATUS_GREEN
    fi
  fi
else # no executable script
  if [ -f "$scriptFullPathName" ];then
    if [[ "$scriptExternal" -eq "1" ]]; then
      logInfo 1 "The script file '$SCRIPT' on $1 is not executable. Exiting from $SYNOPKG_PKGNAME now."
      /bin/echo "$(date "$DTFMT"): The script '$SCRIPT' on '$diskName', mounted as $MOUNTPATH is not executable" >> "$SCRIPT_EXEC_LOG"
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg6" "$SCRIPT"
      fi
    else
      logInfo 1 "The script file '$scriptFullPathName' is not executable. Exiting from $SYNOPKG_PKGNAME now."
      /bin/echo "$(date "$DTFMT"): The script '$scriptFullPathName' is not executable" >> "$SCRIPT_EXEC_LOG"
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg6" "$scriptFullPathName"
      fi
    fi
  else
    if [[ "$scriptExternal" -eq "1" ]]; then
      logInfo 3 "On the device '$1' there is no file '$SCRIPT'. Exiting from $SYNOPKG_PKGNAME now."
      # /bin/echo "$(date "$DTFMT"): There is no script '$SCRIPT' on '$diskName', mounted as $MOUNTPATH" >> "$SCRIPT_EXEC_LOG"
    else
      logInfo 1 "The script file '$scriptFullPathName' is missing. Exiting from $SYNOPKG_PKGNAME now."
      /bin/echo "$(date "$DTFMT"): The script file '$scriptFullPathName' is missing" >> "$SCRIPT_EXEC_LOG"
    fi
  fi
fi # script available on USB disk
exit 0
