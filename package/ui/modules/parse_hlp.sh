#!/bin/bash
# Filename: parse_hlp.sh - coded in utf-8
# used in *.cgi
# Part 1:
#        Copyright (C) 2022 by Tommes
# Member of the German Synology Community Forum
# Part 2:
#  DSM7DemoSPK (https://github.com/toafez/DSM7DemoSPK)

# Adopted to need of UsbEject by Horst Schmid
#      Copyright (C) 2022...2023 by Horst Schmid

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
  local i
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


# logInfoNoEcho may be usefull if stdout is used e.g. as function result, e.g. in cgi files
# Usage: logInfoNoEcho [level] text
logInfoNoEcho() {
  local ll=1 # log level defaultvalue
  if [[ "$1" =~ ^[0-9]+$ ]] && [[ $# -ge 2 ]]; then # Attention: No single or double quotes for regExp allowed!
    ll=$1 # 1st parameter is log level
    shift
  fi
  if [[ "$ll" -le  "$LOGLEVEL" ]]; then
    callerHistory="$(basename "${BASH_SOURCE[1]}"):${BASH_LINENO[0]}"
    local i
    local do_log=1 # logging may be switched off if called from an *.cgi file
    if [[ "${BASH_SOURCE[1]}" == *".cgi" ]]; then
      do_log=0
    fi
    for (( i=2 ; i < "${#BASH_SOURCE[@]}"; i++ )); do
      if [[ "${BASH_SOURCE[$i]}" == *".cgi" ]]; then
        do_log=0
      fi
      if [[ "$LOGLEVEL" -ge "5" ]]; then # full caller history only for high loglevel
        callerHistory="$(basename "${BASH_SOURCE[$i]}"):${BASH_LINENO[$((i-1))]} -> $callerHistory"
        # https://stackoverflow.com/questions/192319/how-do-i-know-the-script-file-name-in-a-bash-script
      fi  
    done

    if [[ "$do_log" -eq "0" ]]; then # cgi file: check the setting 'CGIDEBUG'
      if [[ -z "$app_name" ]]; then
        SCRIPTPATHparsehlp="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; /bin/pwd -P )" # /var/packages/autorun/target/ui/modules/parse_hlp.sh
        app_name="${SCRIPTPATHparsehlp#*packages/}"
        app_name="${app_name%%/*}"
      fi
if [[ "$app_name" == "ui" ]]; then
  logInfoNoEcho 1 "wrong app_name='$app_name'"
fi
      line="$(grep -i "CGIDEBUG=" "/var/packages/$app_name/var/config")"
      if [[ -n "$line" ]];then
        x=$(echo "$line" | sed -e 's/^CGIDEBUG="//' -e 's/"$//')
        if [[ "$x" == "checked" ]]; then
          do_log="1"
        fi
      fi
    fi
    # do_log=1
    if [[ "$do_log" -eq "1" ]]; then
      /bin/printf "%s\t%s\n" "$(date "$DTFMT") $callerHistory" "$*" >> "$LOG"
    fi
  fi
}

# do a login, set $syno_user and set global $is_admin = "yes" or "no"
function cgiLogin() {
  if [[ "${REQUEST_METHOD}" == "POST" ]]; then
    OLD_REQUEST_METHOD="POST"
    REQUEST_METHOD="GET"
  fi
  syno_login=$(/usr/syno/synoman/webman/login.cgi) # login.cgi is a binary ELF file
  # with "join-groupname": "http" in priviledge file the "journalctl -f" gives
  #        /usr/syno/synoman/webman/login.cgi: Permission denied
  # with "join-groupname": "system" it works
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
  # logInfoNoEcho 6 "authenticate.cgi: syno_user=$syno_user"
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
    logInfoNoEcho 8 "from authenticate.cgi: syno_user=$syno_user (is admin)"
  else
    #shellcheck disable=2034
    is_admin="no" # used in caller
    logInfoNoEcho 2 "authenticate.cgi: syno_user=$syno_user (is no admin)"
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
      get["SynoToken"]="${syno_token}"
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
  local msg1=""
  local key
  local val
  if [[ "$REQUEST_METHOD" == "POST" ]]; then
    # post_request="$app_temp/post_request.txt" # that files would allow to save settings from this main page for sub pages
    # Analyze incoming POST requests and process to ${var[key]}="$value" variables:
    local postData
    read -r -n"${HTTP_CONTENT_LENGTH}" postData  # e.g. 'logNewlevel=8&fname=xyz'
    # logInfoNoEcho 8 "HTTP_CONTENT_LENGTH='$HTTP_CONTENT_LENGTH', postData='$postData'"
    if [[ -n "$postData" ]]; then
      local -a POST_vars
      mapfile -d "&" -t POST_vars  < <(/bin/printf '%s' "$postData")
      logInfoNoEcho 8 "HTTP_CONTENT_LENGTH='$HTTP_CONTENT_LENGTH', postData='$postData', split to ${#POST_vars[@]} items"
      local i
      for((i=0; i<${#POST_vars[@]}; i++)); do
        key=${POST_vars[$i]%%=*}
        key=$(urldecode "$key")
        val=${POST_vars[$i]#*=}
        val=$(urldecode "$val")
        # logInfoNoEcho 8 "Post i=$i, key='$key', value='$val'"
        msg1="$msg1  $key='$val' "
        if [[ -n "$key" ]]; then
          # shellcheck disable=2004
          get[$key]="$val" # Attention: ShellCheck warning SC2004 is here wrong! get[key]="$val" is not working!!!
        fi
        logInfoNoEcho 8 "Post i=$i, key='$key', value='$val', get[$key]='${get[$key]}'"
        # Saving POST request items for later processing:
        # /usr/syno/bin/synosetkeyvalue "${post_request}" "$key" "$val"
      done
      if [[ ${#POST_vars[@]} -gt 0 ]]; then
        logInfoNoEcho 7 "get[] setup from received ${#POST_vars[@]} POST data items: $msg1."
      fi
    fi
  fi

  if [[ -n "${QUERY_STRING}" ]]; then
    # QUERY_STRING may be set also in POST mode
    local -a GET_vars
    mapfile -d "&" -t GET_vars < <(/bin/printf '%s' "$QUERY_STRING")
    GET_vars[-1]=$(echo "${GET_vars[-1]}" | sed -z 's|\n$||' ) # remove the \n which was appended to last item by "<<<"

    # Analyze incoming GET requests and process them to ${get[key]}="$value" variables
    logInfoNoEcho 8 "Count of cgi GET items = ${#GET_vars[@]}: ${GET_vars[*]}"
    for ((i=0; i<${#GET_vars[@]}; i++)); do
      key=${GET_vars[i]%%=*}
      key=$(urldecode "$key")
      val=${GET_vars[i]#*=}
      val=$(urldecode "$val")
      msg1="$msg1  $key='$val'"
      # shellcheck disable=2004
      get[$key]="$val" # Attention: ShellCheck warning SC2004 is here wrong! get[key]="$val" is not working!!!
      logInfoNoEcho 8 "GET i=$i, key='$key', value='$val', get[$key]='${get[$key]}'"
      # Saving GET requests for later processing
      # /usr/syno/bin/synosetkeyvalue "${get_request}" "$key" "$val"
    done # $QUERY_STRING with GET parameters
  fi # if [[ -n "${QUERY_STRING}" ]];
  logInfoNoEcho 6 "get[] array setup with ${#get[@]} items: $msg1"
  #if [[ ${#GET_vars[@]} -gt 0 ]]; then
  #  logInfoNoEcho 6 "get[] array setup with ${#get[@]} items: $msg1"
  #fi
}

###############################################################################
LOGLEVEL=8 # 8=log all, 1=log only important, may be overwritten from config file!
DTFMT="+%Y-%m-%d %H:%M:%S"
scpt="$( cd -- "$(/bin/dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; /bin/pwd -P )" # e.g. /volumeX/@appstore/<app>/ui
scpp=${scpt%/*}
# /volumeX/@appstore/<app>, not /var/packages/<app>/target (Link)
if [[ -z "$app_name" ]]; then # if called from translate.sh it's already well set
  app_name=${scpp##*/} # if it's used from translate.sh scriptpathParent would be wrong!
fi
appData="/var/packages/$app_name/var" # verbigt u.U. APPDATA in common!??
# logInfoNoEcho 1 "parse_hlp.sh is executed with path '$SCRIPTPATHparsehlp'"
if [[ -f "$appData/config" ]]; then
  # logInfoNoEcho 1 "parse_hlp.sh, config file $appData/config found"
  # eval "$(grep "LOGLEVEL=" "$appData/config")" # not secure, code injection may be possible
  LOGLEVEL="$(grep "LOGLEVEL=" "$appData/config" | sed -e 's/^LOGLEVEL="//' -e 's/"$//')"
  if [[ -d "$(basename "$LOG" )" ]]; then # in 1st call from main script (called from udev) $LOG may be not yet setup
    logInfoNoEcho 7 "parse_hlp.sh: Read LOGLEVEL from '$appData/config' is $LOGLEVEL"
  fi
else
  # logInfoNoEcho 1 "parse_hlp.sh, config file $appData/config not found!!"
  if [[ -d "$(basename "$LOG" )" ]]; then
    logInfoNoEcho 1 "parse_hlp.sh: Not found: '$appData/config'"
  fi
fi
