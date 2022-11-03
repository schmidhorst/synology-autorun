#!/bin/bash
# Filename: index.cgi - coded in utf-8
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
  # SCRIPT_NAME=/webman/3rdparty/<appName>/index.cgi
  # $0=/usr/syno/synoman/webman/3rdparty/<appName>/index.cgi 
app_link=${SCRIPT_NAME%/*} # "/webman/3rdparty/<appName>"
app_name=${app_link##*/} # "<appName>"
  # DOCUMENT_URI=/webman/3rdparty/<appName>/index.cgi
  # PWD=/volume1/@appstore/<appName>/ui
user=$(whoami) # EnvVar $USER may be not well set, user is '<appName>'
  # REQUEST_URI=/webman/3rdparty/<appName>/index.cgi
  # SCRIPT_FILENAME=/usr/syno/synoman/webman/3rdparty/<appName>/index.cgi
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
    exit
  fi
else
  echo "$(date "$DTFMT"): Failed to find ${app_home}/modules/parse_hlp.sh with functions urlencode() and urldecode() skipped" >> "$LOG"
  exit
fi

# Evaluate app authentication
# To evaluate the SynoToken, change REQUEST_METHOD to GET
[[ "${REQUEST_METHOD}" == "POST" ]] && REQUEST_METHOD="GET" && OLD_REQUEST_METHOD="POST"
# Read out and check the login authorization  ( login.cgi )
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
  logInfo 0 "Access denied, no login permission"
  exit
fi
# Login successful ( success=true )
if echo "${syno_login}" | grep -q success ; then
  login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
fi
if [[ ${login_success} != "true" ]]; then
  logInfo 0 "Access denied, login failed"
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
  logInfo 0 "User '${syno_user}' does not exist"
  exit
fi
# Check whether the local user belongs to the "administrators" group:
if id -G "${syno_user}" | grep -q 101; then
  is_admin="yes"
else
  is_admin="no"
  logInfoNoEcho 2 "User ${syno_user} is no admin"
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
# ${used_lang} is now e.g. enu

# Resetting access permissions
unset syno_login rar_data syno_privilege syno_token syno_user user_exist is_authenticated

# Evaluate app authentication
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
    logInfo 0 "Access denied, no login permission"
    exit
  fi
  # Login successful ( success=true )
  if echo "${syno_login}" | grep -q success ; then
    login_success=$(echo "${syno_login}" | grep success | cut -d "," -f3 | grep success | cut -d ":" -f2 | cut -d " " -f2 )
  fi
  if [[ ${login_success} != "true" ]]; then
    logInfo 0 "Access denied, login failed"
    exit
  fi
  # Set REQUEST_METHOD back to POST again:
  [[ "${OLD_REQUEST_METHOD}" == "POST" ]] && REQUEST_METHOD="POST" && unset OLD_REQUEST_METHOD


# Set variables to "readonly" for protection or empty contents
unset syno_login rar_data syno_privilege
readonly syno_token syno_user user_exist is_admin # is_authenticated

if [ "$is_admin" != "yes" ]; then
  echo "Content-type: text/html"
  echo  
  echo "<!doctype html><html lang=\"${SYNO2ISO[${used_lang}]}\">"
  echo "<HEAD><TITLE>$app_name: ${LoginRequired}</TITLE></HEAD><BODY>${PleaseLogin}<br/>"
  echo "<button onclick=\"location.href='licence.html'\" type=\"button\">${btnShowLicence}</button> "
  echo "<br/></BODY></HTML>"
  logInfoNoEcho 0 "Admin Login required!"
  exit 0
fi

#appCfgDataPath=$(find /volume*/@appdata/${app_name} -maxdepth 0 -type d)
appCfgDataPath="/var/packages/${app_name}/var"
if [ ! -d "${appCfgDataPath}" ]; then
  logInfo 0 "... terminating as app home folder '$ah' ('${app_home}') not found!"
  echo "$(date "$DTFMT"): ls -l /:" >> "$LOG"
  ls -l / >> "$LOG"
  exit
fi  

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

# Securing the Internal Field Separator (IFS) as well as the separation
# of the GET/POST key/value requests, by locating the separator "&"
if [ -z "${backupIFS}" ]; then
  mapfile -d "&" -t GET_vars <<< "${QUERY_STRING}"
  mapfile -d "&" -t POST_vars <<< "${POST_STRING}"
  backupIFS="${IFS}"
#  IFS='&'
#  GET_vars=("${QUERY_STRING}")
#  POST_vars=("${POST_STRING}")
  readonly backupIFS
  IFS="${backupIFS}"
  logInfoNoEcho 6 "CGI QUERY_STRING='${QUERY_STRING}'"
  logInfoNoEcho 6 "CGI POST_STRING='${POST_STRING}'"
  logInfoNoEcho 8 "GET_vars[*]='${GET_vars[*]}'"
  logInfoNoEcho 5 "CGI QUERY_STRING done, GET_vars and/or POST_vars set"
fi

SCRIPT_EXEC_LOG="$appCfgDataPath/execLog"
logfile="$SCRIPT_EXEC_LOG" # default, later optionally set to "$appCfgDataPath/detailLog"
st=$(echo "$logTitleExec")  # default, later optionally set to "$logTitleDetail"

# Analyze incoming GET requests and process them to ${get[key]}="$value" variables
declare -A get # associative array
script=""
for ((i=0; i<${#GET_vars[@]}; i+=1)); do
  key=${GET_vars[i]%%=*}
  key=$(urldecode "$key")
  val=${GET_vars[i]#*=}
  val=$(urldecode "$val")
  logInfoNoEcho 8 "i=$i, key='$key', value='$val'"
  get[$key]=$val
  if [[ "$key" == "action" ]]; then
    if [[ "$val" == "showDetailLog" ]] || [[ "$val" == "delDetailLog" ]] || [[ "$val" == "reloadDetailLog" ]]; then
      logfile="$appCfgDataPath/detailLog"  # Link to /var/log/tmp/autorun.log
      st=$(echo "$logTitleDetail")
    fi
    if [[ "$val" == "delSimpleLog" ]] || [[ "$val" == "delDetailLog" ]]; then
      echo "" > $logfile
      logInfoNoEcho 4 "Old content of '$logfile' removed"
    fi
    if [[ "$val" == "reloadSimpleLog" ]] || [[ "$val" == "reloadDetailLog" ]]; then
      logInfoNoEcho 4 "Page reload"
# https://stackoverflow.com/questions/17642872/refresh-page-and-keep-scroll-position
      script="<script>window.onload=function(){ window.scrollTo(0, document.body.scrollHeight);}</script>"

#      script="<script>"
#      script="${script} window.addEventListener(\"beforeunload\", function (e) { sessionStorage.setItem('scrollpos', window.scrollY); });"
#      script="${script} window.onload=function(){
#        var scrollpos = sessionStorage.getItem('scrollpos');
#        if (scrollpos) {
#          window.scrollTo(0, scrollpos);
#          sessionStorage.removeItem('scrollpos');
#          };
#        }"
#      script="$script</script>"
    fi
  fi
  
  # Reset saved GET/POST requests if main is set
  if [[ "${get[page]}" == "main" ]] && [ -z "${get[section]}" ]; then
    [ -f "${get_request}" ] && rm "${get_request}"
    [ -f "${post_request}" ] && rm "${post_request}"
  fi

  # Saving GET requests for later processing
  /usr/syno/bin/synosetkeyvalue "${get_request}" "$key" "$val"
done

if [[ ${#GET_vars[@]} -gt 0 ]]; then
  logInfoNoEcho 5 "get[] array setup and synosetkeyvalue done."
fi

# Adding the SynoToken to the GET request processing
/usr/syno/bin/synosetkeyvalue "${get_request}" "get[SynoToken]" "$syno_token"

# Analyze incoming POST requests and process to ${var[key]}="$value" variables
declare -A POST_vars
for ((i=0; i<${#POST_vars[@]}; i+=1)); do
  key=${POST_vars[i]%%=*}
  key=$(urldecode "$key")
  val=${POST_vars[i]#*=}
  val=$(urldecode "$val")
  logInfoNoEcho 8 "i=$i, key='$key', value='$val'"
  get[$key]=$val
done

if [[ ${#POST_vars[@]} -gt 0 ]]; then
  logInfoNoEcho 6 "POST_key and POST_value setup and synosetkeyvalue done."
fi
  # Inclusion of the temporarily stored GET/POST requests ( key="value" ) as well as the user settings
[ -f "${get_request}" ] && source "${get_request}"
[ -f "${post_request}" ] && source "${post_request}"

filesize_Bytes=$(stat -c%s "$logfile")  # if it's a link this returns size of the link, not of linked file!  
logInfoNoEcho 8 "Size of $logfile is $filesize_Bytes Bytes"

# Layout output
# --------------------------------------------------------------
if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]; then
  echo "Content-type: text/html"
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
      <link rel="stylesheet" type="text/css" href="dsm3.css"/>'
  echo "$script"
  echo '</head>
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
          if [[ "$logfile" == "$SCRIPT_EXEC_LOG" ]]; then
            echo "<button onclick=\"location.href='index.cgi?action=showDetailLog'\" type=\"button\">${btnShowDetailLog}</button> "
          else
            echo "<button onclick=\"location.href='index.cgi'\" type=\"button\">${btnShowSimpleLog}</button> "
          fi  
          echo "<button onclick=\"location.href='settings.cgi'\" type=\"button\">${btnShowSettings}</button> "
          echo "<button onclick=\"location.href='licence.html'\" type=\"button\">${btnShowLicence}</button> "

          echo '<article>'
          echo "<strong>$st</strong><table>"

          if [[ -f "$logfile" ]]; then

            if [[ filesize_Bytes -lt 10 ]]; then
              msg=$(echo "$execLogNA")
              echo "<tr><td>$msg</td></tr>"            
            else
              while read line; do # read all settings from config file
                timestamp=${line%%: *}
                msg=${line#*: }  
                echo "<tr><td>$timestamp</td><td>$msg</td></tr>"
              done < "$logfile" # Works well even if last line has no \n!
            fi
          else
            logInfoNoEcho 3 "'$logfile' not found!"
            logInfoNoEcho 8 "execLogNA='$execLogNA'"
            msg=$(echo "$execLogNA")
            echo "<tr><td>$msg</td></tr>"
          fi

        else
          # Infotext: Access allowed only for users from the Administrators group
          echo '<p>'${txtAlertOnlyAdmin}'</p>'
        fi
        echo '
      </table></article>
	    <p style="margin-left:22px; line-height: 16px;">'
      if [[ filesize_Bytes -gt 10 ]]; then
        if [[ "$logfile" == "$SCRIPT_EXEC_LOG" ]]; then
          echo "<button onclick=\"location.href='index.cgi?action=reloadSimpleLog'\" type=\"button\">${btnRefresh}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=delSimpleLog'\" type=\"button\">${btnDelLog}</button> "
        else
          echo "<button onclick=\"location.href='index.cgi?action=reloadDetailLog'\" type=\"button\">${btnRefresh}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=delDetailLog'\" type=\"button\">${btnDelLog}</button> "
        fi  
      fi
      btnRefresh
    	echo "</p>
        </body>
      </html>"
fi # if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]
logInfoNoEcho 3 "$(basename "$0") done"
exit

