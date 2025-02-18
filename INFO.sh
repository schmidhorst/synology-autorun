#!/bin/bash
#shellcheck disable=2034,1091 # no warning for unused variables, not found external scripts like pkg_util.sh
if [[ "$1" == "" ]]; then # Generation with toolkit scripts
  source /pkgscripts-ng/include/pkg_util.sh
fi
package="autorun"
version="1.10.0-0011"
# beta="yes"
arch="noarch"
os_min_ver="7.0-40000"
# install_dep_packages="WebStation>=3.0.0-0323:PHP7.4>=7.4.18-0114:Apache2.4>=2.4.46-0122"
# install_dep_packages="Perl" # not needed
maintainer="Jan Reidemeister, Horst Schmid"
maintainer_url="https://github.com/schmidhorst/synology-autorun"
# ctl_stop="yes"
# reloadui="yes"
thirdparty="yes"
support_center="no"
dsmuidir="ui"
distributor=""
# distributor_url=""
silent_upgrade="no"
# precheckstartstop="yes"
arch="noarch"
helpurl="https://www.synology-forum.de/showthread.html?18360-Autorun-fuer-ext.-Datentraeger"
support_url="https://github.com/schmidhorst/synology-${package}/issues"
dsmappname="SYNO.SDS._ThirdParty.App.$package"

SCRIPTPATHinfo="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; /bin/pwd -P )"

# index.cgi uses https://raw.githubusercontent.com/schmidhorst/synology-autorun/main/INFO.sh to check for an new version
# change that entry automatically if the maintainer_url is changed:
if [[ -n "$maintainer_url" ]]; then
  githubRawInfoUrl=$(echo "${maintainer_url}/main/INFO.sh" | sed 's/github.com/raw.githubusercontent.com/')
  # patch githubRawInfoUrl directly to the index.cgi file if necessary:
  lineInfoUrl=$(grep "githubRawInfoUrl=" "$SCRIPTPATHinfo/package/ui/index.cgi")
  if [[ "$lineInfoUrl" != "githubRawInfoUrl=\"${githubRawInfoUrl}\"" ]]; then
    sed -i "s|^githubRawInfoUrl=.*\$|githubRawInfoUrl=\"${githubRawInfoUrl}\" #patched to distributor_url from INFO.sh|" "$SCRIPTPATHinfo/package/ui/index.cgi"
  fi
fi
if [[ "$1" != "" ]]; then  # Generation without toolkit scripts
  line0=$(grep "SYNO.SDS." "package/ui/config")
  # echo "from ui/config: '$line0'"
  line1="${line0#*SYNO.SDS.}"
  line1=${line1%%\"*}
  dsmappname="SYNO.SDS.${line1}" # synodsmnotify works only, if dsmappname is identical to .url in ui/config !
  pck=${line1##*.}
  if [[ "$pck" != "$package" ]]; then
    echo "================================================================"
    echo "==INFO.sh: ====================================================="
    echo "Warning: package='$package' not found in .url{...} of package/ui/config:"
    echo "$line0"
    echo "================================================================"
    echo "================================================================"
  fi

  line0=$(grep -i '"appWindow"' "package/ui/config")
  # echo "from ui/config: '$line0'"
  if [[ -n "$line0" ]] && [[ ! "${line0,,}" == *"${package,,}"* ]]; then # match in lower case
    echo "================================================================"
    echo "==INFO.sh: ====================================================="
    echo "Warning: The \"appWindow\" line in package/ui/config does not contain the package name '$package':"
    echo "$line0"
    echo "================================================================"
    echo "================================================================"
  fi

  line0=$(grep -i '"url"' "package/ui/config")
  # echo "from ui/config: '$line0'"
  if [[ -n "$line0" ]] && [[ "$line0" == *"/webman/3rdparty/"* ]] && [[ ! "${line0,,}" == *"${package,,}"* ]]; then # match in lower case
    echo "================================================================"
    echo "==INFO.sh: ====================================================="
    echo "Warning: The \"url\" line in package/ui/config does not contain the package name '$package':"
    echo "$line0"
    echo "================================================================"
    echo "================================================================"
  fi
fi
# displayname=""  # if not set then $package will be used as displayname, fetched from lang.txt file
# displayname_enu="" #  fetched from lang.txt file
# displayname_ger=""
# description="Execute a script on (or for) external drive (USB / eSATA) when it's connected to the disk station." #  fetched from lang.txt file
# description_enu="Execute a script on (or for) external drive (USB / eSATA) when it's connected to the disk station." #  fetched from lang.txt file
# description_ger="Führt ein Skript auf einem (oder für ein) externen Laufwerk (USB / eSATA) aus wenn dieses an die Diskstation angeschlossen wird." #  fetched from lang.txt file

if [[ "$1" != "" ]]; then # Generation without toolkit scripts
# copy of 'pkg_dump_info' from '/pkgscripts-ng/include/pkg_util.sh' ('local' removed):
  langs="enu chs ger fre ita spn jpn dan sve nld rus plk ptb ptg hun trk csy" # cht, krn, nor: not supported by DeepL, ptb?

  fields="package version maintainer maintainer_url distributor distributor_url arch exclude_arch model exclude_model
    adminprotocol adminurl adminport firmware dsmuidir dsmappname dsmapppage dsmapplaunchname checkport allow_altport
    startable helpurl report_url support_center install_reboot install_dep_packages install_conflict_packages install_dep_services
    instuninst_restart_services startstop_restart_services start_dep_services silent_install silent_upgrade silent_uninstall install_type
    checksum package_icon package_icon_120 package_icon_128 package_icon_144 package_icon_256 thirdparty support_conf_folder
    auto_upgrade_from offline_install precheckstartstop os_min_ver os_max_ver beta ctl_stop ctl_install ctl_uninstall
    install_break_packages install_replace_packages use_deprecated_replace_mechanism description displayname"
  # local f=

  for f in $fields; do
    if [ -n "${!f}" ]; then  # indirect addressing with ! for f
      echo "$f=\"${!f}\"" >> INFO
    fi
  done
fi

lngFolder="$SCRIPTPATHinfo/package/ui/texts"
for lang in $langs; do
  descriptionINFO=""
  displaynameINFO=""
  if [[ -f "$lngFolder/$lang/lang.txt" ]]; then

    eval "$(grep "descriptionINFO=" "$lngFolder/$lang/lang.txt")"
    description="description_${lang}"
    if [ -n "${descriptionINFO}" ]; then
      echo "${description}=\"${descriptionINFO}\"" >> INFO
      if [[ "$lang" == "enu" ]]; then
        echo "description=\"${descriptionINFO}\"" >> INFO
      fi
    fi
    eval "$(grep "displaynameINFO=" "$lngFolder/$lang/lang.txt")"
    displayname="displayname_${lang}"
    if [ -n "${displaynameINFO}" ]; then
      echo "${displayname}=\"${displaynameINFO}\"" >> INFO
      if [[ "$lang" == "enu" ]]; then
        echo "displayname=\"${displaynameINFO}\"" >> INFO
      fi
    fi
  fi
done

if [[ "$1" != "" ]]; then # Generation without toolkit scripts
  # checksum  MD5 string to verify the package.tgz.
  return 0
fi

# Generation with toolkit:
[ "$(caller)" != "0 NULL" ] && return 0

if [[ "$1" == "" ]]; then
  pkg_dump_info
else
  echo "INFO.sh Error: pkg_dump_info not executed!"
  echo "pwd=$(/bin/pwd)"
  echo "ls -l: '$(ls -l)'"
fi

