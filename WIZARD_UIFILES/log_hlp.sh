#!/bin/bash
# write an info entry to out log file
# included to scripts in folders WIZARD_UIFILES and scripts directly. 
# During the 1st start of start-stop-status script a link under /var/packages/$SYNOPKG_PKGNAME/target/ is generated for use in via the common file.
# Hint: In the *.cgi files this is not used, only logInfoNoEcho() (located in parse_hlp.sh) is used.

# Variante a:  $1 = log entry
# Variante b: $1= LogLevel, $2 log entry: Only if $1 is smaler or equal to the loglevel it will be reported
logInfo() {
  local ll=1 # log level defaultvalue
  if [[ "$1" =~ ^[0-9]+$ ]] && [[ $# -ge 2 ]]; then # Attention: No single or double quotes for regExp allowed!
    ll=$1 # 1st parameter is log level
    # /bin/echo "logInfo called with level $ll"
    shift
  fi
  # /bin/echo "logInfo with ll='$ll' and LOGLEVEL='$LOGLEVEL'"
  if [[ "$ll" -le  "$LOGLEVEL" ]]; then
    # /bin/echo "generating callerHistory now"
    local callerHistory
    callerHistory="$(basename "${BASH_SOURCE[1]}"):${BASH_LINENO[0]}"
    if [[ "$LOGLEVEL" -ge "5" ]]; then # full caller history only for high loglevel
      local i
      for (( i=2 ; i < "${#BASH_SOURCE[@]}"; i++ )); do
        callerHistory="$(basename "${BASH_SOURCE[$i]}"):${BASH_LINENO[$((i-1))]} -> $callerHistory"
        # https://stackoverflow.com/questions/192319/how-do-i-know-the-script-file-name-in-a-bash-script
      done
    fi
    if [[ $- == *i* ]]; then # interactive shell, [[ -n "$PS1" ]] would also be possible
      /bin/printf "%s\t%s\n" "$(date "$DTFMT") ${callerHistory}" "$*" | /bin/tee -a "$LOG"
    else
      /bin/printf "%s\t%s\n" "$(date "$DTFMT") ${callerHistory}" "$*" >> "$LOG"
    fi
  fi
}


# write an error entry to out log file
#  logError [lineNumber] text
logError() {
  local callerHistory
  callerHistory="$(basename "${BASH_SOURCE[1]}"):${BASH_LINENO[0]}"
  local i
  for (( i=2 ; i < "${#BASH_SOURCE[@]}"; i++ )); do
    callerHistory="$(basename "${BASH_SOURCE[$i]}"):${BASH_LINENO[$((i-1))]} -> $callerHistory"
    # https://stackoverflow.com/questions/192319/how-do-i-know-the-script-file-name-in-a-bash-script
  done
  if [[ $- == *i* ]]; then # interactive shell, [[ -n "$PS1" ]] would also be possible
    /bin/printf "%s\t%s\n" "$(date "$DTFMT")$callerHistory" "<span style=\"color:red;\">$*</span><br/>" | /bin/tee -a "$LOG"
  else
    /bin/printf "%s\t%s\n" "$(date "$DTFMT")$callerHistory" "<span style=\"color:red;\">$*</span><br/>" >> "$LOG"
  fi
  # https://stackoverflow.com/questions/692000/how-do-i-write-standard-error-to-a-file-while-using-tee-with-a-pipe
  # BASH_SOURCE[0] = this file, BASH_SOURCE[1] = caller, BASH_SOURCE[-1] = $0 original script
  # /bin/echo "$(date "$DTFMT"): <span style=\"color:red;\">$1</span><br/>" > >(tee -a stdout.log) 2> >(tee -a stderr.log >&2)
}


##### global ####
DTFMT="+%Y-%m-%d %H:%M:%S"
msglh=""
if [[ -n "${app_name}" ]] && [[ -z "${SYNOPKG_PKGNAME}" ]];then
  SYNOPKG_PKGNAME="${app_name}"
  msglh="$msglh, SYNOPKG_PKGNAME set from app_name"
fi
if [[ -z "${SYNOPKG_PKGNAME}" ]];then
  SYNOPKG_PKGNAME="UNKNOWN_PACKAGE"
  msglh="$msglh, app_name and SYNOPKG_PKGNAME both have been empty!"
fi
unset msglh2
if [[ -z "$LOG" ]];then
  msglh="$msglh, LOG was not yet set"
  if [[ ! -f "/var/log/packages/$SYNOPKG_PKGNAME.log" ]]; then 
    /bin/touch "/var/log/packages/$SYNOPKG_PKGNAME.log"
  fi
  if [[ -f "/var/log/packages/$SYNOPKG_PKGNAME.log" ]]; then 
    logUser=$(stat -c '%U' "/var/log/packages/${SYNOPKG_PKGNAME}.log")
  fi
  if [[ "$(whoami)" == "root" ]] && [[ "$logUser" != "$SYNOPKG_PKGNAME" ]] && [[ "$SYNOPKG_PKGNAME" != "UNKNOWN_PACKAGE" ]]; then
    chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "/var/log/packages/$SYNOPKG_PKGNAME.log" 
    msglh2="owner of /var/log/packages/$SYNOPKG_PKGNAME.log changed to $SYNOPKG_PKGNAME"    
  fi
  if [[ -w "/var/log/packages/$SYNOPKG_PKGNAME.log" ]]; then # exists and writeable
    LOG="/var/log/packages/$SYNOPKG_PKGNAME.log"
    if [[ $(basename "${BASH_SOURCE[1]}") == "upgrade_uifile.sh" ]]; then
      logInfo 3 "From a previous installation of the package '$SYNOPKG_PKGNAME' the logfile '$LOG' is already writable for the user '$(whoami)'"
    # else: at 1st installation not writable during execution of install_uifile.sh and upgrade_uifile.sh!
    fi  
  else
    if [[ ! -d "/var/tmp" ]]; then
      mkdir "/var/tmp" # if nginx is used, this will already exist
    fi
    if [[ -f "/var/tmp/$SYNOPKG_PKGNAME.log" ]]; then
      touch "/var/tmp/$SYNOPKG_PKGNAME.log"
    fi
    if [[ -w "/var/tmp/$SYNOPKG_PKGNAME.log" ]]; then
      LOG="/var/tmp/$SYNOPKG_PKGNAME.log"
      msglh="$msglh, can't use /var/log/packages/$SYNOPKG_PKGNAME.log, using /var/tmp/$SYNOPKG_PKGNAME.log"
    else
      LOG="/tmp/$SYNOPKG_PKGNAME.log"
      msglh="$msglh, can't use /var/log/packages/$SYNOPKG_PKGNAME.log or /var/tmp/$SYNOPKG_PKGNAME.log, using $LOG. user is $(whoami)"
    fi
  fi
fi # if [[ -z "$LOG" ]]

SCRIPTPATHwiz="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; /bin/pwd -P )"
configFilePathName="${SCRIPTPATHwiz%%/@*}/@appdata/${SYNOPKG_PKGNAME}/config" # ${SCRIPTPATHwiz%%/@*} gives e.g. /volume1

#if [[ -w "$configFilePathName" ]]; then
#  line="$(grep -i "DEBUGLOG=" "$configFilePathName")"
#  if [[ -z "$line" ]]; then # generate a new entry:
#    echo "DEBUGLOG=\"$LOG\"" >> "$configFilePathName"
#    msglh="$msglh, config entry 'DEBUGLOG' generated and set to '$LOG'"
#  else
#    DEBUGLOG="$(echo "$line" | sed -e 's/^DEBUGLOG="//' -e 's/"$//')"
#    if [[ "$DEBUGLOG" != "$LOG" ]]; then # change the existing line:
#      sed -i "s|^DEBUGLOG=.*$|DEBUGLOG=\"$LOG\"|" "$configFilePathName"
#      msglh="$msglh, config entry 'DEBUGLOG' changed from '$DEBUGLOG' to '$LOG'"
#    fi
#  fi
#fi

if [[ -z "$LOGLEVEL" ]]; then
  if [[ -f "$configFilePathName" ]]; then
    LOGLEVEL=$(grep -i "LOGLEVEL=" "$configFilePathName" | /bin/sed -e 's/^LOGLEVEL="//i' -e 's/"$//')
  fi
  if [[ -z "$LOGLEVEL" ]];then
    LOGLEVEL=8;
    msglh="$msglh, no LOGLEVEL found in config or no config file found, LOGLEVEL set to 8"
  fi
fi

if [[ -n "$msglh" ]] && [[ $(basename "${BASH_SOURCE[1]}") != "start-stop-status" ]] && [ -z "$log_hlp_msg_done" ]; then
  # skip message if called from start-stop-status, as this occures periodically
  logInfo 3 "${msglh/#, /}"
  export log_hlp_msg_done=1
fi
if [[ -n "$msglh2" ]]; then
  logInfo 5 "$msglh2, previous logs may be found in /var/tmp/$SYNOPKG_PKGNAME.log or /tmp/$SYNOPKG_PKGNAME.log"
fi
# /bin/echo "LOGLEVEL set to $LOGLEVEL"
