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
bDebug=0
if [[ -z "$SCRIPT_NAME" ]]; then  # direct start in debug run 
  SCRIPT_NAME="/webman/3rdparty/autorun/index.cgi"
  bDebug=1
  echo "###### index.cgi executed in debug mode!!  ######"
fi
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
echo -e "\n$(date "$DTFMT"): App '$app_name' file '$0' started as user '$user' with parameters '$QUERY_STRING' ..." >> "$LOG"
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

# get the installed version of the package for later comparison to latest version on github: 
local_version=$(cat "/var/packages/${app_name}/INFO" | grep ^version | cut -d '"' -f2)
if [ -x "${app_home}/modules/parse_language.sh" ]; then
  source "${app_home}/modules/parse_language.sh" "${syno_user}"
  res=$?
  logInfoNoEcho 7 "Loading ${app_home}/modules/parse_language.sh done with result $res"
  # || exit
else
  logInfo 0 "Loading ${app_home}/modules/parse_language.sh failed"
  exit 
fi
# ${used_lang} is now setup, e.g. enu

# Resetting access permissions
unset syno_login rar_data syno_privilege syno_token syno_user user_exist is_authenticated

# Evaluate app authentication
if [[ "$bDebug" -eq 0 ]]; then
  # To evaluate the SynoToken, change REQUEST_METHOD to GET
  if [[ "${REQUEST_METHOD}" == "POST" ]]; then
    OLD_REQUEST_METHOD="POST"
    REQUEST_METHOD="GET"
  fi
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

licenceFile="licence_${used_lang}.html"
if [[ ! -f "licence_${used_lang}.html" ]]; then
  licenceFile="licence_enu.html"
fi

if [ "$is_admin" != "yes" ]; then
  echo "Content-type: text/html"
  echo  
  echo "<!doctype html><html lang=\"${SYNO2ISO[${used_lang}]}\">"
  echo "<HEAD><TITLE>$app_name: ${LoginRequired}</TITLE></HEAD><BODY>${PleaseLogin}<br/>"
  echo "<button onclick=\"location.href='$licenceFile'\" type=\"button\">${btnShowLicence}</button> "

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
logInfoNoEcho 6 "CGI QUERY_STRING done, GET_vars and/or POST_vars set"

SCRIPT_EXEC_LOG="$appCfgDataPath/execLog"
logfile="$SCRIPT_EXEC_LOG" # default, later optionally set to "$appCfgDataPath/detailLog"
pageTitle=$(echo "$logTitleExec")  # default, later optionally set to "$logTitleDetail"

versionUpdateHint=""
# githubRawInfoUrl="https://raw.githubusercontent.com/schmidhorst/synology-autorun/main/INFO.sh"
 #patched from INFO.sh
if [[ -n "$githubRawInfoUrl" ]]; then
  git_version=$(wget --timeout=30 --tries=1 -q -O- "$githubRawInfoUrl" | grep ^version | cut -d '"' -f2)
  logInfoNoEcho 6 "local_version='$local_version', git_version='$git_version'"
  if [ -n "${git_version}" ] && [ -n "${local_version}" ]; then
	  if dpkg --compare-versions ${git_version} gt ${local_version}; then
  	# if dpkg --compare-versions ${git_version} lt ${local_version}; then # for debugging
      vh=$(echo "$update_available")
		  versionUpdateHint='<p style="text-align:center">'${vh}' <a href="https://github.com/schmidhorst/synology-'${app_name}'/releases" target="_blank">'${git_version}'</a></p>'
  	fi
  fi
fi

# Analyze incoming GET requests and process them to ${get[key]}="$value" variables
declare -A get # associative array
script="<script>"
for ((i=0; i<${#GET_vars[@]}; i+=1)); do
  key=${GET_vars[i]%%=*}
  key=$(urldecode "$key")
  if [[ -n "$key" ]]; then
    val=${GET_vars[i]#*=}
    val=$(urldecode "$val")
    logInfoNoEcho 8 "i=$i, key='$key', value='$val'"
    get[$key]=$val
    if [[ "$key" == "action" ]]; then
      if [[ "$val" == "showDetailLog" ]] || [[ "$val" == "delDetailLog" ]] || [[ "$val" == "reloadDetailLog" ]] || [[ "$val" == "downloadDetailLog" ]]; then
        logfile="$appCfgDataPath/detailLog"  # Link to /var/log/tmp/autorun.log
				pageTitle=$(echo "$logTitleDetail")
      fi
      if [[ "$val" == "delSimpleLog" ]] || [[ "$val" == "delDetailLog" ]]; then
        echo "" > "$logfile"
        logInfoNoEcho 4 "Old content of '$logfile' removed"
      fi
      if [[ "$val" == "downloadSimpleLog" ]] || [[ "$val" == "downloadDetailLog" ]]; then
        logInfoNoEcho 4 "Download content of '$logfile' requested, disposition='$disposition'"
        echo "Content-type: text/plain; charset=utf-8"
        echo "Content-Disposition: attachment; filename=$(basename $logfile).txt"
        echo
        # echo "<!doctype html>"
        cat "$logfile"
				if [[ "$val" == "downloadDetailLog" ]]; then
          echo -e "\n"
          env || printenv
          echo ""
				fi
        exit
      fi
      if [[ "$val" == "reloadSimpleLog" ]] || [[ "$val" == "reloadDetailLog" ]]; then
        logInfoNoEcho 4 "Page reload"
# https://stackoverflow.com/questions/17642872/refresh-page-and-keep-scroll-position
        script="${script} window.onload=function(){ window.scrollTo(0, document.body.scrollHeight);}"  # scroll to bottom

#       script="${script} window.addEventListener(\"beforeunload\", function (e) { sessionStorage.setItem('scrollpos', window.scrollY); });"
#       script="${script} window.onload=function(){
#         var scrollpos = sessionStorage.getItem('scrollpos');
#         if (scrollpos) {
#           window.scrollTo(0, scrollpos);
#           sessionStorage.removeItem('scrollpos');
#           };
#         }"

      fi # reload
    fi # action
  
    # Reset saved GET/POST requests if main is set
    if [[ "${get[page]}" == "main" ]] && [ -z "${get[section]}" ]; then
      [ -f "${get_request}" ] && rm "${get_request}"
      [ -f "${post_request}" ] && rm "${post_request}"
    fi

    # Saving GET requests for later processing
    /usr/syno/bin/synosetkeyvalue "${get_request}" "$key" "$val"
  fi # if [[ -n "$key" ]]; then 
done

script="$script</script>"

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

linkTarget="$(readlink $logfile)" # result 1 if it's not a link
if [[ "$?" -eq "0" ]]; then
  filesize_Bytes=$(stat -c%s "$linkTarget")
  lineCount=$(wc -l < "$linkTarget")
else
  filesize_Bytes=$(stat -c%s "$logfile")  # if it's a link this returns size of the link, not of linked file!  
  lineCount=$(wc -l < "$logfile")
fi
logInfoNoEcho 8 "Size of $logfile is $lineCount lines, $filesize_Bytes Bytes"
if [[ "$bDebug" -ne 0 ]]; then
  echo "startingo to generate html document ..."
fi
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
  # echo "<title>${pageTitle}</title>"   # <title>...</title> is not displayed but title from the file config
  echo '
      <link rel="shortcut icon" href="images/icon_32.png" type="image/x-icon" />
      <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
      <link rel="stylesheet" type="text/css" href="dsm3.css"/>'
  echo "$script"
  echo '</head>
    <body>
      <header>'
  echo "$versionUpdateHint"
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
          echo "<button onclick=\"location.href='$licenceFile'\" type=\"button\">${btnShowLicence}</button> "
          echo "<p><strong>$pageTitle</strong></p>"
          echo "</header><table>"

          if [[ -f "$logfile" ]]; then

            if [[ filesize_Bytes -lt 10 ]]; then
              msg=$(echo "$execLogNA")
              echo "<tr><td>$msg</td></tr>"            
            else
              while read line; do # read all settings from logfile
                timestamp=${line%%: *}
                msg=${line#*: }
								if [[ "$msg" == "$timestamp" ]]; then # no ": " 
								  timestamp="" # put all to 2nd column
								fi  
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
      </table>
	    <p style="margin-left:22px; line-height: 16px;">'
      if [[ filesize_Bytes -gt 10 ]]; then
        if [[ "$logfile" == "$SCRIPT_EXEC_LOG" ]]; then
          echo "<button onclick=\"location.href='index.cgi?action=reloadSimpleLog'\" type=\"button\">${btnRefresh}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=downloadSimpleLog'\" type=\"button\">${btnDownload}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=delSimpleLog'\" type=\"button\">${btnDelLog}</button> "
        else
          echo "<button onclick=\"location.href='index.cgi?action=reloadDetailLog'\" type=\"button\">${btnRefresh}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=downloadDetailLog'\" type=\"button\">${btnDownload}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=delDetailLog'\" type=\"button\">${btnDelLog}</button> "
        fi  
      fi
    	echo "</p>
        </body>
      </html>"
fi # if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]
logInfoNoEcho 3 "$(basename "$0") done"
exit

