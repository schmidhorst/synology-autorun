#!/bin/bash
# $SYNOPKG_PKGNAME is available if pre-processing was well done! 
LOG="/var/log/tmp/autorun.log"
DTFMT="+%Y-%m-%d %H:%M:%S"
user=$(whoami)
echo "$(date "$DTFMT"): Start of $0 to put values from config file (if available) to '$SYNOPKG_TEMP_LOGFILE', which replaces install_uifile (as $user)" >> "$LOG"
if [[ -z "$SYNOPKG_PKGNAME" ]]; then
  LOG="/var/log/tmp/autorun.log"
  echo "$(date "$DTFMT"): Error: SYNOPKG_PKGNAME is not set in install_uifile.sh !!!???" >> "$LOG"
else
  LOG="/var/log/tmp/$SYNOPKG_PKGNAME.log"
  echo "$(date "$DTFMT"): install_uifile.sh SYNOPKG_PKGNAME is available: '$SYNOPKG_PKGNAME'" >> "$LOG"
fi

# userpreferencePathName="$(/bin/get_key_value /etc/synoinfo.conf userpreference_realpath)/$user/usersettings" # "/volume1/@userpreference/<user>/usersettings"
# contains ...},"Personal":{"dateFormat":"Y-m-d","lang":"def","timeFormat":"H:i"}...
# but is not accessible
if [[ -n "$SYNOPKG_DSM_LANGUAGE" ]]; then
  lng="$SYNOPKG_DSM_LANGUAGE"
  echo "$(date "$DTFMT"): from environment: '$lng'" | tee -a "$LOG"
else
  declare -A ISO2SYNO
  ISO2SYNO=( ["de"]="ger" ["en"]="enu" ["zh"]="chs" ["cs"]="csy" ["jp"]="jpn" ["ko"]="krn" ["da"]="dan" ["fr"]="fre" ["it"]="ita" ["nl"]="nld" ["no"]="nor" ["pl"]="plk" ["ru"]="rus" ["sp"]="spn" ["sv"]="sve" ["hu"]="hun" ["tr"]="trk" ["pt"]="ptg" )
  if [[ -n "${LANG}" ]]; then
    env_lng="${LANG:0:2}"
    lng=${ISO2SYNO[$env_lng]}
  fi  
fi
if [[ -z "$lng" ]]; then
  lng="enu"
  echo "$(date "$DTFMT"): No language in environment found, using 'enu'" >> "$LOG"
fi
if [[ -f "$(dirname "$0")/wizard_$lng.json" ]]; then
  JSON="$(dirname "$0")/wizard_$lng.json"
else
  JSON="$(dirname "$0")/wizard_enu.json"
fi
if [ ! -f "$JSON" ]; then
  echo "$(date "$DTFMT"): ERROR 11: WIZARD template file '$JSON' not available!" | tee -a "$LOG"
  echo "[]" >> "$SYNOPKG_TEMP_LOGFILE"
  echo "                              No install_uifile ($$SYNOPKG_TEMP_LOGFILE) generated (only empty file)" >> "$LOG"
  exit 11 # should we use exit 0 ?
fi
echo "$(date "$DTFMT"): WIZARD template file available" >> "$LOG"
configFilePathName="/var/packages/$SYNOPKG_PKGNAME/var/config"
if [ ! -f "$configFilePathName" ]; then
  configFilePathName="/var/packages/$SYNOPKG_PKGNAME/target/config"  # old version used config in this folder  
fi
if [ ! -f "$configFilePathName" ]; then
  configFilePathName="$(dirname "$0")/initial_config.txt"
fi
echo "$(date "$DTFMT"): Used config file: '$configFilePathName'" >> "$LOG"

cat "$JSON" >> "$SYNOPKG_TEMP_LOGFILE"
fields="SCRIPT SCRIPT_AFTER_EJECT ADD_NEW_FINGERPRINTS TRIES WAIT BEEP LED LED_COPY EJECT_TIMEOUT LOG_MAX_LINES NOTIFY_USERS"
msg=""
for f1 in $fields; do
  line=$(grep "^$f1=" "$configFilePathName")
  if [[ -z "$line" ]]; then # new item in this version
    line=$(grep "^$f1=" "$(dirname "$0")/initial_config.txt")  
  fi
  eval $line
  sed -i -e "s|@${f1}@|${!f1}|g" "$SYNOPKG_TEMP_LOGFILE" # replace placeholder by value in upgrade_uifile
  msg="$msg, $f1='${!f1}'"
done
echo "$(date "$DTFMT"): Found settings: $msg" >> "$LOG"      

ENTRY_COUNT=0
if [ -f "${SYNOPKG_PKGVAR}/FINGERPRINTS" ]; then
  ENTRY_COUNT=$(wc -l < "${SYNOPKG_PKGVAR}/FINGERPRINTS")
fi
sed -i -e "s|@ENTRY_COUNT@|$ENTRY_COUNT|g" "$SYNOPKG_TEMP_LOGFILE"

# Fill ComboBox with the configured scheduled Tasks:
# not possible as the command $(synoschedtask --get) is not working as actual user = $SYNOPKG_PKGNAME

echo "$(date "$DTFMT"): Values from config and TaskSchedulerList put to template and copied to '$SYNOPKG_TEMP_LOGFILE'" >> "$LOG"
echo "$(date "$DTFMT"): ... $0 done" >> "$LOG"
exit 0

