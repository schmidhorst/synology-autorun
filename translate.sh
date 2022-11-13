#!/bin/bash
# api.deepl.com
# Here is where the magic with DeepL happens. We get the JSON response from
# Look at https://www.deepl.com/docs-api/translating-text/request/ for supported languages
bExec=1 # 0: do not translate, only list files, which would be processed, 1: translate
bUpdateAll=0 # 0: update only outdated files, 1:translate all
SCRIPTPATHTHIS="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; /bin/pwd -P )"
source "$SCRIPTPATHTHIS/package/ui/modules/parse_hlp.sh" # urlencode, urldecode
SCRIPTPATHPARENT=${SCRIPTPATHTHIS%/*}
if [[ -f "$SCRIPTPATHPARENT/DeepLApiKey.txt" ]]; then
  apikey=$(cat "$SCRIPTPATHPARENT/DeepLApiKey.txt")
  echo "DeepL Api-Key '$apikey'"
else
  echo "Datei $SCRIPTPATHPARENT/DeepLApiKey.txt mit dem DeepL ApiKey nicht gefunden!"
  exit 2
fi
deepl_url="https://api.deepl.com/v2/translate?auth_key=$apikey"
# deepl_url="https://api-free.deepl.com/v2/translate?auth_key=$apikey"

declare -A SYNO2ISO
SYNO2ISO=( ["ger"]="de" ["enu"]="en" ["chs"]="zh" ["csy"]="cs" ["jpn"]="ja" ["krn"]="ko" ["dan"]="da" ["fre"]="fr" ["ita"]="it" ["nld"]="nl"              ["plk"]="pl" ["rus"]="ru" ["spn"]="es" ["sve"]="sv" ["hun"]="hu" ["trk"]="tr" ["ptb"]="pt-BR" ["ptg"]="pt-PT" )
# Japan: ja (DeepL acc. FIPS 10 = U.S. Federal Information Processing Standard No. 10), not jp (ISO 3166-1)?

# https://www.laenderdaten.info/laendercodes.php

# Deepl: BG - Bulgarian, , EL - Greek, ET - Estonian, FI - Finnish, ID - Indonesian, LT - Lithuanian, LV - Latvian, RO - Romanian, RO - Romanian, SK - Slovak, SL - Slovenian, UK - Ukrainian
# DeepL-Syno: CS - Czech - csy, DA - Danish - dan, DE - German - ger, EN - English - enu, ES - Spanish - spn, FR - French - fre, HU - Hungarian - hun, IT - Italian - ita, JA - Japanese - jpn, NL - Dutch - nld, PL - Polish - plk, PT-BR - Portuguese Brazilian - ptb,  PT-PT - Portuguese European - ptg, RU - Russian - rus, SV - Swedish - sve, TR - Turkish - trk, ZH - Chinese simplified - chs
#Syno: ["cht"]="" Chinese traditional,  ["krn"]="ko" Korean, NO - Norwegian - nor,  th - Thai - tha


synoLangs="chs csy dan fre hun ita jpn nld plk ptb ptg rus spn sve trk"
#synoLangs="ger fre ita jpn"

sourceSynoLang="enu"
sourceIsoLang="${SYNO2ISO[$sourceSynoLang]}"

# sourcable files:
filePath="$SCRIPTPATHTHIS/package/ui/texts"
sourceablefiles=( "$filePath/${sourceSynoLang}/lang.txt" "$filePath/${sourceSynoLang}/strings" )

# json files from Wizzards:
wizzardfiles=( "$SCRIPTPATHTHIS/WIZARD_UIFILES/wizard_$sourceSynoLang.json" "$SCRIPTPATHTHIS/WIZARD_UIFILES/uninstall_uifile_$sourceSynoLang" )

# html files:
htmlfiles=( "$SCRIPTPATHTHIS/package/ui/licence_$sourceSynoLang.html" )

allfiles=( "${sourceablefiles[@]}" "${wizzardfiles[@]}" "${htmlfiles[@]}" ) # all source files
for sourcefile in "${allfiles[@]}"; do
  if [[ ! -f "$sourcefile" ]]; then
    echo "Sourecfile '$sourcefile' for translation is missing!"
    exit 2
  fi
done

# line by line translation of sourcable files with removed item label like "msg1="
for sourcefile in "${sourceablefiles[@]}"; do
  if [[ "$bUpdateAll" -ne "0" ]]; then
    timeStampSource=$(date +%s)
  else
    timeStampSource=$(stat -c %Y "$sourcefile")  
  fi
  timeStampSource=$(stat -c %Y "$sourcefile")
  for synoLang in $synoLangs; do
    targetIsoLang="${SYNO2ISO[$synoLang]}"
    srcLngPath=$(dirname "$sourcefile")
    # echo "srcLngPath=$srcLngPath, ${srcLngPath##*/}"
    if [[ "${srcLngPath##*/}" == "$sourceSynoLang" ]]; then # lng in path, seperate folders for each language
      lngPath=${srcLngPath%/*} # parent without e.g. "ger"
      targetFile="$lngPath/${synoLang}/$(basename "$sourcefile")"
      if [[ "$bExec" -ne "0" ]]; then
        if [[ ! -d "$filePath/${synoLang}" ]]; then
          mkdir "$filePath/${synoLang}" 
          chmod 777 "$filePath/${synoLang}"
          chown :users "$filePath/${synoLang}" 
        fi
      fi
    else # lng in file name
      # targetFile=$(echo "$sourcefile" | sed "s/_$sourceSynoLang/_$synoLang/")
      targetFile=${sourcefile/_$sourceSynoLang/_$synoLang}
    fi
    echo "source='$sourcefile', target='$targetFile'"
    uptodate=0    
    if [[ -f "$targetFile" ]]; then
      timeStampDest=$(stat -c %Y "$targetFile")
      if [[ "$timeStampDest" -gt "$timeStampSource" ]]; then # up to date
        echo "up to date: $targetFile"
        uptodate=1
      else
        echo "too old: $targetFile"
        if [[ "$bExec" -ne "0" ]]; then
          rm "$targetFile"
        fi # bExec          
      fi # timeStamp
    else
      echo "not yet existing: $targetFile"
    fi # target exists else
    if [[ "uptodate" -eq "0" ]]; then
      lineCount=0
      while read line; do # read all settings from file
        lineCount=$((lineCount+1))
        if [[ ${line} == "#"* ]] || [[ ${line} == "["* ]]; then
          if [[ "$bExec" -ne "0" ]]; then
            echo "$line" >> "$targetFile"
            if [[ "$lineCount" -eq "1" ]]; then # add an comment line
              echo "# This file was generated via DeepL machine translation from $sourceIsoLang" >> "$targetFile"        
            fi
          fi       
        else
          itemName=${line%%=*}
          val=$(echo "${line#*=}" | sed 's/^"//' | sed 's/"$//')
          preparedsource="$val"
          # echo "$synoLang $targetIsoLang: '$source' '$preparedsource'"
          param="target_lang=$targetIsoLang&source_lang=$sourceIsoLang"
          if [[ "$bExec" -ne "0" ]]; then
            translatedraw=$(curl -Gs "$deepl_url" --data-urlencode "text=$preparedsource" -d "$param")
            res=$? 
            if [ $res -eq 0 ]; then # If the curl above was sucessful
              # Get the translated text from the JSON response:
              translated=$(echo "$translatedraw" | jq -c '.translations[0].text')
              # echo "$translated"
              translated=$(urldecode "$translated") 
              echo "$synoLang $targetIsoLang: $translated"
              echo "$itemName=$translated" >> "$targetFile"
            else # If the curl above was NOT sucessful
              echo "The request failed: $res"
              exit 1
            fi
          else
            echo "to translate: '$preparedsource'"
          fi        
        fi
      done < "$sourcefile" # while read: Works well even if last line has no \n!    
      chmod 777 "$targetFile"
      chown :users "$targetFile" 
    fi # not uptodate 
  done # for synoLang in $synoLangs; do
done # for sourcefile in $sourceablefiles; do
  
# translation of lines with "desc": and "step_title": in wizzard files: 
for sourcefile in "${wizzardfiles[@]}"; do
  if [[ "$bUpdateAll" -ne "0" ]]; then
    timeStampSource=$(date +%s)
  else
    timeStampSource=$(stat -c %Y "$sourcefile")
  fi  
  for synoLang in $synoLangs; do
    targetIsoLang="${SYNO2ISO[$synoLang]}"
    srcLngPath=$(dirname "$sourcefile")
    # echo "srcLngPath=$srcLngPath, ${srcLngPath##*/}"
    if [[ "${srcLngPath##*/}" == "$sourceSynoLang" ]]; then # lng in path, seperate folders for each language
      lngPath=${srcLngPath%/*} # parent without e.g. "ger"
      targetFile="$lngPath/${synoLang}/$(basename "$sourcefile")"    
    else # lng in file name
      # targetFile=$(echo "$sourcefile" | sed "s/_$sourceSynoLang/_$synoLang/")     
      targetFile=${sourcefile/_$sourceSynoLang/_$synoLang}     
    fi
    if [[ ! -d "$filePath/${synoLang}" ]]; then
      mkdir "$filePath/${synoLang}" 
      chmod 700 "$filePath/${synoLang}"
      chown :users "$filePath/${synoLang}" 
    fi
    echo "source='$sourcefile', target='$targetFile'"
    uptodate=0    
    if [[ -f "$targetFile" ]]; then
      timeStampDest=$(stat -c %Y "$targetFile")
      age=$(( timeStampDest - timeStampSource ))
      if [[ "$timeStampDest" -gt "$timeStampSource" ]]; then # up to date
        echo "up to date: $targetFile, age: $age"
        uptodate=1
      else
        echo "too old: $targetFile, age: $age"
        if [[ "$bExec" -ne "0" ]]; then
          rm "$targetFile"
        fi # bExec          
      fi # timeStamp
    else
      echo "not yet existing: $targetFile"
    fi # target exists else
    if [[ "uptodate" -eq "0" ]]; then
      lineCount=0
      while read line; do # read all settings from file
        lineCount=$((lineCount+1))
        val=""
        if [[ ${line} == *"\"step_title\":"* ]] || [[ ${line} == *"\"desc\":"* ]]; then
          prefix=${line%%:*}
          #val=$(echo "${line#*=}" | sed 's/^"//' | sed 's/"$//')
          val="${line#*:}" # e.g. "Konfiguration",
          echo "raw val='$val'"
          postfix="${val##*\"}" # e.g. trailing comma
          val="${val%\"*}"
          val="${val#*\"}"
          echo "postfix='$postfix', remaining='$val'"
        elif [[ ${line} == *"\"fn\""*"return" ]]; then # "fn": "{if (/^([0-9]+)$/.test(arguments[0])) return true; return 'Eine positive Zahl eingeben!'; }"
          prefix=${line%return*}
          val=${line##*return }
          postfix=${line##*\'}
          val=$(echo "$val" | sed "s/\$postfix$//")
        fi      
        if [[ -n $val ]]; then
          if [[ "$bExec" -ne "0" ]]; then
            preparedsource="$val"
            # echo "$synoLang $targetIsoLang: '$source' '$preparedsource'"
            param="target_lang=$targetIsoLang&source_lang=$sourceIsoLang"
            if [[ "${targetFile}" == *"html" ]]; then
              param="$param&tag_handling=html"        
            fi
            translatedraw=$(curl -Gs "$deepl_url" --data-urlencode "text=$preparedsource" -d "$param")
            res=$? 
            if [ $res -eq 0 ]; then # If the curl above was sucessful
              # Get the translated text from the JSON response:
              translated=$(echo "$translatedraw" | jq -c '.translations[0].text')
              translated=$(urldecode "$translated") 
              echo "$synoLang $targetIsoLang: $translated"
              echo "${prefix}:$translated$postfix" >> "$targetFile"
            else # If the curl above was NOT sucessful
              echo "The request failed: $res"
              exit 1
            fi # if [ $res -eq 0 ] else
          else # only simulation
            echo "source line: '$line'"
            echo "to translate: '$val'"
            echo "result line: '${prefix}: \"XXXX\"${postfix}'"
          fi # translate or simulate
        else # $val empty: copy line unchanged:
          if [[ "$bExec" -ne "0" ]]; then
            echo "$line" >> "$targetFile"
          fi  
        fi
      done < "$sourcefile" # while read: Works well even if last line has no \n!    
      chmod 777 "$targetFile"
      chown :users "$targetFile" 
    fi # not uptodate
  done # for synoLang in $synoLangs; do
done # for sourcefile in ${wizzardfiles[@]}; do


# translation of html files
for sourcefile in "${htmlfiles[@]}"; do
  if [[ "$bUpdateAll" -ne "0" ]]; then
    timeStampSource=$(date +%s)
  else
    timeStampSource=$(stat -c %Y "$sourcefile")
  fi  
  for synoLang in $synoLangs; do
    targetIsoLang="${SYNO2ISO[$synoLang]}"
    srcLngPath=$(dirname "$sourcefile")
    # echo "srcLngPath=$srcLngPath, ${srcLngPath##*/}"
    if [[ "${srcLngPath##*/}" == "$sourceSynoLang" ]]; then # lng in path, seperate folders for each language
      
      lngPath=${srcLngPath%/*} # parent without e.g. "ger"
      targetFile="$lngPath/${synoLang}/$(basename "$sourcefile")"
      if [[ "$bExec" -ne "0" ]]; then
        if [[ ! -d "$filePath/${synoLang}" ]]; then
          mkdir "$filePath/${synoLang}" 
        fi
      fi
    else # lng in file name
      #targetFile=$(echo "$sourcefile" | sed "s/_$sourceSynoLang/_$synoLang/")
      targetFile=${sourcefile/_$sourceSynoLang/_$synoLang}
    fi
    uptodate=0    
    if [[ -f "$targetFile" ]]; then
      timeStampDest=$(stat -c %Y "$targetFile")
      if [[ "$timeStampDest" -gt "$timeStampSource" ]]; then # up to date
        echo "up to date: $targetFile"
        uptodate=1
      else
        echo "too old: $targetFile"
        if [[ "$bExec" -ne "0" ]]; then
          rm "$targetFile"
        fi # bExec          
      fi # timeStamp
    else
      echo "not yet existing: $targetFile"
    fi # target exists else
    if [[ "uptodate" -eq "0" ]]; then
      val=$(<"$sourcefile")
      param="target_lang=$targetIsoLang&source_lang=$sourceIsoLang&tag_handling=html"        
      if [[ "$bExec" -ne "0" ]]; then
        translatedraw=$(curl -Gs "$deepl_url" --data-urlencode "text=$val" -d "$param")
        res=$? 
        if [ $res -eq 0 ]; then # If the curl above was sucessful
          # echo "Response from DeepL: $translatedraw"
          # Get the translated text from the JSON response:
          translated=$(echo "$translatedraw" | jq -c '.translations[0].text')
          translated=${translated#\"} # remove quote at string start
          translated=${translated%\"} # remove quote at string end
          #printf %s "$translated" > "${targetFile}_extracted"
          echo "to $synoLang translated $sourcefile:"
          translated=$(urldecode "$translated") 
          # echo "$translated"
          # printf %s "$translated" > "$targetFile"
          echo -e "$translated" > "$targetFile"
          chmod 777 "$targetFile"
          chown :users "$targetFile" 
          sed -i 's/\\"/"/g' "$targetFile" # unescape all quotes
          sed -i 's/<html lang=\"..\">/<html lang=\"$targetIsoLang\">/' "$targetFile"       
        else # If the curl above was NOT sucessful
          echo "The request failed: $res"
          exit 1
        fi
      else
        echo "Source: '$sourcefile', Target: '$targetFile'"    
      fi        
    fi # not up to date
  done # for synoLang in $synoLangs; do
done # for sourcefile in $htmlfiles; do

