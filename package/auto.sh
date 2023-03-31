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


# replaceLastLogLineIfSimilar():
# if the last line in "$SCRIPT_EXEC_LOG" contains $1, then replace that line by $2, else append $2
# This is to reduce the number of entries in $SCRIPT_EXEC_LOG
# If 3 parameters given: Replace only, if $1 is in the last line but $3 is not in the last line
# That is to avoid e.g.
#   "Re-Installation (change of settings) of V1.10.0-0011 done, Package 'autorun' was STARTED! Package 'autorun' was STARTED! Package 'autorun' was STARTED!"
replaceLastLogLineIfSimilar() {
  latestEntry="$(/bin/tail -1 "$SCRIPT_EXEC_LOG")"
  replace=0
  if [[ "$latestEntry" == *"$1"* ]]; then
    replace=1
    if [[ "$#" -gt 2 ]]; then
      echo "more than 2 params"
      if [[ "$latestEntry" == *"$3"* ]]; then
        replace=0
      fi
    fi
  fi
  if [[ "$replace" -eq "1" ]]; then
    lineCount=$(/bin/wc -l < "$SCRIPT_EXEC_LOG")
    /bin/sed -i -e "$lineCount,\$d" "$SCRIPT_EXEC_LOG" # remove last line
    /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "$2" >> "$SCRIPT_EXEC_LOG"
    logInfo 8 "Last Entry in SCRIPT_EXEC_LOG was '$latestEntry' and has been replaced now by '$2'"
  else
    /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "$2" >> "$SCRIPT_EXEC_LOG"
    logInfo 8 "Item '$1' not found in SCRIPT_EXEC_LOG last line: '$latestEntry', additional entry generated:'$2'"
  fi # if [[ "$latestEntry" == *"$diskName"* ]]
}


# Convert integer range (e.g. "90;93-96;99") to individual values (e.g. 90;93;94;95;96;99)
# Result put to referenced variable
# Attention: Call with Name, not value, e.g. "expandRange noMsgRetCodes" instead of "expandRange $noMsgRetCodes"
expandRange() {
  local -n ref=$1
  m=0; # make sure not to get an endless loop
  while [[ "$ref" == *"-"* ]] && [[ "$m" -lt "201" ]]; do # expand to numbers
    m=$((m+1))
    # echo "Loop $m"
    before1="${ref%%-*}"
    after1="${ref#*-}"
    if [[ "$before1" == *";"* ]]; then # not 1st element
      before2="${before1##*;}"
    else
      before2="${before1}"
    fi
    if [[ "$after1" == *";"* ]]; then # not 1st element
      # echo "  after1 with ;"
      after2="${after1%%;*}"
    else
      after2="${after1}"
    fi
    # echo "  before1='$before1', before2='$before2', after1='$after1', after2='$after2'"
    # after2="$((after2-2))"
    for (( i=$((before2+1)); i<after2; i++ )); do
      before1="$before1;$i"
    done
    ref="$before1;$after1"
    # echo "ref='$ref'"
  done
  }


executeConfiguredScript(){
  # $1 is e.g. 'usb1p1'
  # run it:
  logInfo 3 "starting now '$scriptFullPathName' ..."
  dateStart_s=$(/bin/date +"%s")
  dateStart_string=$(/bin/date "$DTFMT")
  if [[ "$SCRIPT" == *"/"* ]]; then
    /bin/printf "%s\t%s\n" "$(/bin/date "$DTFMT")" "The disk '$diskName' was mounted as $MOUNTPATH and the script '$scriptFullPathName' was started and is running ..." >> "$SCRIPT_EXEC_LOG"
  else
    /bin/printf "%s\t%s\n" "$(/bin/date "$DTFMT")" "The script '$scriptFullPathName' on '$diskName', mounted as $MOUNTPATH, was started and is running ..." >> "$SCRIPT_EXEC_LOG"
  fi
  if (((LED & 1)!=0)); then  # 1 or 3
    beep LED_STATUS_GREEN
  elif (((LED & 2)!=0)); then # 2
    beep LED_STATUS_GREEN_FLASH
  fi
  if [[ "$LED_COPY" -eq "1" ]] || [[ "$LED_COPY" -eq "3" ]]; then
    beep LED_COPY_ON
  elif [[ "$LED_COPY" -ne "0" ]]; then # 2 or 4 or 5
    beep LED_COPY_FLASH
  fi
  # https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
  if [[ $- == *i* ]]; then # interactive shell, [[ -n "$PS1" ]] would also be possible
    # with immediate output to tty and also to variable out:
    out="$(/bin/sh "$scriptFullPathName" "$MOUNTPATH" "$1" 2>&1 | tee /dev/tty; res1=${PIPESTATUS[0]}; exit "$res1")"
    scriptResultCode=$?
  else
    out="$(/bin/sh "$scriptFullPathName" "$MOUNTPATH" "$1" 2>&1)"
    scriptResultCode=$?
  fi
  lastScriptMsg=$(/bin/tail -n 1 <<< "$out") # get the last line from the executed script output
  if [[ "$CAPTURE" == "1" ]];then # inserted to autorun main log
    printf '%s\n' "$out" | /bin/tee -a "$SCRIPT_EXEC_LOG"
  elif [[ "$CAPTURE" == "2" ]];then # inserted to debug log
    printf '%s\n' "$out" | /bin/tee -a "$LOG"
  fi
  if [[ ";$failureCodes;" == *";$scriptResultCode;"* ]]; then
    highlightStart="<span style=\"color:Red;\">"
    highlightEnd="</span>"
    lastMsgColorStart="<span style=\"color:Red;\">"
  else
    highlightStart=""
    highlightEnd=""
    lastMsgColorStart="<span style=\"color:Green;\">"
  fi
  logInfo 6 "Back in $scriptThisFullPhysicalPathName from $scriptFullPathName with ${highlightStart}result=$scriptResultCode${highlightEnd} and last msg line ${highlightStart}'$lastScriptMsg'${highlightEnd}"
  dateFinished_s=$(/bin/date +"%s")

  if [[ "$LED" == "1" ]]; then
    beep LED_STATUS_GREEN_FLASH
  fi
  if (((LED_COPY & 7)!=0)); then
    beep LED_COPY_OFF # Copy LED off
    if [[ ";$failureCodes;" == *";$scriptResultCode;"* ]]; then
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
  # get the free space
  FREE=$(/bin/df -h "$MOUNTPATH" | /bin/grep "$MOUNTPATH" | /bin/awk '{ print $4 }')  # e.g. "2.1T"
  ejected=0 # 0: no eject, 1: ejecting, 2: eject success, 3: eject fail
  noMsgRetCodes="$NO_DSM_MESSAGE_RETURN_CODES" # e.g. "90;93-96;99"
  expandRange noMsgRetCodes # Attention: Function call with parameter variable transfer by name 'noMsgRetCodes', not by value '$noMsgRetCodes'! (bash 4.3ff)
  ejectReturnCodes="$EJECT_RETURN_CODES"
  expandRange ejectReturnCodes # Attention: Function call with parameter variable transfer by name, not by value! (bash 4.3ff)
  failureCodes="$FAILURE_CODES" # e.g. '1-5;250-255'
  expandRange failureCodes # now e.g. '1;2;3;4;5;250;251;252;253;254;255'

  # unmount when the result is in the list of the configured EJECT_RETURN_CODES
  if [[ ";$ejectReturnCodes;" == *";$scriptResultCode;"* ]];then
    # with the lsof command it's possible to get all open files, but as default it's not available on DSM 7.1
    # lsof is part of "SynoCli Tools" and of "synogear"
    # fuser is also only part of "SynoCli Tools"
    /bin/echo "Script result code $scriptResultCode detected in $EJECT_RETURN_CODES"
    if [ "$LED" -eq "1" ];then
      beep LED_STATUS_GREEN_FLASH
    fi
    # no change of LED_COPY from running script to ejecting!
    logInfo 2 "device '$1' - script '$scriptFullPathName' finished with $scriptResultCode ($FREE left on device), starting unmount"
    d1=$(/bin/echo "$1" | /bin/sed -e 's:/dev/::' -e 's:p.*::') # # $1 is e.g. 'usb1p1' or '/dev/usb1p1', d1 is now e.g. 'usb1'
    info=$(/usr/syno/bin/synousbdisk -info "$d1")
    sn=$(/bin/echo "$info" | /bin/grep "Share Name:") # catch line with the share name
    sn=${sn#*:} # remove the label
    sn=$(/bin/echo "$sn") # remove blanks, so we get e.g. usbshare4
    ejected=1  #1: ejecting, 2: eject success, 3: eject fail
    endTime=$(($(/bin/date +%s) + EJECT_TIMEOUT))
    k=$TRIES # $TRIES is from the config file
    while [[ $(/bin/date +%s) -le $endTime ]]; do # loop with counter as the external drive may be in use ...
      # try to do the unmount
      logInfo 8 "till eject timeout left $(( endTime - $(date +%s) ))s"
      /bin/sleep 3
      res1="$( { /bin/sync; } 2>&1 )"
      ret1=$?
      if [[ -n "$res1" ]]; then # the default is an empty string
        res1=" ($res1)"
      fi
      /bin/sleep 6
      res2="$( { /usr/syno/bin/synousbdisk -rcclean; } 2>&1 )"
      ret2=$?
      /bin/sleep 6
      # /bin/umount $MOUNTPATH
      res3=$( { /usr/syno/bin/synousbdisk -umount "$d1"; } 2>&1 ) # $d1 e.g. usb1
      ret3=$?
      msgR="Loop $((TRIES - k )) of $TRIES results: 'sync'=$ret1$res1; 'synousbdisk -rcclean'=$ret2($res2); 'synousbdisk -umount $d1'=$ret3($res3)"
      if [ $ret3 -eq 0 ];then # success
        # 2nd Part of umount (neccessary?)
        res4=$( { /usr/syno/bin/synousbdisk -umount "$sn"; } 2>&1 ) # e.g. usbshare4
        ret4=$?
        msgR="${msgR}; 'synousbdisk -umount $sn'=$ret4($res4)"
      fi
      /bin/sleep 45
      logInfo 7 "$msgR"
      # check whether now realy no more mounted:
      resultm=$(/bin/mount 2>&1 | /bin/grep "/dev/$1" | /bin/cut -d ' ' -f3)
      if [[ -z "$resultm" ]] && [[ "$ret3" -eq "0" ]] && [[ "$ret4" -eq "0" ]]; then # synousbdisk -umount was really successfull
        # would a "synousbdisk -rmtabentry DEVNAME" do that also ???
        ejected=2 # 0: no eject, 1: ejecting, 2: eject success, 3: eject fail
        # Remove it now from the 'gui' list:
        /bin/cp /tmp/usbtab /tmp/usbtab.old
        /bin/grep -v "$d1" /tmp/usbtab.old > /tmp/usbtab  # copy all non-matching lines
        lineCountOld=$(/bin/wc -l < "/tmp/usbtab.old")
        /bin/rm -f /tmp/usbtab.old
        lineCountNew=$(/bin/wc -l < "/tmp/usbtab")
        # unbind ??? # Optional !!!????
        logInfo 3 "device '$1' successfully unmounted and removed from GUI ($(( lineCountOld - lineCountNew )) line removed from file /tmp/usbtab)!"
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
    detailLink=" <a href='/usr/syno/synoman/webman/3rdparty/$SYNOPKG_PKGNAME/index.cgi'> details </a> " # is the token needed?
    if [[ $ejected -eq 1 ]]; then # above a loop timeout occured
      /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script '$scriptFullPathName' for '$diskName', mounted as $MOUNTPATH, was finished after $execTime with return code $scriptResultCode. <span style=\"color:Red;\">Attention: The requested ejection of the device failed!!</span>" >> "$SCRIPT_EXEC_LOG"
      ejected=3 # failed
    fi
    # logInfo 4 "Eject part finisched with $ejected. (2: eject success, 3: eject fail) "
    if [[ -n "$SCRIPT_AFTER_EJECT" ]]; then
      if [ -x "$SCRIPT_AFTER_EJECT" ]; then
        if [[ "$ejected" -eq "2" ]]; then
          logInfo 5 "Script '$SCRIPT_AFTER_EJECT' will be started with parameters '$MOUNTPATH' and '$1' !"
          # https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
          if [[ $- == *i* ]]; then # interactive shell, [[ -n "$PS1" ]] would also be possible
            # with immediate output to tty and also to variable out:
            outAfter="$(/bin/bash "$SCRIPT_AFTER_EJECT" "$MOUNTPATH" "$1" 2>&1 | tee /dev/tty; res1=${PIPESTATUS[0]}; exit "$res1")"
            resAfter=$?
          else
            outAfter="$(/bin/bash "$SCRIPT_AFTER_EJECT" "$MOUNTPATH" "$1" 2>&1)" # e.g. "/volumeUSB1/usbshare" and "usb2p1"
            resAfter=$?
          fi
          logInfo 6 "$SCRIPT_AFTER_EJECT done with $resAfter ($outAfter). CAPTURE='$CAPTURE'"
          if [[ "$CAPTURE" == "1" ]];then # inserted to autorun main log
            printf '%s\n' "$outAfter" | /bin/tee -a "$SCRIPT_EXEC_LOG"
          elif [[ "$CAPTURE" == "2" ]];then # inserted to debug log
            printf '%s\n' "$outAfter" | /bin/tee -a "$LOG"
          fi

          if [[ ";$failureCodes;" == *";$resAfter;"* ]]; then
            highlightAfterStart="<span style=\"color:Red;\">"
            highlightAfterEnd="</span>"
            lastMsgAfterColorStart="<span style=\"color:Red;\">"
          else
            highlightAfterStart=""
            highlightAfterEnd=""
            lastMsgAfterColorStart="<span style=\"color:Green;\">"
          fi
          replaceLastLogLineIfSimilar "mounted as $MOUNTPATH" "The script '$scriptFullPathName' for '$diskName', mounted as $MOUNTPATH, was started $dateStart_string and finished after $execTime with ${highlightStart}return code ${scriptResultCode}${highlightEnd} and the last message: ${lastMsgColorStart}$lastScriptMsg</span>. Device successfully ejected and the script '$SCRIPT_AFTER_EJECT' done with ${highlightAfterStart}return code ${resAfter}${highlightAfterEnd}: ${lastMsgAfterColorStart}${outAfter}</span>. ${FREE}Bytes free on the external storage."
        else
          # if $ejected != 2
          logInfo 3 "Script '$SCRIPT_AFTER_EJECT' will be started with 'Ejection failed'!"
          # https://serverfault.com/questions/146745/how-can-i-check-in-bash-if-a-shell-is-running-in-interactive-mode
          if [[ $- == *i* ]]; then # interactive shell, [[ -n "$PS1" ]] would also be possible
            # with immediate output to tty and also to variable outAfter:
            outAfter="$(/bin/sh "$SCRIPT_AFTER_EJECT" "Ejection failed" "$MOUNTPATH" "$1" 2>&1 | tee /dev/tty; res1=${PIPESTATUS[0]}; exit "$res1")"
            resAfter=$?
          else
            outAfter="$(/bin/sh "$SCRIPT_AFTER_EJECT" "Ejection failed" "$MOUNTPATH" "$1" 2>&1)"
            resAfter=$?
          fi
          /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script '$scriptFullPathName' ${txtOnFor} '$diskName', mounted as $MOUNTPATH, was finished after $execTime with ${highlightStart}return code ${scriptResultCode}${highlightEnd}. <span style=\"color:Red;\">Device ejecting was failing.</span> The script '$SCRIPT_AFTER_EJECT' with parameter 'Ejection failed' and ${highlightAfterStart}result=${resAfter}${highlightEnd} was done." >> "$SCRIPT_EXEC_LOG"
        fi # if [[ "$ejected" -eq "2" ]] else
      else
        logError "The script '$SCRIPT_AFTER_EJECT' is not executable for actual user"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg10" "$SYNOPKG_PKGNAME" "$scriptFullPathName" "$SCRIPT_AFTER_EJECT" "$detailLink"
                                        # $dsmappname is setup in INFO file, e.g. "SYNO.SDS._ThirdParty.App.autorun"
        fi
      fi # if [ -x "$SCRIPT_AFTER_EJECT" ] else
    else
      logInfo 6 "No SCRIPT_AFTER_EJECT specified"
      resAfter="9999"
      replaceLastLogLineIfSimilar "mounted as $MOUNTPATH" "The script '$scriptFullPathName' for '$diskName', mounted as $MOUNTPATH, was started $dateStart_string and finished after $execTime with ${highlightStart}return code ${scriptResultCode}${highlightEnd} (${lastMsgColorStart}${lastScriptMsg}</span>). ${FREE}Bytes free on the external storage."
    fi # if [[ -n "$SCRIPT_AFTER_EJECT" ]] else

    if [[ $ejected -eq 3 ]]; then
      # Ejection of device failed!
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg7" "$scriptFullPathName" "$MOUNTPATH" "$scriptResultCode" "$detailLink"
      fi
      /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "Ejection of '$diskName', mounted as $MOUNTPATH failed!" >> "$SCRIPT_EXEC_LOG"
    else
      if [[ -n "$NOTIFY_USERS" ]] && [[ ";$noMsgRetCodes;" != *";$scriptResultCode;"* ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg8" "$scriptFullPathName" "$MOUNTPATH" "$scriptResultCode" "$detailLink" "$FREE"
      fi
    fi
  else # script result not in $EJECT_RETURN_CODES
    replaceLastLogLineIfSimilar "mounted as $MOUNTPATH" "The script '$scriptFullPathName' ${txtOnFor} '$diskName', mounted as $MOUNTPATH, was started $dateStart_string and finished after $execTime with return code $scriptResultCode. ${FREE}Bytes free."
    /bin/echo "Script result code $scriptResultCode is not in '$EJECT_RETURN_CODES'"
    logInfo 5 "device '$1' - script '$scriptFullPathName' finished with $scriptResultCode ($lastScriptMsg) ($FREE left on device), no unmount requested"
    if [[ -n "$NOTIFY_USERS" ]] && [[ ";$noMsgRetCodes;" != *";$scriptResultCode;"* ]]; then
      /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg9" "$scriptFullPathName" "$MOUNTPATH" "$scriptResultCode" "$detailLink" "$FREE"
    fi
  fi # if [ "$scriptResultCode" in $EJECT_RETURN_CODES ] else

# return codes: $scriptResultCode, $ejected (0: no ejection, 2: eject success, 3: eject fail) and
  if [[ "$LED_COPY" -eq "1" ]] || [[ "$LED_COPY" -eq "2" ]]; then
    beep LED_COPY_OFF # independent from failures
  fi
  if [[ "$ejected" -eq "3" ]] || [[ ";$failureCodes;" == *";$scriptResultCode;"* ]] || [[ ";$failureCodes;" == *";$resAfter;"* ]];then # failure
    if [[ "$LED_COPY" -eq "3" ]] || [[ "$LED_COPY" -eq "4" ]]; then
      beep LED_COPY_FLASH # independent from failures
    elif [[ "$LED_COPY" -eq "5" ]]; then
      beep LED_COPY_ON
    fi
    if [[ "$LED" -ge "1" ]] && [[ "$LED" -le "3" ]]; then
      beep LED_STATUS_ORANGE_FLASH
    fi
  else # no failure
    if [[ "$LED_COPY" -ge "1" ]]; then
      beep LED_COPY_OFF
    fi
    if [[ "$LED" -eq "1" ]] || [[ "$LED" -eq "3" ]]; then
      beep LED_STATUS_OFF
    elif [[ "$LED" -eq "2" ]]; then
      beep LED_STATUS_GREEN
    fi
  fi
} # executeConfiguredScript()


########################################### start point #####################
# environment PATH is empty when started via event!!!

SCRIPTPATHauto="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )" # e.g. /volumeX/@appstore/<app>
# https://stackoverflow.com/questions/421772/how-can-a-bash-script-know-the-directory-it-is-installed-in-when-it-is-sourced-w
baseNameThis="$(basename "${BASH_SOURCE[0]}")"
scriptThisFullPhysicalPathName=$SCRIPTPATHauto/$baseNameThis # with physical path
if [[ -z "$SYNOPKG_PKGNAME" ]]; then
  SYNOPKG_PKGNAME=${SCRIPTPATHauto##*/}
  myMsg="SYNOPKG_PKGNAME='$SYNOPKG_PKGNAME' extracted from SCRIPTPATHauto"
else
  myMsg="SYNOPKG_PKGNAME='$SYNOPKG_PKGNAME' was available"
fi
# shellcheck source=..\WIZARD_UIFILES\initial_config.txt
source "/var/packages/$SYNOPKG_PKGNAME/var/config" # import our config

# import helper functions logInfo(), beepError() and beep() (also used for LED control):
if [[ ! -x "/var/packages/$SYNOPKG_PKGNAME/target/common" ]]; then
  /bin/echo "###########################################################################"
  /bin/echo "Error: File '/var/packages/$SYNOPKG_PKGNAME/target/common' not available or not executable!" | tail -a "/var/log/packages/$SYNOPKG_PKGNAME.log"
  /bin/echo "###########################################################################"
  exit 11
fi
# shellcheck source=common
source "/var/packages/$SYNOPKG_PKGNAME/target/common" "$SYNOPKG_PKGNAME" # lngUser, lngMail (for Logfile) set, $APPDATA/config read
# shellcheck source=../WIZARD_UIFILES/log_hlp.sh
source "/var/packages/$SYNOPKG_PKGNAME/WIZARD_UIFILES/log_hlp.sh" "$SYNOPKG_PKGNAME" # logInfo, logError
/bin/echo -e "" >> "$LOG" # empty row
user=$(whoami) # EnvVar $USER may be not well set
versShell="$($SHELL --version | sed -n '1p')"
logInfo 3 "Start of ${BASH_SOURCE[0]} as user '$user' with SHELL='$SHELL' ($versShell) ..."
logInfo 6 "$myMsg"
if [ -z "$1" ]; then
  /bin/echo "incorrect '\$1' - aborting ..."
  logError "Error: Parameter 1 missing in ${BASH_SOURCE[0]}"
  beepError
  exit 12
fi

MOUNTPATH="" # external Disk
scriptFullPathName="" # internal $SCRIPT or $MOUNTPATH/$SCRIPT
dsmappname="" # preset to avoid shellcheck warnings
eval "$(grep "dsmappname=" "/var/packages/$SYNOPKG_PKGNAME/INFO")"
logInfo 6 "The 'dsmappname', the class for synodsmnotify is '$dsmappname'"
# dsmappname needs to match the .url in ui/config. Otherwise synodsmnotify will not work
# used as CLASS in synodsmnotify

SCRIPT_EXEC_LOG="$APPDATA/execLog" # logfile with 1 ..2 lines per executed script
for f1 in "$LOG" "$SCRIPT_EXEC_LOG"; do
  # if the file $1 has more than $2 lines: Delete the 1st $2/2 lines
  logfileTrim "$f1" "$LOG_MAX_LINES" # logfileTrim() is in file common
done

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
  logError "device '$1' - unable to find with the 'mount' command the mount point '/dev/$1' within $COUNT seconds, aborting with exit code 13"
  beepError
  exit 13
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

# is there the script according to SCRIPT="..." in the config file on/for our DSM or external drive?
if [[ "$SCRIPT" == *"/"* ]]; then
  scriptFullPathName="$SCRIPT"  # script on DSM, not at external storage
  scriptExternal=0
  txtOnFor="on" # for messages: <script> on <disk>
  # check for file with other upper/lower case already done in start-stop-status
else
  scriptFullPathName="$MOUNTPATH/$SCRIPT" # script on external storage
  scriptExternal=1
  txtOnFor="for" # for messages: <script> for <disk>
fi
if [[ ! -f "$scriptFullPathName" ]]; then
  res="$(/bin/find -L "$(dirname "$scriptFullPathName")" -maxdepth 1 -iname "$(basename "$scriptFullPathName")" -type f)" # -L Follow symbolic links
  if [[ -n "$res" ]]; then
    logInfo 1 "device '$1' - script '$res' found, but it's different in upper/lower case and will not ignored!"
    /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "Suspicous: There is a script '$res', but it's name is different in upper/lower case and therefore will be ignored!" >> "$SCRIPT_EXEC_LOG"
  fi

  if [[ "$scriptExternal" -eq "0" ]]; then # Error!
    logError "Could not find the script file '$scriptFullPathName'"
    /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "Error 14: The configured script file '$scriptFullPathName' to run at storage drive connection is not avaliable!" >> "$SCRIPT_EXEC_LOG"
    exit 14
  else # ignore this storage drive
    logInfo 2 "On the storage device '$diskName', which is mounted as '$MOUNTPATH', is no script file '$SCRIPT'. So no autorun action taken!"
    exit 0
  fi
fi
if [ -x "$scriptFullPathName" ];then
  logInfo 5 "device '$1' - executable script '$scriptFullPathName' found"
elif [[ -f "$scriptFullPathName" ]]; then
  logError "device '$1' - script '$scriptFullPathName' found, but not executable!"
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

  # Calculate the hash of the scriptfile on or for USB/SATA disk:
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
    # check whether the hash of the actual script on/for USB is already registerd
    line0=$(/bin/grep "$FINGERPRINT" "$KNOWNSCRIPTSFILEPATHNAME")
    logInfo 6 "Matching Fingerprint line: '$line0'"
    line=${line0%%#*} # remove comments
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
          /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The fingerprint of the script '$SCRIPT' ($scriptDateLastChange) on '$diskName', mounted as $MOUNTPATH was now registered as allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
        else
          /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The fingerprint of the script '$scriptFullPathName' ($scriptDateLastChange) was now registered as allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
        fi
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg3" "$SCRIPT" "$scriptDateLastChange"
        fi
      else
        logError "Failed to register fingerprint of '$scriptFullPathName' in '$KNOWNSCRIPTSFILEPATHNAME'"
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
      if [[ "$scriptExternal" -eq "1" ]]; then
        /bin/echo "$FINGERPRINT # $(date "$DTFMT") added from $diskName for $SCRIPT ($scriptDateLastChange)" >> "$KNOWNSCRIPTSFILEPATHNAME"
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The fingerprint of the script '$SCRIPT' ${txtOnFor} '$diskName' ($scriptDateLastChange), mounted as $MOUNTPATH was now registered as additionally allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
      else
        /bin/echo "$FINGERPRINT # $(date "$DTFMT") added for $scriptFullPathName ($scriptDateLastChange)" >> "$KNOWNSCRIPTSFILEPATHNAME"
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The fingerprint of the script '$scriptFullPathName' ($scriptDateLastChange) was now registered as additionally allowed fingerprint." >> "$SCRIPT_EXEC_LOG"
      fi
      logInfo 3 "New fingerprint of '$scriptFullPathName' registered"
      if [[ "$ENTRY_COUNT" -eq 0 ]]; then # file was just created with owner root:root
        /bin/chmod 644 "$KNOWNSCRIPTSFILEPATHNAME"
        /bin/chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "$KNOWNSCRIPTSFILEPATHNAME"  # allow postuninst and postinst to delete the file
      fi
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg3" "$scriptFullPathName" "$scriptDateLastChange"
      fi
    else
      logInfo 7 "Fingerprint of '$scriptFullPathName' was already registered "
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
      res=$( { $rFile -b "$scriptFullPathName"; } 2>&1 )
      ret=$?
      logInfo 6 "File coding check '$scriptFullPathName' result $ret: $res"
      if [[ $res == *"CRLF line terminators"* ]]; then # Windows Format
        bExec=0 # don't try to execute the script
        logError "######## Windows line terminator need to be converted to Unix! #########"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg14" "$scriptFullPathName"
        fi
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "Error: The Skript '$scriptFullPathName', which should be executed, uses the wrong line break CR/LF (Windows). Please use a siutable Editor (Linux oder Windows Notepad++, PSPad, ...) to change it to LF (UNIX)!" >> "$SCRIPT_EXEC_LOG"
        bError=1
      elif [[ $res == *"CR line terminators"* ]]; then # MAC format
        bExec=0 # don't try to execute the script
        logError "######## MAC line terminator need to be converted to Unix! #########"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg16" "$scriptFullPathName"
        fi
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "Error: The Skript '$scriptFullPathName', which should be executed, uses the wrong line break CR (MAC). Please use a siutable Editor to change it to LF (UNIX)!" >> "$SCRIPT_EXEC_LOG"
        bError=1
      elif [[ "$res" == *"ISO-8859 text"* ]]; then
        bExec=0 # don't try to execute the script
        logInfo 1 "File coding check '$scriptFullPathName' result $ret: $res"
        logInfo 1 "######## Please convert to UTF-8! ##########"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg15" "$scriptFullPathName"
        fi
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "Error: The Skript '$scriptFullPathName', which should be executed, uses the wrong coding (Windows ISO-8859). Please use a siutable Editor (Linux oder Windows Notepad++, PSPad, ...) to change it to UTF-8!" >> "$SCRIPT_EXEC_LOG"
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
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script '$SCRIPT' ($scriptDateLastChange) ${txtOnFor} '$diskName' with fingerprint $FINGERPRINT, mounted as $MOUNTPATH does not match registered fingerprints" >> "$SCRIPT_EXEC_LOG"
        logInfo 2 "This skript '$SCRIPT' ($scriptDateLastChange) ${txtOnFor} '$diskName' with fingerprint $FINGERPRINT with it's fingerprint is not permitted to run. No autorun!"
        if [[ -n "$NOTIFY_USERS" ]]; then
          /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg4" "$SYNOPKG_PKGNAME" "$SCRIPT" "$scriptDateLastChange"
        fi
      else
        /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script '$scriptFullPathName' ($scriptDateLastChange) with fingerprint $FINGERPRINT does not match registered fingerprints" >> "$SCRIPT_EXEC_LOG"
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
      logInfo 1 "The script file '$SCRIPT' ${txtOnFor} $1 is not executable. Exiting from $SYNOPKG_PKGNAME now."
      /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script '$SCRIPT' on '$diskName', mounted as $MOUNTPATH is not executable" >> "$SCRIPT_EXEC_LOG"
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg6" "$SCRIPT"
      fi
    else
      logError "The script file '$scriptFullPathName' is not executable. Exiting from $SYNOPKG_PKGNAME now."
      /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script '$scriptFullPathName' is not executable" >> "$SCRIPT_EXEC_LOG"
      if [[ -n "$NOTIFY_USERS" ]]; then
        /usr/syno/bin/synodsmnotify -c "$dsmappname" "$NOTIFY_USERS" "$SYNOPKG_PKGNAME:app1:title01" "$SYNOPKG_PKGNAME:app1:msg6" "$scriptFullPathName"
      fi
    fi
  else
    if [[ "$scriptExternal" -eq "1" ]]; then
      logInfo 3 "On the device '$1' there is no file '$SCRIPT'. Exiting from $SYNOPKG_PKGNAME now."
      # /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "There is no script '$SCRIPT' ${txtOnFor} '$diskName', mounted as $MOUNTPATH" >> "$SCRIPT_EXEC_LOG"
    else
      logError "The script file '$scriptFullPathName' is missing. Exiting from $SYNOPKG_PKGNAME now."
      /bin/printf "%s\t%s\n" "$(date "$DTFMT")" "The script file '$scriptFullPathName' is missing" >> "$SCRIPT_EXEC_LOG"
    fi
  fi
fi # script available on USB disk
exit 0

