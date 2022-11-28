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
bDebug="0" # no Buttons for the LED control at bottom as permission is not sufficient to to it!
# --------------------------------------------------------------
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/syno/bin:/usr/syno/sbin
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
ah="/volume*/@appstore/$app_name/ui"
app_home=$(find $ah -maxdepth 0 -type d) # Attention: find is not working with quotet path!!

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
    logInfoNoEcho 0 "Access denied, no login permission"
    exit
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfoNoEcho 0 "Access denied, login failed"
    exit
  fi
  # Set REQUEST_METHOD back to POST again:
  [[ "${OLD_REQUEST_METHOD}" == "POST" ]] && REQUEST_METHOD="POST" && unset OLD_REQUEST_METHOD
  # Reading user/group from authenticate.cgi
  syno_user=$(/usr/syno/synoman/webman/authenticate.cgi) # authenticate.cgi is a Synology binary
  logInfoNoEcho 6 "authenticate.cgi: syno_user=$syno_user"
  # Check if the user exists:
  user_exist=$(grep -o "^${syno_user}:" /etc/passwd)
  # [ -n "${user_exist}" ] && user_exist="yes" || exit
  if [ -z "${user_exist}" ]; then
    logInfoNoEcho 0 "User '${syno_user}' does not exist"
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
  logInfoNoEcho 6 "Loading ${app_home}/modules/parse_language.sh done with result $res"
  # || exit
else
  logInfo 0 "Loading ${app_home}/modules/parse_language.sh failed"
  exit 
fi

# parse_language.sh: out of ${HTTP_ACCEPT_LANGUAGE} tried to set $used_lang
# if no siutable language found: fallbackToEnu=1 

# Resetting access permissions
unset syno_login rar_data syno_privilege syno_token syno_user user_exist is_authenticated

# Evaluate app authentication
if [[ "$bDebug" -eq 0 ]]; then
  # To evaluate the SynoToken, change REQUEST_METHOD to GET
  [[ "${REQUEST_METHOD}" == "POST" ]] && REQUEST_METHOD="GET" && OLD_REQUEST_METHOD="POST"
  # Read out and check the login authorization  ( login.cgi )
  syno_login=$(/usr/syno/synoman/webman/login.cgi)
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
    logInfoNoEcho 0 "Access denied, no login permission"
    exit
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfoNoEcho 0 "Access denied, login failed"
    exit
  fi
  # Set REQUEST_METHOD back to POST again:
  [[ "${OLD_REQUEST_METHOD}" == "POST" ]] && REQUEST_METHOD="POST" && unset OLD_REQUEST_METHOD
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
  logInfoNoEcho 0 "Admin Login required!"
  echo "Admin Login required!"
  exit 0
fi

#appCfgDataPath=$(find /volume*/@appdata/${app_name} -maxdepth 0 -type d)
appCfgDataPath="/var/packages/${app_name}/var"
if [ ! -d "${appCfgDataPath}" ]; then
  logInfo 0 "... terminating as app home folder '$appCfgDataPath' not found!"
  echo "$(date "$DTFMT"): ls -l /:" >> "$LOG"
  ls -l / >> "$LOG"
  exit
fi  

# Generate the text with the actual settings values and the language specific descriptions:
st=$(echo "$settingsTitle")  # = eval the $app_name in the $settingsTitle
ledResetHintRequired=0
while read line; do # read all settings from config file
  itemName=${line%%=*}
  eval "$line"
  settings="${settings}$itemName='${!itemName}'<br/>"
  if [[ "$itemName" == "ADD_NEW_FINGERPRINTS" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">"
    if [[ "$ADD_NEW_FINGERPRINTS" -eq 0 ]]; then
      fp=$(echo "$fingerprint0")  # replace variables like script '/$SCRIPT' is attached in original string 
      settings="${settings}$fp<br/>" # echo because $SCRIPT is included
    elif [[ "$ADD_NEW_FINGERPRINTS" -eq 1 ]]; then
      if [[ "$ENTRY_COUNT" -eq 0 ]]; then
        fp=$(echo "$fingerprint1count0")
        settings="${settings}$fp<br/>"
      else
        fp=$(echo "$fingerprint1count1")
        settings="${settings}$fp<br/>"
      fi
    elif [[ "$ADD_NEW_FINGERPRINTS" -eq 2 ]]; then
      fp=$(echo "$fingerprint2")
      settings="${settings}$fp<br/>"
    elif [[ "$ADD_NEW_FINGERPRINTS" -eq 3 ]]; then
      fp=$(echo "$fingerprint3")
      settings="${settings}$fp<br/>"
    fi
    settings="${settings}</p>"
  elif [[ "$itemName" == "SCRIPT" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${script1}<br/></p>"
  elif [[ "$itemName" == "SCRIPT_AFTER_EJECT" ]]; then
    if [[ "$SCRIPT_AFTER_EJECT" == "" ]]; then
      settings="${settings}<p style=\"margin-left:30px;\">${scriptAfterNone}<br/></p>"
    else
      settings="${settings}<p style=\"margin-left:30px;\">${scriptAfter}<br/></p>"
    fi  
  elif [[ "$itemName" == "TRIES" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${tries1}<br/></p>"
  elif [[ "$itemName" == "WAIT" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${wait1}<br/></p>"
  elif [[ "$itemName" == "BEEP" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${beep1}<br/></p>"
  elif [[ "$itemName" == "LED" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${led1}<br/></p>"
		if [[ "${!itemName}" -ne "0" ]]; then
		  ledResetHintRequired=1
		fi
  elif [[ "$itemName" == "LED_COPY" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${ledCopy1}<br/></p>"
		if [[ "${!itemName}" -ne "0" ]]; then
		  ledResetHintRequired=1
		fi
  elif [[ "$itemName" == "EJECT_TIMEOUT" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${ejectTimeout1}<br/></p>"
  elif [[ "$itemName" == "LOG_MAX_LINES" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${logMaxLines1}<br/></p>"  
  elif [[ "$itemName" == "NOTIFY_USERS" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${notifyUsers1}<br/></p>"  
  elif [[ "$itemName" == "NO_DSM_MESSAGE_RETURN_CODES" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${noDsmMessageReturnCodes}<br/></p>"  
  elif [[ "$itemName" == "LOGLEVEL" ]]; then
    settings="${settings}<p style=\"margin-left:30px;\">${logVerbose1}<br/></p>"  
  fi
  # echo "  line='$line', itemName='$itemName', value='${!itemName}'" >> "$LOG"
done < "$appCfgDataPath/config" # Works well even if last line has no \n!
if [[ "$ledResetHintRequired" -ne "0" ]]; then
  settings="${settings}<p>${ledResetHint}</p>"  
fi
ENTRY_COUNT=0
if [[ -f "$appCfgDataPath/FINGERPRINTS" ]]; then
  ENTRY_COUNT=$(wc -l < "$appCfgDataPath/FINGERPRINTS")
fi
logInfoNoEcho 6 "Fingerprint ENTRY_COUNT='$ENTRY_COUNT'"

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
get_request="$app_temp/get_request.txt"
post_request="$app_temp/post_request.txt"

# If no page set, then show home page
if [ -z "${get[page]}" ]; then
  logInfoNoEcho 6 "generating $get_request ..." # /volume1/@appstore/autorun/ui/temp/get_request.txt
  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[page]" "main"  # write and read an .ini style file with lines of key=value pairs
  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[section]" "start"
  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[SynoToken]" "$syno_token"
fi

# Processing GET/POST request variables
# CONTENT_LENGTH: CGI meta variable https://stackoverflow.com/questions/59839481/what-is-the-content-length-varaible-of-a-cgi

# https://www.parckwart.de/computer_stuff/bash_and_cgi_parsing_get_and_post_requests  
  #if [ -z "${POST_STRING}" ] && [ "${REQUEST_METHOD}" = "POST" ] && [ -n "${CONTENT_LENGTH}" ]; then
  #  read -n ${CONTENT_LENGTH} POST_STRING
  #fi

# mapfile -d "&" -t GET_vars <<< "${QUERY_STRING}" here-string <<< appends a newline!
mapfile -d "&" -t GET_vars < <(printf '%s' "$QUERY_STRING")
mapfile -d "&" -t POST_vars  < <(printf '%s' "$POST_STRING")
logInfoNoEcho 5 "CGI QUERY_STRING done, GET_vars and/or POST_vars set"

# Analyze incoming GET requests and process them to ${get[key]}="$value" variables
declare -A get # associative array
for ((i=0; i<${#GET_vars[@]}; i+=1)); do
  key=${GET_vars[i]%%=*}
  key=$(urldecode "$key")
  if [[ -n "$key" ]]; then
    val=${GET_vars[i]#*=}
    val=$(urldecode "$val")
    logInfoNoEcho 8 "i=$i, key='$key', value='$val'"
    get[$key]=$val
    if [[ "$key" == "action" ]]; then
      if [[ "$val" == "copyLedOn" ]]; then # not working!!! Would require root permission!
        res=$(/bin/echo "@" > /dev/ttyS1) # @ 	0x40 	Copy LED on
        ret=$?
        logInfoNoEcho 8 "CopyLED ON done with $ret: '$res'"
      elif [[ "$val" == "copyLedOff" ]]; then # not working!!! Would require root permission!
        res=$(/bin/echo "B" > /dev/ttyS1) # B 	0x42 	Copy LED off
        ret=$?
        logInfoNoEcho 8 "CopyLED OFF done with $ret: '$res'"
      elif [[ "$val" == "statusLedGreen" ]]; then  # not working!!! Would require root permission!  
        /bin/echo "8" > /dev/ttyS1 # 8 	0x38 	Status LED green (default)
        logInfoNoEcho 8 "StatusLED green done"
      elif [[ "$val" == "statusLedOff" ]]; then  # not working!!! Would require root permission!   
        /bin/echo "7" > /dev/ttyS1 # 7 	0x37 	Status LED off
        logInfoNoEcho 8 "StatusLED green done"
      fi
    fi
    # Reset saved GET/POST requests if main is set
    if [[ "${get[page]}" == "main" ]] && [ -z "${get[section]}" ]; then
      [ -f "${get_request}" ] && rm "${get_request}"
      [ -f "${post_request}" ] && rm "${post_request}"
    fi

    # Saving GET requests for later processing
    /usr/syno/bin/synosetkeyvalue "${get_request}" "$key" "$val"
  fi # if [[ -n "$key" ]]; then 
done

if [[ ${#GET_vars[@]} -gt 0 ]]; then
  logInfoNoEcho 5 "get[] array setup and synosetkeyvalue done."
fi

# Adding the SynoToken to the GET request processing
/usr/syno/bin/synosetkeyvalue "${get_request}" "get[SynoToken]" "$syno_token"

# Analyze incoming POST requests and process to ${var[key]}="$value" variables
for ((i=0; i<${#POST_vars[@]}; i+=1)); do
  key=${POST_vars[i]%%=*}
  key=$(urldecode "$key")
  val=${POST_vars[i]#*=}
  val=$(urldecode "$val")
  logInfoNoEcho 8 "i=$i, key='$key', value='$val'"
  if [[ -n "$key" ]]; then
    get[$key]=$val
  fi  
done

if [[ ${#POST_vars[@]} -gt 0 ]]; then
  logInfoNoEcho 6 "POST_key and POST_value setup and synosetkeyvalue done."
fi
  # Inclusion of the temporarily stored GET/POST requests ( key="value" ) as well as the user settings
[ -f "${get_request}" ] && source "${get_request}"
[ -f "${post_request}" ] && source "${post_request}"

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
logInfoNoEcho 3 "$(basename "$0") done"
exit

