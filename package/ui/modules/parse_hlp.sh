#!/bin/bash
# Filename: parse_hlp.sh - coded in utf-8
# used in *.cgi
# Part 1:
#        Copyright (C) 2022 by Tommes
# Member of the German Synology Community Forum
# Part 2:
#  DSM7DemoSPK (https://github.com/toafez/DSM7DemoSPK) and adopted to UsbEject by Horst Schmid
#        Copyright (C) 2022 by Tommes
# Member of the German Synology Community Forum
#
#             License GNU GPLv3
#   https://www.gnu.org/licenses/gpl-3.0.html
# Changed & extended by Horst Schmid
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
      [a-zA-Z0-9.~_-])
        /bin/printf '%s' "$c"
        ;;
      *)
        /bin/printf '%%%02X' "'$c"
        ;;
      esac
  done
  LC_COLLATE=$old_lc_collate
}


function urldecode() {
  # urldecode <string>
  local url_encoded="${1//+/ }"
  /bin/printf '%b' "${url_encoded//%/\\x}"
}


# noEcho may be usefull if stdout is used e.g. as function result, e.g. in cgi files
# logInfoNoEcho [level] text
logInfoNoEcho() {
  if [[ "$1" =~ ^[0-9]+$ ]] && [[ $# -ge 2 ]]; then # Attention: No single or double quotes for regExp allowed!
    ll=$1
    shift
  else
    ll=1 # default value for used logLevel
  fi
  if [[ "$ll" -le  "$LOGLEVEL" ]]; then
    /bin/echo -e "$(date "$DTFMT"): $*" >> "$LOG"
  fi
}


function cgiLogin() {
  if [[ "${REQUEST_METHOD}" == "POST" ]]; then
    OLD_REQUEST_METHOD="POST"
    REQUEST_METHOD="GET"
  fi
  syno_login=$(/usr/syno/synoman/webman/login.cgi) # login.cgi is a binary ELF file
  # echo -e "\n$(date "$DTFMT"): syno_login='$syno_login'" >> "$LOG" # X-Content-Type-Options, Content-Security-Policy, Set-Cookie, SynoToken
  # and "{"SynoToken"	"xxxxxxxxx", "result"	"success", "success"	true}"

  # SynoToken ( only when protection against Cross-Site Request Forgery Attacks is enabled ):
  if echo "${syno_login}" | grep -q SynoToken ; then
    syno_token=$(echo "${syno_login}" | grep SynoToken | cut -d ":" -f2 | cut -d '"' -f2)
  fi
  if [ -n "${syno_token}" ]; then
    [ -z "${QUERY_STRING}" ] && QUERY_STRING="SynoToken=${syno_token}" || QUERY_STRING="${QUERY_STRING}&SynoToken=${syno_token}"
  fi
  # Login permission ( result=success ):
  if echo "${syno_login}" | grep -q result ; then
    login_result=$(echo "${syno_login}" | grep result | cut -d ":" -f2 | cut -d '"' -f2)
  fi
  if [[ ${login_result} != "success" ]]; then
    logInfoNoEcho 1 "Access denied, no login permission"
    return 3
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfoNoEcho 1 "Access denied, login failed"
    return 4
  fi
  # Set REQUEST_METHOD back to POST again:
  if [[ "${OLD_REQUEST_METHOD}" == "POST" ]]; then
    REQUEST_METHOD="POST"
    unset OLD_REQUEST_METHOD
  fi
  # Reading user/group from authenticate.cgi
  syno_user=$(/usr/syno/synoman/webman/authenticate.cgi) # authenticate.cgi is a Synology binary
  logInfoNoEcho 6 "authenticate.cgi: syno_user=$syno_user"
  # Check if the user exists:
  user_exist=$(grep -o "^${syno_user}:" /etc/passwd)
  # [ -n "${user_exist}" ] && user_exist="yes" || exit
  if [ -z "${user_exist}" ]; then
    logInfoNoEcho 1 "User '${syno_user}' does not exist"
    return 5
  fi
  # Check whether the local user belongs to the "administrators" group:
  if id -G "${syno_user}" | grep -q 101; then
    is_admin="yes"
    logInfoNoEcho 8 "User ${syno_user} is admin"
  else
    is_admin="no"
    logInfoNoEcho 2 "User ${syno_user} is no admin"
  fi
  return 0
}


function evaluateCgiLogin() {
  # To evaluate the SynoToken, change REQUEST_METHOD to GET
  if [[ "${REQUEST_METHOD}" == "POST" ]]; then
    OLD_REQUEST_METHOD="POST"
    REQUEST_METHOD="GET"
  fi
  # Read out and check the login authorization  ( login.cgi )
  # SynoToken ( only when protection against Cross-Site Request Forgery Attacks is enabled ):
  if echo "${syno_login}" | grep -q SynoToken ; then
    syno_token=$(echo "${syno_login}" | grep SynoToken | cut -d ":" -f2 | cut -d '"' -f2)
  fi
  if [ -n "${syno_token}" ]; then
    if [[ "${QUERY_STRING}" != *"SynoToken=${syno_token}"* ]]; then
      # QUERY_STRING="${QUERY_STRING}&SynoToken=${syno_token}"
      get[SynoToken]="${syno_token}"
    fi
  fi
  # Login permission ( result=success ):
  if echo "${syno_login}" | grep -q result ; then
    login_result=$(echo "${syno_login}" | grep result | cut -d ":" -f2 | cut -d '"' -f2)
    logInfoNoEcho 7 "login_result='$login_result' extracted from syno_login='$syno_login'"
  fi
  if [[ ${login_result} != "success" ]]; then
    logInfoNoEcho 1 "Access denied, no login permission"
    return 6
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfoNoEcho 1 "Access denied, login failed"
    return 7
  fi
  # Set REQUEST_METHOD back to POST again:
  if [[ "${OLD_REQUEST_METHOD}" == "POST" ]]; then
    REQUEST_METHOD="POST"
    unset OLD_REQUEST_METHOD
  fi
  return 0
}


function cgiDataEval() {
# Analyze incoming POST requests and process them to ${get[key]}="$value" variables
  if [[ "$REQUEST_METHOD" == "POST" ]]; then
    # post_request="$app_temp/post_request.txt" # that files would allow to save settings from this main page for sub pages
    # Analyze incoming POST requests and process to ${var[key]}="$value" variables:
    logInfoNoEcho 8 "Count of cgi POST items = ${#POST_vars[@]}, HTTP_CONTENT_LENGTH='$HTTP_CONTENT_LENGTH'"  # Zero!?
    read -n${HTTP_CONTENT_LENGTH} postData  # e.g. 'logNewlevel=8&fname=xyz'
    logInfoNoEcho 8 "postData='$postData'"
    if [[ -n "$postData" ]]; then
      mapfile -d "&" -t POST_vars  < <(/bin/printf '%s' "$postData")
      # mapfile -d "&" -t POST_vars  <<< "$postData"
      # POST_vars[-1]=$(echo "${POST_vars[-1]}" | sed -z 's|\n$||' ) # remove the \n which was appended to last item by "<<<"
      for ((i=0; i<${#POST_vars[@]}; i+=1)); do
        key=${POST_vars[i]%%=*}
        key=$(urldecode "$key")
        val=${POST_vars[i]#*=}
        val=$(urldecode "$val")
        logInfoNoEcho 8 "Post i=$i, key='$key', value='$val'"
        if [[ -n "$key" ]]; then
          get[$key]=$val
        fi
        # Saving POST request items for later processing:
        # /usr/syno/bin/synosetkeyvalue "${post_request}" "$key" "$val"
      done
      if [[ ${#POST_vars[@]} -gt 0 ]]; then
        logInfoNoEcho 7 "get[] setup from received POST data."
      fi
    fi
  fi

  if [[ -n "${QUERY_STRING}" ]]; then
    # QUERY_STRING may be set also in POST mode
    # mapfile -d "&" -t GET_vars <<< "${QUERY_STRING}" # here-string <<< appends a newline!
    mapfile -d "&" -t GET_vars < <(/bin/printf '%s' "$QUERY_STRING")
    GET_vars[-1]=$(echo "${GET_vars[-1]}" | sed -z 's|\n$||' ) # remove the \n which was appended to last item by "<<<"

    # Analyze incoming GET requests and process them to ${get[key]}="$value" variables
    logInfoNoEcho 8 "Count of cgi GET items = ${#GET_vars[@]}"
    for ((i=0; i<${#GET_vars[@]}; i+=1)); do
      key=${GET_vars[i]%%=*}
      key=$(urldecode "$key")
      val=${GET_vars[i]#*=}
      val=$(urldecode "$val")
      logInfoNoEcho 8 "GET i=$i, key='$key', value='$val'"
      get[$key]=$val
      # Saving GET requests for later processing
      # /usr/syno/bin/synosetkeyvalue "${get_request}" "$key" "$val"
    done # $QUERY_STRING with GET parameters
  fi # if [[ -n "${QUERY_STRING}" ]];
  if [[ ${#GET_vars[@]} -gt 0 ]]; then
    logInfoNoEcho 8 "get[] array setup with ${#get[@]} items"
  fi
}

###############################################################################
LOGLEVEL=8 # 8=log all, 1=log only important, may be overwritten from config file!
DTFMT="+%Y-%m-%d %H:%M:%S"
SCRIPTPATHTHIS="$( cd -- "$(/bin/dirname "$0")" >/dev/null 2>&1 ; /bin/pwd -P )" # e.g. /volumeX/@appstore/<app>/ui
scriptpathParent=${SCRIPTPATHTHIS%/*}
# /volumeX/@appstore/<app>, not /var/packages/<app>/target (Link)
if [[ -z "$app_name" ]]; then # if called from translate.sh it's already well set
  app_name=${scriptpathParent##*/} # if it's used from translate.sh scriptpathParent would be wrong!
fi
appData="/var/packages/$app_name/var" # verbigt u.U. APPDATA in common!??
if [[ -f "$appData/config" ]]; then
  eval "$(grep "LOGLEVEL=" "$appData/config")"
  if [[ -d "$(basename "$LOG" )" ]]; then # in 1st call from main script (called from udev) $LOG may be not yet setup
    logInfoNoEcho 8 "parse_hlp.sh is executed with path '$SCRIPTPATHTHIS'"
    logInfoNoEcho 7 "parse_hlp.sh: Read LOGLEVEL from '$appData/config' is $LOGLEVEL"
  fi
else
  if [[ -d "$(basename "$LOG" )" ]]; then
    logInfoNoEcho 8 "parse_hlp.sh is executed with path '$SCRIPTPATHTHIS'"
    logInfoNoEcho 1 "parse_hlp.sh: Not found: '$appData/config'"
  fi
fi

