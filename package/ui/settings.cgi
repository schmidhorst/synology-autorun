#!/bin/bash
# Filename: settings.cgi - coded in utf-8
#    taken from
#  DSM7DemoSPK (https://github.com/toafez/DSM7DemoSPK) and adopted to autorun by Horst Schmid
#        Copyright (C) 2022 by Tommes
# Member of the German Synology Community Forum

#             License GNU GPLv3
#   https://www.gnu.org/licenses/gpl-3.0.html

# This index.cgi is in the config file configured as "url": "/webman/3rdparty/<appName>/index.cgi"
# /usr/syno/synoman/webman/3rdparty/<app> is linked to /volumeX/@apptemp/<app>/ui
# and /var/packages/<app>/target/ui is the same folder

# for https://www.shellcheck.net/
# shellcheck disable=SC1090

# Initiate system
# --------------------------------------------------------------
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/syno/bin:/usr/syno/sbin
bDebug="0" # no Buttons for the LED control at bottom as permission is not sufficient to to it!
  # SCRIPT_NAME=/webman/3rdparty/<appName>/settings.cgi
if [[ -z "$SCRIPT_NAME" ]]; then  # direct start in debug run
  SCRIPT_NAME="/webman/3rdparty/autorun/index.cgi"
  bDebug=1
  echo "###### index.cgi executed in debug mode!!  ######"
fi
  # $0=/usr/syno/synoman/webman/3rdparty/<appName>/settings.cgi
app_link=${SCRIPT_NAME%/*} # "/webman/3rdparty/<appName>"
app_name=${app_link##*/} # "<appName>"
  # DOCUMENT_URI=/webman/3rdparty/<appName>/settings.cgi
  # PWD=/volume1/@appstore/<appName>/ui
user=$(whoami) # EnvVar $USER may be not well set, user is '<appName>'
  # REQUEST_URI=/webman/3rdparty/<appName>/settings.cgi
  # SCRIPT_FILENAME=/usr/syno/synoman/webman/3rdparty/<appName>/settings.cgi
display_name="Tool for an script autorun at storage (USB or eSATA) to DSM 7" # used as title of Page
LOG="/var/log/tmp/${app_name}.log"  # no permission if default -rw-r--r-- root:root was not changed
DTFMT="+%Y-%m-%d %H:%M:%S" # may be overwritten by parse_hlp
echo -e "\n$(date "$DTFMT"): App '$app_name' file '$0' started as user '$user' ..." >> "$LOG"
echo -e "$(date "$DTFMT"): with parameters '$QUERY_STRING'" >> "$LOG" # e.g. "action=copyLedOff"
# $0=/usr/syno/synoman/webman/3rdparty/<appName>/index.cgi
# ah="/volume*/@appstore/$app_name/ui"
# app_home=$(find $ah -maxdepth 0 -type d) # Attention: find is not working with the wildcard in the quotet part of path!!
app_home=$(find /volume*/@appstore/"$app_name/ui" -maxdepth 0 -type d)

# Load urlencode and urldecode function from ../modules/parse_hlp.sh:
if [ -f "${app_home}/modules/parse_hlp.sh" ]; then
  source "${app_home}/modules/parse_hlp.sh"
  res=$?
  echo "$(date "$DTFMT"): Loading ${app_home}/modules/parse_hlp.sh with functions urlencode() and urldecode() done with result $res" >> "$LOG"
  if [[ "$res" -gt 1 ]]; then
    echo "### Loading ${app_home}/modules/parse_hlp.sh failed!! ###"
    exit
  fi
else
  echo "$(date "$DTFMT"): Failed to find ${app_home}/modules/parse_hlp.sh with functions urlencode() and urldecode() skipped" >> "$LOG"
  echo "Failed to find ${app_home}/modules/parse_hlp.sh"
  exit
fi

# Evaluate app authentication
# To evaluate the SynoToken, change REQUEST_METHOD to GET
if [[ "${REQUEST_METHOD}" == "POST" ]]; then
  OLD_REQUEST_METHOD="POST"
  REQUEST_METHOD="GET"
fi
# Read out and check the login authorization  ( login.cgi )
if [[ "$bDebug" -eq 0 ]]; then
  syno_login=$(/usr/syno/synoman/webman/login.cgi)
  # echo -e "\n$(date "$DTFMT"): syno_login='$syno_login'" >> "$LOG"

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
    exit
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfoNoEcho 1 "Access denied, login failed"
    exit
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
    exit
  fi
  # Check whether the local user belongs to the "administrators" group:
  if id -G "${syno_user}" | grep -q 101; then
    is_admin="yes"
  else
    is_admin="no"
    logInfoNoEcho 2 "User ${syno_user} is no admin"
  fi
else
  echo "Due to debug mode login skipped"
fi

if [ -x "${app_home}/modules/parse_language.sh" ]; then
  source "${app_home}/modules/parse_language.sh" "${syno_user}"
  res=$?
  logInfoNoEcho 7 "Loading ${app_home}/modules/parse_language.sh done with result $res"
  # || exit
else
  logInfo 1 "Loading ${app_home}/modules/parse_language.sh failed"
  exit
fi

# parse_language.sh: out of ${HTTP_ACCEPT_LANGUAGE} tried to set $used_lang
# if no siutable language found: fallbackToEnu=1

# Resetting access permissions
unset syno_login rar_data syno_privilege syno_token syno_user user_exist is_authenticated
declare -A get # associative array for parameters (POST, GET)

# Evaluate app authentication
if [[ "$bDebug" -eq 0 ]]; then
  # To evaluate the SynoToken, change REQUEST_METHOD to GET
  if [[ "${REQUEST_METHOD}" == "POST" ]]; then
    OLD_REQUEST_METHOD="POST"
    REQUEST_METHOD="GET"
  fi
  # Read out and check the login authorization  ( login.cgi )
  syno_login=$(/usr/syno/synoman/webman/login.cgi) # login.cgi is a binary ELF file
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
  fi
  if [[ ${login_result} != "success" ]]; then
    logInfoNoEcho 1 "Access denied, no login permission"
    exit
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfoNoEcho 1 "Access denied, login failed"
    exit
  fi
  # Set REQUEST_METHOD back to POST again:
  if [[ "${OLD_REQUEST_METHOD}" == "POST" ]]; then
    REQUEST_METHOD="POST"
    unset OLD_REQUEST_METHOD
  fi
else
  echo "Due to debug mode access check skipped"
  is_admin="yes"
fi

# Set variables to "readonly" for protection or empty contents
unset syno_login rar_data syno_privilege
readonly syno_token syno_user user_exist is_admin # is_authenticated

if [ "$is_admin" != "yes" ]; then
  echo "Content-type: text/html"
  echo
  echo "<!doctype html><html lang=\"${SYNO2ISO[${used_lang}]}\">"
  echo "<HEAD><TITLE>$app_name: ${LoginRequired}</TITLE></HEAD><BODY>${PleaseLogin}<br/>"
  echo "<br/></BODY></HTML>"
  logInfoNoEcho 1 "Admin Login required!"
  echo "Admin Login required!"
  exit 0
fi

#appCfgDataPath=$(find /volume*/@appdata/${app_name} -maxdepth 0 -type d)
appCfgDataPath="/var/packages/${app_name}/var"
if [ ! -d "${appCfgDataPath}" ]; then
  logInfo 1 "... terminating as app home folder '$appCfgDataPath' not found!"
  echo "$(date "$DTFMT"): ls -l /:" >> "$LOG"
  ls -l / >> "$LOG"
  exit
fi

# Generate the text with the actual settings values and the language specific descriptions:
st=$(echo "$settingsTitle")  # = eval the $app_name in the $settingsTitle
ledResetHintRequired=0
securityWarningDone=0
while read line; do # read all settings from config file
  itemName=${line%%=*}
  if [[ "$itemName" != "VERSION" ]]; then # skip the VERSION entry as this is not a real setting and only used for re-installation
    eval "$line"
    settings="${settings}$itemName='${!itemName}'<br/>"
    if [[ "$itemName" == "ADD_NEW_FINGERPRINTS" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">"
      fp=$(echo "$settingFingerprint")  # replace variables like script '/$SCRIPT' is attached in original string
      settings="${settings}$fp<br/>" # echo because $SCRIPT is included
      settings="${settings}</p>"
    elif [[ "$itemName" == "SCRIPT" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingScript}<br/></p>"
    elif [[ "$itemName" == "SCRIPT_AFTER_EJECT" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingScriptAfter}<br/></p>"
    elif [[ "$itemName" == "TRIES" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingTries}<br/></p>"
    elif [[ "$itemName" == "WAIT" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingWait}<br/></p>"
    elif [[ "$itemName" == "BEEP" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingBeep}<br/></p>"
    elif [[ "$itemName" == "LED" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingLedStatus}<br/></p>"
      if [[ "${!itemName}" -ne "0" ]]; then
        ledResetHintRequired=1
      fi
    elif [[ "$itemName" == "LED_COPY" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingLedCopy}<br/></p>"
      if [[ "${!itemName}" -ne "0" ]]; then
        ledResetHintRequired=1
      fi
    elif [[ "$itemName" == "EJECT_TIMEOUT" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingEjectTimeout}<br/></p>"
    elif [[ "$itemName" == "LOG_MAX_LINES" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingLogMaxLines}<br/></p>"
    elif [[ "$itemName" == "NOTIFY_USERS" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingNotifyUsers}<br/></p>"
    elif [[ "$itemName" == "NO_DSM_MESSAGE_RETURN_CODES" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingNoDsmMessageReturnCodes}<br/></p>"
    elif [[ "$itemName" == "LOGLEVEL" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${settingLogVerbose}<br/></p>"
    fi
    if [[ "$ADD_NEW_FINGERPRINTS" == "0" ]] || [[ "$ADD_NEW_FINGERPRINTS" == "2" ]]; then
      if [[ "$SCRIPT" != *"/"* ]] && [[ "$securityWarningDone" -eq "0" ]]; then
        settings="${settings}<p>${settingSecurityWarning}<br/></p>"
        securityWarningDone="1"
      fi
    fi
  fi
  # echo "  line='$line', itemName='$itemName', value='${!itemName}'" >> "$LOG"
done < "$appCfgDataPath/config" # Works well even if last line has no \n!
if [[ "$ledResetHintRequired" -ne "0" ]]; then
  settings="${settings}<p><br>${ledResetHint}</p>"
fi
ENTRY_COUNT=0
if [[ -f "$appCfgDataPath/FINGERPRINTS" ]]; then
  ENTRY_COUNT=$(wc -l < "$appCfgDataPath/FINGERPRINTS")
fi
if [[ "$ENTRY_COUNT" -gt "0" ]]; then
  settings="${settings}${settingHeadlineFingerprints}<br/><p style=\"margin-left:30px;\">"
  while read line; do # read all settings from logfile
    settings="${settings}${line}<br>"
  done < "$appCfgDataPath/FINGERPRINTS" # Works well even if last line has no \n!
  settings="${settings}<br></p>"
fi
settings="${settings}<p><strong>${runInstallationAgain}</strong></p><br/>"
# echo "settings='$settings'" >> "$LOG"

# Set environment variables
# --------------------------------------------------------------
# Set up folder for temporary data:
app_temp="${app_home}/temp" # /volume*/@appstore/${app_name}/ui/temp
#  or /volume*/@apptemp/$app_name ??
if [ ! -d "${app_temp}" ]; then
  mkdir -p -m 755 "${app_temp}"
fi
# result="${app_temp}/result.txt"

# Evaluate POST and GET requests and cache them in files
  # get_keyvalue="/bin/get_key_value"
# get_request="$app_temp/get_request.txt"

# If no page set, then show home page
#if [ -z "${get[page]}" ]; then
#  logInfoNoEcho 6 "generating $get_request ..." # /volume1/@appstore/autorun/ui/temp/get_request.txt
#  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[page]" "main"  # write and read an .ini style file with lines of key=value pairs
#  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[section]" "start"
#  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[SynoToken]" "$syno_token"
#fi

# Processing GET/POST request variables
# CONTENT_LENGTH: CGI meta variable https://stackoverflow.com/questions/59839481/what-is-the-content-length-varaible-of-a-cgi

# https://www.parckwart.de/computer_stuff/bash_and_cgi_parsing_get_and_post_requests
  #if [ -z "${POST_STRING}" ] && [ "${REQUEST_METHOD}" = "POST" ] && [ -n "${CONTENT_LENGTH}" ]; then
  #  read -n ${CONTENT_LENGTH} POST_STRING
  #fi


# Analyze incoming POST requests and process them to ${get[key]}="$value" variables
declare -A get # associative array
if [[ "$REQUEST_METHOD" == "POST" ]]; then
  # post_request="$app_temp/post_request.txt" # that files would allow to save settings from this main page for sub pages
  # Analyze incoming POST requests and process to ${var[key]}="$value" variables
  logInfoNoEcho 8 "Count of cgi POST items = ${#POST_vars[@]}, HTTP_CONTENT_LENGTH='$HTTP_CONTENT_LENGTH'"  # Zero!?
  read -n${HTTP_CONTENT_LENGTH} postData  # e.g. 'logNewlevel=8&fname=xyz'
  logInfoNoEcho 8 "postData='$postData'"
  if [[ -n "$postData" ]]; then
    mapfile -d "&" -t POST_vars  < <(/bin/printf '%s' "$postData") # process substitution <(...) may not be available
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
  # mapfile -d "&" -t GET_vars <<< "${QUERY_STRING}" # here-string <<< appends a newline!
  mapfile -d "&" -t GET_vars < <(/bin/printf '%s' "$QUERY_STRING") # process substitution <(...) may be not available
  # GET_vars[-1]=$(echo "${GET_vars[-1]}" | sed -z 's|\n$||' ) # remove the \n which was appended to last item by "<<<"

  # Analyze incoming GET requests and process them to ${get[key]}="$value" variables
  logInfoNoEcho 8 "Count of cgi GET items = ${#GET_vars[@]}"
  for ((i=0; i<${#GET_vars[@]}; i+=1)); do
    key=${GET_vars[i]%%=*}
    key=$(urldecode "$key")
    val=${GET_vars[i]#*=}
    val=$(urldecode "$val")
    logInfoNoEcho 8 "GET i=$i, key='$key', value='$val'"
    get[$key]=$val
    if [[ "$key" == "action" ]]; then

      if [[ "$val" == "copyLedOn" ]]; then # not working!!! Would require root permission!
        res=$(/bin/echo "@" > /dev/ttyS1) # @   0x40  Copy LED on
        ret=$?
        logInfoNoEcho 8 "CopyLED ON done with $ret: '$res'"
      elif [[ "$val" == "copyLedOff" ]]; then # not working!!! Would require root permission!
        res=$(/bin/echo "B" > /dev/ttyS1) # B   0x42  Copy LED off
        ret=$?
        logInfoNoEcho 8 "CopyLED OFF done with $ret: '$res'"
      elif [[ "$val" == "statusLedGreen" ]]; then  # not working!!! Would require root permission!
        /bin/echo "8" > /dev/ttyS1 # 8  0x38  Status LED green (default)
        logInfoNoEcho 8 "StatusLED green done"
      elif [[ "$val" == "statusLedOff" ]]; then  # not working!!! Would require root permission!
        /bin/echo "7" > /dev/ttyS1 # 7  0x37  Status LED off
        logInfoNoEcho 8 "StatusLED green done"
      fi
    fi

    # Reset saved GET/POST requests if main is set
    #if [[ "${get[page]}" == "main" ]] && [ -z "${get[section]}" ]; then
    #  [ -f "${get_request}" ] && rm "${get_request}"
    #  [ -f "${post_request}" ] && rm "${post_request}"
    #fi

    # Saving GET requests for later processing
    # /usr/syno/bin/synosetkeyvalue "${get_request}" "$key" "$val"
  done # $QUERY_STRING with GET parameters
fi # if [[ -n "${QUERY_STRING}" ]];

if [[ ${#GET_vars[@]} -gt 0 ]]; then
  logInfoNoEcho 8 "get[] array setup."
fi

# Adding the SynoToken to the GET request processing
# /usr/syno/bin/synosetkeyvalue "${get_request}" "get[SynoToken]" "$syno_token"

  # Inclusion of the temporarily stored GET/POST requests ( key="value" ) as well as the user settings
# [ -f "${get_request}" ] && source "${get_request}"
# [ -f "${post_request}" ] && source "${post_request}"

# Layout output
# --------------------------------------------------------------
if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]; then
  echo "Content-type: text/html; charset=utf-8"
  echo
  echo "
  <!doctype html>
  <html lang=\"${SYNO2ISO[${used_lang}]}\">
    <head>"
  echo '<meta charset="utf-8" />'
  echo "<title>${display_name}</title>"   # <title>...</title> is not displayed but title from the file config
  echo '
      <link rel="shortcut icon" href="images/icon_32.png" type="image/x-icon" />
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
      <link rel="stylesheet" type="text/css" href="dsm3.css"/>
    </head>
    <body>
      <header></header>
      <article>'
        # Load page content
        # --------------------------------------------------------------
        if [[ "${is_admin}" == "yes" ]]; then
          # Infotext: Enable application level authentication
          # [ -n "${txtActivatePrivileg}" ] && echo ''${txtActivatePrivileg}''
          # Dynamic page output:
          #if [ -f "${get[page]}.sh" ]; then
          #  . ./"${get[page]}.sh"
          #else
          #  echo 'Page '${get[page]}'.sh not found!'
          #fi

          # HTTP GET and POST requests
          echo "<button onclick=\"location.href='index.cgi'\" type=\"button\">${btnShowSimpleLog}</button>"
          #echo '<br \>'
          echo "<p><strong>$st</strong></p>"
          echo "${settings}"
        else
          # Infotext: Access allowed only for users from the Administrators group
          echo '<p>'${txtAlertOnlyAdmin}'</p>'
        fi
        if [[ "$fallbackToEnu" -eq "0" ]]; then
          echo '<p>'${txtLanguageSource}'</p>'
        else
          echo "<p>Could not find a supported language in your webbrowser regional preferences '${HTTP_ACCEPT_LANGUAGE}'. Therefore English is used.</p>"
        fi
        if [[ "$bDebug" -eq "1" ]]; then # LED control is not working, permission denied!
          echo "$ledCtrlHint<br/>"
          echo "<button onclick=\"location.href='index.cgi?action=copyLedOn'\" type=\"button\">CopyLED ON</button> "
          echo "<button onclick=\"location.href='index.cgi?action=copyLedOff'\" type=\"button\">${btnCopyLedOff}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=statusLedGreen'\" type=\"button\">${btnStatusLedGreen}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=statusLedOff'\" type=\"button\">${btnStatusLedOff}</button><br/>"
        fi
        echo '
      </article>
    </body>
  </html>'
fi # if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]
logInfoNoEcho 4 "$(basename "$0") done"
exit

