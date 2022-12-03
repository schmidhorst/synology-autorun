#!/bin/bash
# Filename: parse_hlp.sh - coded in utf-8
# used in *.cgi

#        Copyright (C) 2022 by Tommes 
# Member of the German Synology Community Forum
#             License GNU GPLv3
#   https://www.gnu.org/licenses/gpl-3.0.html

# urlencode and urldecode https://gist.github.com/cdown/1163649
# --------------------------------------------------------------
function urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}


function urldecode() {
    # urldecode <string>
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}


# noEcho may be usefull if stdout is used e.g. as function result, e.g. in cgi files
logInfoNoEcho() {
  if [[ $# == 2 ]]; then
    ll=$1
    shift
  else
    ll=1 # default value for used logLevel 
  fi
  if [[ "$ll" -le  "$LOGLEVEL" ]]; then
	  /bin/echo -e "$(date "$DTFMT"): $*" >> "$LOG"
  fi
}


###############################################################################
LOGLEVEL=8 # 8=log all, 1=log only important, may be overwritten from config file!
DTFMT="+%Y-%m-%d %H:%M:%S"
SCRIPTPATHTHIS="$( cd -- "$(/bin/dirname "$0")" >/dev/null 2>&1 ; /bin/pwd -P )" # e.g. /volumeX/@appstore/<app>/ui
scriptpathParent=${SCRIPTPATHTHIS%/*}
# /volumeX/@appstore/<app>, not /var/packages/<app>/target (Link)
if [[ -z "$APPNAME" ]]; then
  APPNAME=${scriptpathParent##*/} # APPNAME="autorun", but if this is used from translate.sh script it's wrong!
fi
appData="/var/packages/$APPNAME/var" # verbigt u.U. APPDATA in common!??
if [[ -f "$appData/config" ]]; then
  eval "$(grep "LOGLEVEL=" "$appData/config")"
  if [[ -d "$(basename "$LOG" )" ]]; then # in 1st call from autorun $LOG may be not yet setup
    logInfoNoEcho 8 "parse_hlp.sh is executed with path '$SCRIPTPATHTHIS'"
    logInfoNoEcho 7 "parse_hlp.sh: Read LOGLEVEL from '$appData/config' is $LOGLEVEL"
  fi
else
  if [[ -d "$(basename "$LOG" )" ]]; then
    logInfoNoEcho 8 "parse_hlp.sh is executed with path '$SCRIPTPATHTHIS'"
    logInfoNoEcho 1 "parse_hlp.sh: Not found: '$appData/config'"
  fi
fi

