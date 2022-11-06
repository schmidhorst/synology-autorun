#!/bin/bash
# Filename: parse_language.sh - coded in utf-8

#                SPKdevDSM7
#
#        Copyright (C) 2022 by Tommes 
# Member of the German Synology Community Forum
#             License GNU GPLv3
#   https://www.gnu.org/licenses/gpl-3.0.html

# Spracheinstellungen konfigurieren
# --------------------------------------------------------------

#********************************************************************#
#  Description: Script get the current used dsm language             #
#  Author 1:    QTip from the german Synology support forum          #
#  Copyright:   2016-2018 by QTip                                    #
#  Author 2:    Modified 2022 by Tommes                              #
#  Author 3:    Horst Schmid, 2022                                   #
#  License:     GNU GPLv3                                            #
#  ----------------------------------------------------------------  #
#  Version:     2022-11-06                                           #
#********************************************************************#
bDebugPL=0
# DSM language
gui_lang=$(/bin/get_key_value /etc/synoinfo.conf language)
mail_lang=$(/bin/get_key_value /etc/synoinfo.conf maillang) # e.g. ger, global setting, not individual user!
if [[ -n "$1" ]]; then
  user="$1" # should be the logged-in user
else
  user=$(whoami) # EnvVar $USER may be not well set (whoami may be <appName>)
fi
if [[ -z "$SCRIPT_NAME" ]]; then  # direct start in debug run
  app_name="autorun" 
  SCRIPT_NAME="/webman/3rdparty/autorun"
  echo "parse_language.sh started and switched to debug mode ..."
  bDebugPL=1
else
  app_link=${SCRIPT_NAME%/*} # "/webman/3rdparty/<appName>"
  app_name=${app_link##*/} # "<appName>"
fi

LOG="/var/log/tmp/${app_name}.log"
echo "$(date '+%Y-%m-%d %H:%M:%S'): parse_language.sh started ..." >> "$LOG"
if [[ $bDebugPL -eq 1 ]]; then
  echo "see $LOG" 
fi
# userpreferencePathName="$(/bin/get_key_value /etc/synoinfo.conf userpreference_realpath)/$user/usersettings" # "/volume1/@userpreference/<user>/usersettings"
# # contains ...},"Personal":{"dateFormat":"Y-m-d","lang":"def","timeFormat":"H:i"}...
# # even if we have had ${login_result} != "success" in showlog.cgi, then still no access!
# if [[ -f "$userpreferencePathName" ]]; then
#   offs1=$(grep -b -o '},"Personal":{' "$userpreferencePathName")
#   echo "User Language is at about $offs1 in $userpreferencePathName" >> "$LOG"
#   offs1=${offs1%%:*}
#   offs2=$(( offs1 + 75 ))
#   str=$(cut -b "$offs1-$offs2" "$userpreferencePathName")
#   echo "User Language is in '$str'" >> "$LOG"
#   user_lng=${str#*lang\":\"}
#   user_lng=${user_lng%\"*}
# else
#   echo "UserPreferences file '$userpreferencePathName' not found / not accessible " >> "$LOG"
# fi
declare -A ISO2SYNO
ISO2SYNO=( ["de"]="ger" ["en"]="enu" ["zh"]="chs" ["cs"]="csy" ["jp"]="jpn" ["ko"]="krn" ["da"]="dan" ["fr"]="fre" ["it"]="ita" ["nl"]="nld" ["no"]="nor" ["pl"]="plk" ["ru"]="rus" ["sp"]="spn" ["sv"]="sve" ["hu"]="hun" ["tr"]="trk" ["pt"]="ptg" )
declare -A SYNO2ISO
SYNO2ISO=( ["ger"]="de" ["enu"]="en" ["chs"]="zh" ["csy"]="cs" ["jpn"]="jp" ["krn"]="ko" ["dan"]="da" ["fre"]="fr" ["ita"]="it" ["nld"]="nl" ["nor"]="no" ["plk"]="pl" ["rus"]="ru" ["spn"]="sp" ["sve"]="sv" ["hun"]="hu" ["trk"]="tr" ["ptg"]="pt" )

if [[ -n "$SYNOPKG_DSM_LANGUAGE" ]]; then
  pkg_lng="$SYNOPKG_DSM_LANGUAGE"
fi
if [[ -n "${LANG}" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): env LANG='$LANG'" >> "$LOG"
  env_lng="${LANG:0:2}"
  env_lng=${ISO2SYNO[$env_lng]}
fi

if [ -n "${HTTP_ACCEPT_LANGUAGE}" ] ; then  # e.g. 'de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7'
  echo "$(date '+%Y-%m-%d %H:%M:%S'): env http='${HTTP_ACCEPT_LANGUAGE}'" >> "$LOG"
  bl=$(echo "${HTTP_ACCEPT_LANGUAGE}" | cut -d "," -f1)
  bl=${bl:0:2}
  http_lang="${ISO2SYNO[${bl}]}" # may be different from actual user language, most probably it's the DSM GUI language
  # missing: if no SYNO-Language for extracted language, try the next language in the list
  # missing: if no folder texts/${http_lang}, then try the next language
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): env_LANG='$env_lng', httpLng='$http_lang', mailLng='$mail_lang', dsmGuiLng='$gui_lang', pkg_lng='$pkg_lng'" >> "$LOG"

# set >> "$LOG"

if [[ -n "$pkg_lng" ]] && [[ "$pkg_lng" != "def" ]] && [[ -n "$pkg_lng" ]]; then
  used_lang=$pkg_lng # n.a.
elif [[ -n "$env_lng" ]] && [[ "$env_lng" != "def" ]] && [[ -n ${SYNO2ISO["$env_lng"]} ]]; then
  used_lang="$env_lng"  # n.a.
elif [[ -n "$http_lang" ]]; then
  used_lang="$http_lang" # ger for user=ger
elif [[ -n "$mail_lang" ]]; then
  used_lang="$mail_lang" # ger for user=ger
else
  used_lang="enu"
fi  

if [[ -n "$LOG" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Selected Language '$used_lang'" >> "$LOG"
fi  

lngFile="texts/${used_lang}/lang.txt"
if [ ! -f "$lngFile" ]; then
  if [[ -n "$LOG" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): File '$lngFile' is missing, selecting 'enu'" >> "$LOG"
  fi  
  used_lang="enu"
  lngFile="texts/enu/lang.txt"
fi
# echo 'before source "$lngFile"'
source "$lngFile"
# echo 'after source "$lngFile"'
# setup $fingerprint0, $fingerprint1count0, $fingerprint1count1, $fingerprint2, ...
res=$?
if [[ -n "$LOG" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Result from 'source $lngFile' is '$res'" >> "$LOG"
  if [[ "$res" -ne 0 ]]; then
    # dsmnotify
    echo "$result" >> "$LOG"
  fi  
fi

if [[ "$res" -ne 0 ]] && [[ "$used_lang" != "enu" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Failed to load $lngFile: res=$res" >> "$LOG"
  if [[ $bDebugPL -eq 1 ]]; then 
    echo "not enu"
  fi  
  lngFile="texts/enu/lang.txt"
  source "$lngFile"
  res=$?
  if [[ -n "$LOG" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Result from 'source $lngFile' is '$res'" >> "$LOG"
    if [[ "$res" -ne 0 ]]; then
      # dsmnotify
      echo "$result" >> "$LOG"
    fi  
  fi  
else
  if [[ $bDebugPL -eq 1 ]]; then 
    echo "enu"
  fi  
fi  
if [[ $bDebugPL -eq 1 ]]; then
  echo "... parse_language.sh done with res=$res" 
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): ... parse_language.sh done, lng= with res=$res" >> "$LOG"


