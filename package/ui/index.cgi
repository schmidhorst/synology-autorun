#!/bin/bash
# Filename: index.cgi - coded in utf-8
#    taken from
#  DSM7DemoSPK (https://github.com/toafez/DSM7DemoSPK)
#        Copyright (C) 2022 by Tommes
# Member of the German Synology Community Forum

# Adopted to need of Autorun by Horst Schmid
#      Copyright (C) 2022...2023 by Horst Schmid

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
bDebug=0 # 0= do cgiLogin, evaluateCgiLogin; 1= skip cgiLogin, evaluateCgiLogin
if [[ -z "$SCRIPT_NAME" ]]; then  # direct start in debug run
  SCRIPT_NAME="/webman/3rdparty/autorun/index.cgi"
  bDebug=1
  echo "###### index.cgi executed in debug mode!!  ######"
fi
# ${BASH_SOURCE[0]}=/usr/syno/synoman/webman/3rdparty/<appName>/index.cgi
app_link=${SCRIPT_NAME%/*} # "/webman/3rdparty/<appName>"
app_name=${app_link##*/} # "<appName>"
# DOCUMENT_URI=/webman/3rdparty/<appName>/index.cgi
# PWD=/volume1/@appstore/<appName>/ui
user=$(whoami) # EnvVar $USER may be not well set, user is '<appName>'
# REQUEST_URI=/webman/3rdparty/<appName>/index.cgi
# SCRIPT_FILENAME=/usr/syno/synoman/webman/3rdparty/<appName>/index.cgi

if [[ -w "/var/log/packages/${app_name}.log" ]]; then
  LOG="/var/log/packages/${app_name}.log"
elif [[ -w "/var/tmp/${app_name}.log" ]]; then
  LOG="/var/tmp/${app_name}.log"  # no permission if default -rw-r--r-- root:root was not changed
fi
#line="$(grep -i "DEBUGLOG=" "/var/packages/$app_name/var/config")"
#if [[ -n "$line" ]]; then # entry available
#  LOG="$(echo "$line" | sed -e 's/^DEBUGLOG="//' -e 's/"$//')"
#fi
DTFMT="+%Y-%m-%d %H:%M:%S" # may be overwritten by parse_hlp
# $SHELL' is here "/sbin/nologin"
msg1="App '$app_name' file '$(basename "${BASH_SOURCE[0]}")' started as user '$user' with parameters '$QUERY_STRING' ..."
ah="/volume*/@appstore/$app_name/ui"
app_home=$(find $ah -maxdepth 0 -type d) # Attention: find is not working with quoted path!!
# env >> LOG"
# Load urlencode and urldecode, logInfoNoEcho, ... function from ../modules/parse_hlp.sh:
if [ -f "${app_home}/modules/parse_hlp.sh" ]; then
  source "${app_home}/modules/parse_hlp.sh" # includes reading of LOGLEVEL from config file
  res=$?
  # echo "$(date "$DTFMT"): $msg1<br>Loading ${app_home}/modules/parse_hlp.sh with functions urlencode() and urldecode() done with result $res" >> "$LOG"
  if [[ "$res" -gt 1 ]]; then
    echo "### Loading ${app_home}/modules/parse_hlp.sh failed!! res='$res' ###" >> "$LOG"
    exit
  fi
else
  echo "$(date "$DTFMT"): $msg1<br>Failed to find ${app_home}/modules/parse_hlp.sh with functions urlencode() and urldecode() skipped" >> "$LOG"
  echo -e "$msg1\nFailed to find ${app_home}/modules/parse_hlp.sh"
  exit
fi
logInfoNoEcho 8 "$msg1"
if [[ "$app_name" == "ui" ]]; then
  logInfoNoEcho 1 "wrong app_name='$app_name'"
fi
if [[ -f "/var/packages/$app_name/var/config" ]]; then
  # should the execution of *.cgi write debug log entries? If looking for other bugs that is confusing and therefore can be disabled
  CGIDEBUG="$(grep "CGIDEBUG=" "/var/packages/$app_name/var/config" | sed -e 's/^CGIDEBUG="//' -e 's/"$//')"
  logInfoNoEcho 8 "CGIDEBUG='$CGIDEBUG' from '/var/packages/$app_name/var/config' fetched!"
else
  logInfoNoEcho 8 "File '/var/packages/$app_name/var/config' is not available!"
fi
# Evaluate app authentication
# To evaluate the SynoToken, change REQUEST_METHOD to GET
# Read out and check the login authorization  ( login.cgi )
if [[ "$bDebug" -eq 0 ]]; then
  cgiLogin # see parse_hlp.sh, sets $syno_login, $syno_token, $syno_user, $is_admin
  # this may fail with permission denied and result 3
  ret=$?
  if [[ "$ret" -ne "0" ]]; then
    echo "$(date "$DTFMT"): $(basename "${BASH_SOURCE[0]}"), calling cgiLogin failed, ret='$ret' " >> "$LOG"
    # exit
  fi
else
  echo "Due to debug mode login skipped"
fi

# get the installed version of the package for later comparison to latest version on github:
local_version=$(cat "/var/packages/${app_name}/INFO" | grep ^version | cut -d '"' -f2)

if [ -x "${app_home}/modules/parse_language.sh" ]; then
  source "${app_home}/modules/parse_language.sh" "${syno_user}"
  res=$?
  logInfoNoEcho 8 "Loading ${app_home}/modules/parse_language.sh done with result $res"
  # || exit
else
  logInfoNoEcho 1 "Loading ${app_home}/modules/parse_language.sh failed"
  exit
fi
# ${used_lang} is now setup, e.g. enu

# Resetting access permissions
unset syno_login rar_data syno_privilege syno_token user_exist is_authenticated
declare -A get # associative array for parameters (POST, GET)

# Evaluate app authentication
if [[ "$bDebug" -eq 0 ]]; then
  evaluateCgiLogin # in parse_hlp.sh
  ret=$?
  if [[ "$ret" -ne "0" ]]; then
    logInfoNoEcho 1 "$(basename "${BASH_SOURCE[0]}"), execution of evaluateCgiLogin failed, ret='$ret'"
    exit
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
  logInfoNoEcho 1 "Admin Login required!"
  echo "Admin Login required!"
  exit 0
fi

#appCfgDataPath=$(find /volume*/@appdata/${app_name} -maxdepth 0 -type d)
appCfgDataPath="/var/packages/${app_name}/var"
if [ ! -d "${appCfgDataPath}" ]; then
  logInfoNoEcho 1 "... terminating $(basename "${BASH_SOURCE[0]}") as app home folder '$appCfgDataPath' not found!"
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
# get_request="$app_temp/get_request.txt"

# If no page set, then show home page
#if [ -z "${get[page]}" ]; then
#  logInfoNoEcho 6 "generating file $get_request ..." # /volume1/@appstore/autorun/ui/temp/get_request.txt
#  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[page]" "main"  # write and read an .ini style file with lines of key=value pairs
#  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[section]" "start"
#  /usr/syno/bin/synosetkeyvalue "${get_request}" "get[SynoToken]" "$syno_token"
#fi

# Processing GET/POST request variables
# CONTENT_LENGTH: CGI meta variable https://stackoverflow.com/questions/59839481/what-is-the-content-length-varaible-of-a-cgi

SCRIPT_EXEC_LOG="$appCfgDataPath/execLog"
logfile="$SCRIPT_EXEC_LOG" # default, later optionally set to "$appCfgDataPath/detailLog"
pageTitle=$(echo "$logTitleExec")  # default, later optionally set to "$logTitleDetail"

# Analyze incoming POST requests and process them to ${get[key]}="$value" variables
cgiDataEval # parse_hlp.sh, setup associative array get[] from the request (POST and GET)

versionUpdateHint=""
githubRawInfoUrl="https://raw.githubusercontent.com/schmidhorst/synology-autorun/main/INFO.sh" #patched to distributor_url from INFO.sh
 # above line will be patched from INFO.sh and is used to check for a newer version
if [[ -n "$githubRawInfoUrl" ]]; then
  git_version=$(wget --timeout=30 --tries=1 -q -O- "$githubRawInfoUrl" | grep ^version | cut -d '"' -f2)
  logInfoNoEcho 6 "local_version='$local_version', git_version='$git_version'"
  if [ -n "${git_version}" ] && [ -n "${local_version}" ]; then
    if dpkg --compare-versions "${git_version}" gt "${local_version}"; then
    # if dpkg --compare-versions ${git_version} lt ${local_version}; then # for debugging
      vh=$(echo "$update_available")
      versionUpdateHint='<p style="text-align:center">'${vh}' <a href="https://github.com/schmidhorst/synology-'${app_name}'/releases" target="_blank">'${git_version}'</a></p>'
    fi
  fi
fi

if [[ "$bDebug" -eq 1 ]]; then
  logfile="/var/tmp/$app_name"  # optionally to debug behaviour for the debug log instead of action log
fi

myScript="<script>
 function setBoxHeight() { var h0=window.innerHeight; var o1=document.getElementById('mybox'); var h1=o1.style.height; var t1=o1.getBoundingClientRect().top; h2=h0 - t1- 65; o1.style.height = h2+'px'; }"
if [[ -n "${get[action]}" ]]; then
  val="${get[action]}"
  if [[ "$val" == "showDetailLog" ]] || [[ "$val" == "delDetailLog" ]] || [[ "$val" == "reloadDetailLog" ]] || [[ "$val" == "downloadDetailLog" ]] || [[ "$val" == "chgDetailLogLevel" ]] || [[ "$val" == "SupportEMail" ]] || [[ "$bDebug" -eq 1 ]]; then
    # logfile="/var/tmp/$app_name" # this is not working ! But LOG="/var/tmp/${app_name}.log" works !????
    logfile="$appCfgDataPath/detailLog"  # Link to /var/tmp/autorun.log
    pageTitle=$(echo "$logTitleDetail") # with actual LOGLEVEL, which was feteched in parse_hlp.sh
  fi
  if [[ "$val" == "delSimpleLog" ]] || [[ "$val" == "delDetailLog" ]]; then
    echo "" > "$logfile"
    logInfoNoEcho 4 "Old content of '$logfile' removed"
  fi
  if [[ "$val" == "SupportEMail" ]]; then # net yet working, not yet used!

    # https://community.synology.com/enu/forum/10/post/135979

    # not yet working:
    if [[ "${REQUEST_METHOD}" == "GET" ]]; then
      OLD_REQUEST_METHOD="GET"
      REQUEST_METHOD="POST"
    fi

    echo "Content-type: text/html; charset=utf-8"
    echo
    echo "<!doctype html><html lang=\"${SYNO2ISO[${used_lang}]}\"><head>"
    echo '<meta charset="utf-8" /><link rel="shortcut icon" href="images/icon_32.png" type="image/x-icon" />
          <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
          <link rel="stylesheet" type="text/css" href="dsm3.css"/></head><body>'
    echo "<p>Please describe your problem in Englisch or German language in the generated E-Mail</p>"
    echo '<p><a target="_blank" rel="noopener noreferrer" href="mailto:synoapps@schmidhorst.de?subject=Autorun&body='
    echo "Not yet working!"
    # urlencode "$(cat "$logfile")"
    #echo ""
    # urlencode "$(env)"
    #echo ""
    # urlencode "$(cat "$SCRIPT_EXEC_LOG")"
    echo '">Generate Email</a></p></body>'

    # Set REQUEST_METHOD back to GET again:
    if [[ "${OLD_REQUEST_METHOD}" == "POST" ]]; then
      REQUEST_METHOD="GET"
      unset OLD_REQUEST_METHOD
    fi
    exit
  fi
  if [[ "$val" == "downloadSimpleLog" ]] || [[ "$val" == "downloadDetailLog" ]]; then
    logInfoNoEcho 4 "Download content of '$logfile' requested, disposition='$disposition'"
    echo "Content-type: text/plain; charset=utf-8"
    echo "Content-Disposition: attachment; filename=$(basename "$logfile").txt"
    echo
    # echo "<!doctype html>"
    cat "$logfile"
    if [[ "$val" == "downloadDetailLog" ]]; then
      echo -e "\n"
      env || printenv
      echo ""
      # lets append the content of $SCRIPT_EXEC_LOG for full debug info:
      cat "$SCRIPT_EXEC_LOG"
    fi
    exit
  fi # if [[ "$val" == "downloadSimpleLog" ]] || [[ "$val" == "downloadDetailLog" ]]

  if [[ "$val" == "chgDetailLogLevel" ]]; then # also CGIDEBUG on/off
    newlevel=$(echo "${get[logNewlevel]}" | grep "[1-8]")
    if [[ -n "$newlevel" ]]; then
      if [[ -f "$appCfgDataPath/config" ]]; then
        res="$(sed -i "s|^LOGLEVEL=.*$|LOGLEVEL=\"$newlevel\"|" "$appCfgDataPath/config")"
        result=$?
        logInfoNoEcho 4 "index.cgi LogLevel set to '$newlevel' in file '$appCfgDataPath/config': result='$result', res='$res'"
        LOGLEVEL="$newlevel"
        # $logTitleDetail and pageTitle has still old loglevel:
     	  eval "$(grep "logTitleDetail=" "$lngFile")" # lngfile was set in parse_language.sh to texts/${used_lang}/lang.txt
        pageTitle="$logTitleDetail"
      fi
    fi
    newCgi=$(echo "${get[cgiDebug]}")
    if [[ -z "$newCgi" ]]; then
      newCgi=""
    else
      newCgi="checked"
    fi
    line="$(grep -i "CGIDEBUG=" "$appCfgDataPath/config")"
    if [[ -z "$line" ]]; then # generate a new entry:
      echo "CGIDEBUG=\"$newCgi\"" >> "$appCfgDataPath/config"
    else # change the existing line:
      res="$(sed -i "s|^CGIDEBUG=.*$|CGIDEBUG=\"$newCgi\"|" "$appCfgDataPath/config")"
      result=$?      
    fi
    logInfoNoEcho 4 "CGIDEBUG set to '$newCgi' in file '$appCfgDataPath/config'"
    CGIDEBUG="$newCgi"
  fi # if [[ "$val" == "chgDetailLogLevel" ]]
  if [[ "$val" == "reloadSimpleLog" ]] || [[ "$val" == "reloadDetailLog" ]]; then
    logInfoNoEcho 7 "Page reload"
    #myScript="${myScript} window.onload=function(){ window.scrollTo(0, document.body.scrollHeight);}"  # scroll to bottom

# https://stackoverflow.com/questions/17642872/refresh-page-and-keep-scroll-position
# not working:
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

if [[ "${get[action]}" == "reloadSimpleLog" ]] || [[ "${get[action]}" == "reloadDetailLog" ]]; then
  myScript="${myScript}
    function myLoad() { setBoxHeight(); var o1=document.getElementById('mybox'); var sy=o1.scrollHeight; if (!!sy) {o1.scrollTo(0, sy);} else {alert('ScrollY null');} } "
else
  myScript="${myScript}
   function myLoad() { setBoxHeight(); var o1=document.getElementById('mybox'); var sy=o1.scrollHeight; if (!!sy) {o1.scrollTo(0, sy);} else {alert ('ScrollY null')} }"
fi

if [[ "$logfile" == "$appCfgDataPath/detailLog" ]]; then
  pageTitle=$(echo "$logTitleDetail") # read it again and insert the changed LOGLEVEL
fi

# Inclusion of the temporarily stored GET/POST requests ( key="value" ) as well as the user settings
# [ -f "${get_request}" ] && source "${get_request}"
# [ -f "${post_request}" ] && source "${post_request}"

linkTarget="$(readlink "$logfile")" # result 1 if it's not a link
if [[ "$?" -eq "0" ]]; then
  filesize_Bytes=$(stat -c%s "$linkTarget")
  lineCount=$(wc -l < "$linkTarget")
else
  filesize_Bytes=$(stat -c%s "$logfile")  # if it's a link this returns size of the link, not of linked file!
  lineCount=$(wc -l < "$logfile")
fi
myScript="$myScript </script>"
logInfoNoEcho 8 "Size of $logfile is $lineCount lines, $filesize_Bytes Bytes"
# Layout output
# --------------------------------------------------------------
if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]; then
  echo "Content-type: text/html; charset=utf-8"
  echo ""
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
  echo "$myScript"
  echo '</head>
    <body onload="myLoad()" onresize="setBoxHeight()">
      <header>'
  echo "$versionUpdateHint"
        # Load page content
        # --------------------------------------------------------------
        if [[ "$is_admin" == "yes" ]]; then
          # HTTP GET and POST requests
          if [[ "$logfile" == "$SCRIPT_EXEC_LOG" ]]; then
            echo "<button onclick=\"location.href='index.cgi?action=showDetailLog'\" type=\"button\">${btnShowDetailLog}</button> "
          else
            echo "<button onclick=\"location.href='index.cgi'\" type=\"button\">${btnShowSimpleLog}</button> "
          fi
          echo "<button onclick=\"location.href='settings.cgi'\" type=\"button\">${btnShowSettings}</button> "
          echo "<button onclick=\"location.href='$licenceFile'\" type=\"button\">${btnShowLicence}</button> "
# https://stackoverflow.com/questions/21168521/table-fixed-header-and-scrollable-body
# https://www.quackit.com/html/codes/html_scroll_box.cfm
# https://www.w3schools.com/jsref/prop_win_innerheight.asp
          echo "<p><strong>$pageTitle</strong></p>"
          echo "</header>"
          echo "<div id='mybox' style='height:360px;width:100%;overflow:auto;'><table>"

          if [[ -f "$logfile" ]]; then
            if [[ filesize_Bytes -lt 10 ]]; then
              msg=$(echo "$execLogNA")
              echo "<tr><td>$msg</td></tr>"
            else
              while IFS=$'\n' read -r line; do # read all items from logfile
                # split the line now at an tab character (default) or at ": " (if no tab char found, old/obsolete)
                rest1="${line#*: }"
                # rest2="${line#*\t}" not working
                rest2=$(sed 's/[^\t]*\t//' <<<"$line")
                p1=$((${#line} - ${#rest1} - 2 ))
                p2=$((${#line} - ${#rest2} - 1 ))
                if [[ "$p1" -lt 0 ]]; then p1="9999"; fi
                if [[ "$p2" -lt 0 ]]; then p2="9999"; fi
                if [[ "$p1" -eq 9999 ]] && [[ "$p2" -eq 9999 ]]; then
                  timestamp=""  # neither tab char nor ': ' found ==> put all to 2nd column
                  msg="$line"
                else
                  # split line to two columns:
                  if [[ "$p1" -gt "$p2" ]]; then # use TAB
                    p1="$p2"
                    p2=$((p1+1))
                  else
                    p2=$((p1+2))
                  fi
                  timestamp="${line:0:p1}"
                  msg="${line:p2}"
                fi
                #if [[ "$msg" == "$timestamp" ]]; then # no ": "
                #  timestamp="" # put all to 2nd column
                #fi
                echo "<tr><td>$timestamp</td><td>$msg</td></tr>"
              done < "$logfile" # Works well even if last line has no \n!
            fi # if [[ filesize_Bytes -lt 10 ]]; else
          else
            logInfoNoEcho 3 "'$logfile' not found!"
            logInfoNoEcho 8 "execLogNA='$execLogNA'"
            msg=$(echo "$execLogNA")
            echo "<tr><td>$msg</td></tr>"
          fi # if [[ -f "$logfile" ]] else
        else
          # Infotext: Access allowed only for users from the Administrators group
          echo '<p>'${txtAlertOnlyAdmin}'</p>'
        fi # if [[ "$is_admin" == "yes" ]] else
        echo '</table></div>'
      logInfoNoEcho 8 "Table with log entries done, generating footer ..."
      echo '<p style="margin-left:22px; line-height: 16px;">'
      if [[ "$logfile" == "$SCRIPT_EXEC_LOG" ]]; then
        echo "<button onclick=\"location.href='index.cgi?action=reloadSimpleLog'\" type=\"button\">${btnRefresh}</button> "
        if [[ filesize_Bytes -gt 10 ]]; then
          echo "<button onclick=\"location.href='index.cgi?action=downloadSimpleLog'\" type=\"button\">${btnDownload}</button> "
          echo "<button onclick=\"location.href='index.cgi?action=delSimpleLog'\" type=\"button\">${btnDelLog}</button> "
        fi # if [[ filesize_Bytes -gt 10 ]]
      else # detailed debug log: Allow to change the LOGLEVEL:
        echo "<form action='index.cgi?action=chgDetailLogLevel' method='post'>
              <label for='fname'>LogLevel:</label>
              <select name='logNewlevel' id='logNewlevel'>"
        for ((i=1; i<=8; i+=1)); do
          if [[ "$i" -eq "$LOGLEVEL" ]]; then
            echo "<option selected>$i</option>"
          else
            echo "<option>$i</option>"
          fi
        done
        echo "</select>"
        echo "<label for='cgiDebug'>  CGI debug:</label>"
        # Hint: unchecked checkbox is not included in the response!! 
        logInfoNoEcho 7 "using CGIDEBUG='$CGIDEBUG' for the form"
        echo "<input type='checkbox' id='cgiDebug' name='cgiDebug' value='CGIDEBUG' $CGIDEBUG>" # checked checkbox overwrites value
        echo "<input type='submit' value='Submit'>&nbsp;&nbsp;&nbsp;"
        # also inside the <form ...> to have it in the same row:
        echo "<button onclick=\"location.href='index.cgi?action=reloadDetailLog'\" type=\"button\">${btnRefresh}</button>&nbsp;  "
        if [[ filesize_Bytes -gt 10 ]]; then
          echo "<button onclick=\"location.href='index.cgi?action=downloadDetailLog'\" type=\"button\">${btnDownload}</button>&nbsp; "
          echo "<button onclick=\"location.href='index.cgi?action=delDetailLog'\" type=\"button\">${btnDelLog}</button> "
          # echo "<button onclick=\"location.href='index.cgi?action=SupportEMail'\" type=\"button\">Send Support-eMail</button> "
        fi # if [[ filesize_Bytes -gt 10 ]]
        echo "</form>"

      fi # if [[ "$logfile" == "$SCRIPT_EXEC_LOG" ]] else
      echo "</p>
        </body>
      </html>"
fi # if [ $(synogetkeyvalue /etc.defaults/VERSION majorversion) -ge 7 ]
logInfoNoEcho 4 "... $(basename "${BASH_SOURCE[0]}") done"
exit

