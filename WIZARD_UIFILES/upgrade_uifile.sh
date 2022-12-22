#!/bin/bash
LOG="/var/tmp/$SYNOPKG_PKGNAME.log"
DTFMT="+%Y-%m-%d %H:%M:%S"
user=$(whoami)
echo "$(date "$DTFMT"): Start of $0 to put values from config file to $SYNOPKG_TEMP_LOGFILE, which replaces upgrade_uifile (as $user)" >> "$LOG"

if [[ -n "$SYNOPKG_DSM_LANGUAGE" ]]; then
  lng="$SYNOPKG_DSM_LANGUAGE" # lng of actual user
  echo "$(date "$DTFMT"): from environment SYNOPKG_DSM_LANGUAGE: '$lng'" | tee -a "$LOG" # normally available, lng of actual user
else
  declare -A ISO2SYNO
  ISO2SYNO=( ["de"]="ger" ["en"]="enu" ["zh"]="chs" ["cs"]="csy" ["jp"]="jpn" ["ko"]="krn" ["da"]="dan" ["fr"]="fre" ["it"]="ita" ["nl"]="nld" ["no"]="nor" ["pl"]="plk" ["ru"]="rus" ["sp"]="spn" ["sv"]="sve" ["hu"]="hun" ["tr"]="trk" ["pt"]="ptg" )
  if [[ -n "${LANG}" ]]; then
    env_lng="${LANG:0:2}"
    lng=${ISO2SYNO[$env_lng]}
  fi  
fi
if [[ -z "$lng" ]] || [[ "$lng" == "def" ]]; then
  lng="enu"
  echo "$(date "$DTFMT"): No language in environment found, using 'enu'" >> "$LOG"
fi

JSON="$(dirname "$0")/wizard_$lng.json"
if [[ ! -f "$JSON" ]]; then # no translation to the actual language available
  JSON=$(dirname "$0")/wizard_enu.json # using English version
fi  
if [ ! -f "$JSON" ]; then
  echo "$(date "$DTFMT"): ERROR 11: WIZARD template file '$JSON' not available!" | tee -a "$LOG"
  echo "[]" >> "$SYNOPKG_TEMP_LOGFILE"
  echo "$(date "$DTFMT"): No upgrade_uifile ($$SYNOPKG_TEMP_LOGFILE) generated (only empty file)" >> "$LOG"
  exit 11 # should we use exit 0 ?
fi
echo "$(date "$DTFMT"): WIZARD template file available" >> "$LOG"
configFilePathName="/var/packages/$SYNOPKG_PKGNAME/var/config"
if [ ! -f "$configFilePathName" ]; then
  configFilePathName="/var/packages/$SYNOPKG_PKGNAME/target/config"  # old version used config in this folder  
fi
if [ ! -f "$configFilePathName" ]; then
  echo "$(date "$DTFMT"): ERROR 12: Old configuration not available!" | tee -a "$LOG"
  echo "[]" >> "$SYNOPKG_TEMP_LOGFILE"
  echo "$(date "$DTFMT"): No upgrade_uifile ($$SYNOPKG_TEMP_LOGFILE) generated (only empty file)" >> "$LOG"
  exit 12
fi
echo "$(date "$DTFMT"): Used config file: '$configFilePathName'" >> "$LOG"

cat "$JSON" >> "$SYNOPKG_TEMP_LOGFILE"
fields="SCRIPT SCRIPT_AFTER_EJECT ADD_NEW_FINGERPRINTS TRIES WAIT BEEP LED LED_COPY EJECT_TIMEOUT LOG_MAX_LINES NOTIFY_USERS NO_DSM_MESSAGE_RETURN_CODES LOGLEVEL"
msg=""
for f1 in $fields; do
  line=$(grep "^$f1=" "$configFilePathName")
  # echo "$(date "$DTFMT"): Item '$f1' line from $configFilePathName: '$line' " >> "$LOG"
  if [[ -z "$line" ]]; then # new item in this version
    line=$(grep "^$f1=" "$(dirname "$0")/initial_config.txt")  
    echo "$(date "$DTFMT"): Item '$f1' line from initial_config.txt: '$line' " >> "$LOG"
    eval "$line"
    msg="$msg, $f1='${!f1}' (initial value)"
  else
    eval "$line"
    msg="$msg, $f1='${!f1}' (previously configured)"    
  fi
  sed -i -e "s|@${f1}@|${!f1}|g" "$SYNOPKG_TEMP_LOGFILE" # replace placeholder by value in upgrade_uifile
done
echo "$(date "$DTFMT"): Found settings: $msg" >> "$LOG"      

ENTRY_COUNT=0
if [ -f "${SYNOPKG_PKGVAR}/FINGERPRINTS" ]; then
  ENTRY_COUNT=$(wc -l < "${SYNOPKG_PKGVAR}/FINGERPRINTS")
fi
sed -i -e "s|@ENTRY_COUNT@|$ENTRY_COUNT|g" "$SYNOPKG_TEMP_LOGFILE"
if [[ "$ENTRY_COUNT" -eq "0" ]]; then
  #  1: @HASH_DELETION@The 1st script after installation/configuration will be registered and is allowed to execute then again and again.
  sed -i -e "s|@HASH_DELETION@||" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  #  "regex": { "expr": "/^[@SECURITY_RANGE@]+$/","errorText": "With no previously registered hashes value 3 makes no sense"} 
  sed -i -e "s|@SECURITY_RANGE@|0-2|" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  echo "$(date "$DTFMT"): @SECURITY_RANGE@ replaced by '0-2'" >> "$LOG"
else
  #  1: @HASH_DELETION@The 1st script after installation/configuration will be registered and is allowed to execute then again and again.
  if [[ -f "$scriptpathParent/package/ui/texts/$lng/lang.txt" ]]; then
    eval "$(grep "HASH_DELETION=" "$scriptpathParent/package/ui/texts/$lng/lang.txt")" # "
  else
    HASH_DELETION="<b>Previous registered hashes are all deleted now.</b> "
  fi  
  echo "$(date "$DTFMT"): @HASH_DELETION@ replaced by '$HASH_DELETION'" >> "$LOG"
  sed -i -e "s|@HASH_DELETION@|$HASH_DELETION|" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  sed -i -e "s|@SECURITY_RANGE@|0-3|" "$SYNOPKG_TEMP_LOGFILE" # allow all values
  echo "$(date "$DTFMT"): @SECURITY_RANGE@ replaced by '0-3'" >> "$LOG"
fi

# Fill ComboBox with the configured scheduled Tasks:
# not possible as the command $(synoschedtask --get) is not working as actual user = $SYNOPKG_PKGNAME

echo "$(date "$DTFMT"): Values from config put to template '$SYNOPKG_TEMP_LOGFILE'" >> "$LOG"
echo "$(date "$DTFMT"): ... $0 done" >> "$LOG"
# putting here somthing to ENV for use in postinst script is not working!
exit 0

