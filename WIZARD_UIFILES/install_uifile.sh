#!/bin/bash
# $SYNOPKG_PKGNAME is available if pre-processing was well done! 
LOG="/var/tmp/autorun.log"
DTFMT="+%Y-%m-%d %H:%M:%S"
SCRIPTPATHTHIS="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
user=$(whoami)
scriptpathParent=${SCRIPTPATHTHIS%/*}
echo "$(date "$DTFMT"): Start of $0 to put values from config file (if available) to '$SYNOPKG_TEMP_LOGFILE', which replaces install_uifile (as $user)" >> "$LOG"
if [[ -z "$SYNOPKG_PKGNAME" ]]; then
  LOG="/var/tmp/autorun.log"
  echo "$(date "$DTFMT"): Error: SYNOPKG_PKGNAME is not set in install_uifile.sh !!!???" >> "$LOG"
else
  LOG="/var/tmp/$SYNOPKG_PKGNAME.log"
  echo "$(date "$DTFMT"): install_uifile.sh SYNOPKG_PKGNAME is available: '$SYNOPKG_PKGNAME'" >> "$LOG"
fi

if [[ -n "$SYNOPKG_DSM_LANGUAGE" ]]; then
  lng="$SYNOPKG_DSM_LANGUAGE" # lng of actual user
  echo "$(date "$DTFMT"): from environment SYNOPKG_DSM_LANGUAGE: '$lng'" | tee -a "$LOG"
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
# after uninstall is /var/packages/$SYNOPKG_PKGNAME no more available, only /volume1/@appdata/autorun/config !!! 
#configFilePathName="/var/packages/$SYNOPKG_PKGNAME/var/config"
configFilePathName="${SCRIPTPATHTHIS%%/@*}/@appdata/${SYNOPKG_PKGNAME}/config"
if [ ! -f "$configFilePathName" ]; then
  echo "$(date "$DTFMT"): File '$configFilePathName' not found" | tee -a "$LOG"
  configFilePathName="${SCRIPTPATHTHIS%%/@*}/@appdata/${SYNOPKG_PKGNAME}/config"  # version <1.10 used config in this folder  
fi
if [ ! -f "$configFilePathName" ]; then
  echo "$(date "$DTFMT"): No Cfg-File not found, using initial config" | tee -a "$LOG"
  configFilePathName="$(dirname "$0")/initial_config.txt"
fi
echo "$(date "$DTFMT"): Used config file: '$configFilePathName'" >> "$LOG"

cat "$JSON" >> "$SYNOPKG_TEMP_LOGFILE"
fields="SCRIPT SCRIPT_AFTER_EJECT ADD_NEW_FINGERPRINTS TRIES WAIT BEEP LED LED_COPY EJECT_TIMEOUT LOG_MAX_LINES NOTIFY_USERS NO_DSM_MESSAGE_RETURN_CODES LOGLEVEL"
msg=""
for f1 in $fields; do
  line=$(grep "^$f1=" "$configFilePathName")
  if [[ -z "$line" ]]; then # new item in this version
    line=$(grep "^$f1=" "$(dirname "$0")/initial_config.txt")  
  fi
  eval "$line"
  sed -i -e "s|@${f1}@|${!f1}|g" "$SYNOPKG_TEMP_LOGFILE" # replace placeholder by value in upgrade_uifile
  msg="$msg, $f1='${!f1}'"
done
echo "$(date "$DTFMT"): Found settings: $msg" >> "$LOG"      

ENTRY_COUNT=0
# after uninstall is "${SYNOPKG_PKGVAR}/FINGERPRINTS" = "/var/packages/$SYNOPKG_PKGNAME/var/FINGERPRINTS" invalid
fingerprints="${SCRIPTPATHTHIS%%/@*}/@appdata/${SYNOPKG_PKGNAME}/FINGERPRINTS" # e.g. /volume1/@appdata/${SYNOPKG_PKGNAME}/FINGERPRINTS  
if [ -f "$fingerprints" ]; then
  ENTRY_COUNT=$(wc -l < "$fingerprints")
fi
sed -i -e "s|@ENTRY_COUNT@|$ENTRY_COUNT|g" "$SYNOPKG_TEMP_LOGFILE"
if [[ "$ENTRY_COUNT" -eq "0" ]]; then
  #  1: @HASH_DELETION@The 1st script after installation/configuration will be registered and is allowed to execute then again and again.
  sed -i -e "s|@HASH_DELETION@||" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  echo "$(date "$DTFMT"): @HASH_DELETION@ removed" >> "$LOG"
  #  "regex": { "expr": "/^[@SECURITY_RANGE@]+$/","errorText": "With no previously registered hashes value 3 makes no sense"} 
  sed -i -e "s|@SECURITY_RANGE@|0-2|" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  echo "$(date "$DTFMT"): @SECURITY_RANGE@ replaced by '0-2'" >> "$LOG"
else
  #  1: @HASH_DELETION@The 1st script after installation/configuration will be registered and is allowed to execute then again and again.
  if [[ -f "$scriptpathParent/package/ui/texts/$lng/lang.txt" ]]; then
    # preinstDsmVersError=$(/bin/get_key_value "$scriptpathParent/package/ui/texts/$lng/lang.txt" "preinstDsmVersError")  # "... ${osMin} ..." is not yet expanded
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

echo "$(date "$DTFMT"): Wizzard template copied to '$SYNOPKG_TEMP_LOGFILE' and values from config inserted" >> "$LOG"
echo "$(date "$DTFMT"): ... $0 done" >> "$LOG"
exit 0

