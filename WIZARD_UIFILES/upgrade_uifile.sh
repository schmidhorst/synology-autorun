#!/bin/bash
DTFMT="+%Y-%m-%d %H:%M:%S"

############################ start #########################
msg=""
if [[ -z "$SYNOPKG_PKGNAME" ]]; then # may be direkt start for debugging
  # $SYNOPKG_PKGNAME is available if pre-processing was well done!
  SYNOPKG_PKGNAME="autorun"
  msg="Error: Env SYNOPKG_PKGNAME was not set!"
  LOGLEVEL=8;
fi
# Can we read old LogLevel configuration?
SCRIPTPATHwiz="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; /bin/pwd -P )"
if [[ -f "${SCRIPTPATHwiz}/log_hlp.sh" ]]; then
  source "${SCRIPTPATHwiz}/log_hlp.sh"
else
  msg="$msg, Error: '${SCRIPTPATHwiz}/log_hlp.sh' not found!"
fi
# after uninstall is /var/packages/$SYNOPKG_PKGNAME no more available, only /volume1/@appdata/autorun/config !!!
configFilePathName="${SCRIPTPATHwiz%%/@*}/@appdata/${SYNOPKG_PKGNAME}/config"
scriptpathParent=${SCRIPTPATHwiz%/*}
logInfo 2 "Running as user='$(whoami)', putting values from wizard_XXX.json and the config file to $SYNOPKG_TEMP_LOGFILE, which replaces upgrade_uifile"

# $SYNOPKG_TEMP_LOGFILE is e.g. /var/run/synopkgs/synopkgwizard.log.YzJhP5
if [[ -n "$msg" ]]; then
  # logInfo 4 "$msg"
  echo "$msg" >> "$LOG"
fi
logInfo 7 "id: $(id), $(basename "${BASH_SOURCE[0]}"): $(stat "${BASH_SOURCE[0]}" | grep "Access: ("), cmdline='$(tr '\0' ' ' </proc/$PPID/cmdline)'" # id: uid=autorun gid=autorun groups=autorun,1(system),999(synopkgs),1023(http)
folder="$(dirname "${BASH_SOURCE[0]}")" # e.g. /volume1/@tmp/synopkg/wizard.HmIKuj/WIZARD_UIFILES/, Access: (0755/drwxr-xr-x) Uid: ( 0/ root) Gid: ( 0/ root)
# under e.g. /volume1/@tmp/synopkg/wizard.HmIKuj we have the files extracted from the outer tar. The inner tar "package.tgz" is not yet extracted!
folderTmp="${folder%%/synopkg*}" # Access: (1777/drwxrwxrwt) Uid: ( 0/ root) Gid: ( 0/ root)
logInfo 7 "$folder: $(stat "$folder" | grep "Access: ("), $folderTmp: $(stat "$folderTmp" | grep "Access: (")"

if [[ -n "$SYNOPKG_DSM_LANGUAGE" ]]; then
  lng="$SYNOPKG_DSM_LANGUAGE" # lng of actual user
  logInfo 6 "Language from environment SYNOPKG_DSM_LANGUAGE: '$lng'" # normally available, lng of actual user
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
  logInfo 3 "No language in environment found, using 'enu'"
fi

JSON="$(dirname "${BASH_SOURCE[0]}")/wizard_$lng.json"
if [[ ! -f "$JSON" ]]; then # no translation to the actual language available
  JSON=$(dirname "${BASH_SOURCE[0]}")/wizard_enu.json # using English version
fi
if [ ! -f "$JSON" ]; then
  logError "ERROR 11: WIZARD template file '$JSON' not available!"
  echo "[]" >> "$SYNOPKG_TEMP_LOGFILE"
  logError "No upgrade_uifile ($$SYNOPKG_TEMP_LOGFILE) generated (only empty file)"
  exit 11 # should we use exit 0 ?
fi
logInfo 6 "WIZARD template file '$JSON' is available"
if [ ! -f "$configFilePathName" ]; then
  logInfo 7 "No old configuration file '$configFilePathName' from a previous installation V1.10ff found"
  configFilePathName="${SCRIPTPATHwiz%%/@*}/@appdata/${SYNOPKG_PKGNAME}/config"  # version <1.10 used config in this folder  
fi
if [ ! -f "$configFilePathName" ]; then
  logError "Suspicious: No old configuration not available! Trying to use initial configuration setup"
  configFilePathName="$(dirname "${BASH_SOURCE[0]}")/initial_config.txt"
  if [ ! -f "$configFilePathName" ]; then
    logError "Error: initial_config.txt not found!"
    echo "[]" >> "$SYNOPKG_TEMP_LOGFILE"
    logError "No upgrade_uifile ($SYNOPKG_TEMP_LOGFILE) generated (only empty file)" >> "$LOG"
    exit 12
  fi
fi
logInfo 7 "Used config file: '$configFilePathName'"

cat "$JSON" >> "$SYNOPKG_TEMP_LOGFILE" # language dependent file for the Installation wizzard

fields="" # get all the items names from the initial_config.txt file
file="$(dirname "${BASH_SOURCE[0]}")/initial_config.txt"
if [[ ! -f "$file" ]]; then
  logError "Error: initial_config.txt not found!"
  exit 14
fi
logInfo 7 "getting item names from '$(dirname "${BASH_SOURCE[0]}")/initial_config.txt'..."
while read -r line; do
  if [[ "$line" != "#"* ]]; then
    fields="$fields${line%%=*} "
  fi
done < "$(dirname "${BASH_SOURCE[0]}")/initial_config.txt"
logInfo 7 "...done, Items are '$fields'"

msg=""
for f1 in $fields; do # get the item value now either from latest configuration or the default value from the intial config file
  line=$(grep "^$f1=" "$configFilePathName")
  if [[ -z "$line" ]]; then # new item in this version
    hint=" (default)"
    line=$(grep "^$f1=" "$(dirname "${BASH_SOURCE[0]}")/initial_config.txt")  # fetch it from file with defaults
  else
    hint=" (prev. cfg)"
  fi
  # eval "$line" # not secure, code injection may be possible
  declare "$f1"="$(sed -e 's/^"//' -e 's/"$//' <<<"${line#*=}")"
  msg="$msg, $f1='${!f1}'$hint"
  sed -i -e "s|@${f1}@|${!f1}|g" "$SYNOPKG_TEMP_LOGFILE" # replace placeholder like '@SCRIPT@' by value in upgrade_uifile
done
logInfo 7 "Found settings: ${msg:1}"

ENTRY_COUNT=0
if [ -f "${SYNOPKG_PKGVAR}/FINGERPRINTS" ]; then
  ENTRY_COUNT=$(wc -l < "${SYNOPKG_PKGVAR}/FINGERPRINTS")
fi
sed -i -e "s|@ENTRY_COUNT@|$ENTRY_COUNT|g" "$SYNOPKG_TEMP_LOGFILE"
if [[ "$ENTRY_COUNT" -eq "0" ]]; then
  #  1: @HASH_DELETION@The 1st script after installation/configuration will be registered and is allowed to execute then again and again.
  sed -i -e "s|@HASH_DELETION@||" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  logInfo 7 "As the actual hash entry count is zero, useless selection option @HASH_DELETION@ removed from wizzard"
  #  "regex": { "expr": "/^[@SECURITY_RANGE@]+$/","errorText": "With no previously registered hashes value 3 makes no sense"}
  sed -i -e "s|@SECURITY_RANGE@|0-2|" "$SYNOPKG_TEMP_LOGFILE" # Error message for value "3 Only previously registered"
  logInfo 8 "Place holder @SECURITY_RANGE@ replaced by '0-2'"
else
  # Description for the selection '1' will be:
  #  1: @HASH_DELETION@The 1st script after installation/configuration will be registered and is allowed to execute then again and again.
  if [[ -f "$scriptpathParent/package/ui/texts/$lng/lang.txt" ]]; then
    eval "$(grep "HASH_DELETION=" "$scriptpathParent/package/ui/texts/$lng/lang.txt")" # "
  else
    HASH_DELETION="<b>Previous registered hashes are all deleted now.</b> "
  fi  
  if [[ "$ADD_NEW_FINGERPRINTS" -eq "1" ]]; then
    rm -f "${SYNOPKG_PKGVAR}/FINGERPRINTS"
  else
    HASH_DELETION="" # no hash deletion
  fi
  sed -i -e "s|@HASH_DELETION@|$HASH_DELETION|" "$SYNOPKG_TEMP_LOGFILE"
  sed -i -e "s|@SECURITY_RANGE@|0-3|" "$SYNOPKG_TEMP_LOGFILE" # allow all values
  logInfo 7 "Place holder @SECURITY_RANGE@ replaced by '0-3' and @HASH_DELETION@ replaced by '$HASH_DELETION'"
fi

# Fill ComboBox with the configured scheduled Tasks:
# not possible as the command $(synoschedtask --get) is not working as actual user = $SYNOPKG_PKGNAME

logInfo 7 "Wizzard template '$JSON' copied to '$SYNOPKG_TEMP_LOGFILE' and values from config inserted"
logInfo 7 " ... ${BASH_SOURCE[0]} done"
exit 0

