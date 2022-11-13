#!/bin/bash
# Filename: get_language.sh - coded in utf-8
#********************************************************************#
#  Description: Account ${app_name} has no access to user languages  #
#               cgi files are runing in that account                 #
#               This is called from start-stop script, which is      #
#               running as root. And retrieve at packageage start    #
#               for each account the language                        # 
#  Author 1:    Horst Schmid, 2022                                   #
#  License:     GNU GPLv3                                            #
#  ----------------------------------------------------------------  #
#  Version:     2022-11-08                                           #
#********************************************************************#
if [[ -n $SYNOPKG_PKGNAME ]]; then
  LOG="/var/log/tmp/$SYNOPKG_PKGNAME.log"
else # direct execution for debugging
  SYNOPKG_PKGNAME="autorun"
  LOG="/var/log/tmp/getLng.log"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S'): get_languages.sh started ..." >> "$LOG"
LNGDATA="/var/packages/$SYNOPKG_PKGNAME/var/lanuages"
# echo "Settings file: $LNGDATA"
if [[ ! -a "$LNGDATA" ]]; then
  touch "$LNGDATA" # create file
  chmod 644 "$LNGDATA"
  chown "$SYNOPKG_PKGNAME":"$SYNOPKG_PKGNAME" "$LNGDATA" # make it accessable & readable for the cgi scripts  
fi
users=$(synouser --enum all) # including admins, local, domain, ldap
count=$(wc -w <<< "$users") # due to headline real count is one less
if [[ "$count" -gt 200 ]]; then # too many
  users=$(synouser --enum_admin all) # list of all configured administrators
  count=$(wc -w <<< "$users")
  if [[ "$count" -gt 200 ]]; then # too many
    users=$(synouser --enum_admin local) # list of local administrators
  fi
fi
users=${users#*:} # remove header, e.g. "10 User Listed:"
for f in ${users}; do
  # echo "processing user '$f'"
  usersettingsfile="/usr/syno/etc/preference/${f}/usersettings"
  if [ -f "${usersettingsfile}" ] ; then
    userlanguage=$(jq -r ".Personal.lang" "${usersettingsfile}")
    echo "user '$f' language: '$userlanguage'" # may be 'def', 'null' or e.g. ger, enu, ...
    if [[ -n $userlanguage ]] && [[ "$userlanguage" != "null" ]]; then
      oldLine=$(grep "^$f=" "$LNGDATA")
      echo "oldLine $f: $oldLine"
      if [[ -n "$oldLine" ]]; then # entry available
        if [[ "${oldLine#*=}" != "$userlanguage" ]]; then # change entry
          echo "different! ${oldLine#*=} ==> $userlanguage"
          sed -i "s/^${f}=.*\$/$f=$userlanguage/" "$LNGDATA" 
        fi
      else # not yet available
        echo "new: $f=$userlanguage"
        echo "$f=$userlanguage" >> "$LNGDATA"        
      fi 
    fi
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S'): No access to $usersettingsfile" >> "$LOG"
  fi  
done
echo "$(date '+%Y-%m-%d %H:%M:%S'): ... get_languages.sh done" >> "$LOG"

