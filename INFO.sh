#!/bin/bash

if [[ "$1" == "" ]]; then # Generation with toolkit scripts
  source /pkgscripts-ng/include/pkg_util.sh
fi
package="autorun"
version="1.10.0-0003"
#beta="yes"
arch="noarch"
os_min_ver="7.0-40000"
# install_dep_packages="WebStation>=3.0.0-0323:PHP7.4>=7.4.18-0114:Apache2.4>=2.4.46-0122"
maintainer="Jan Reidemeister, Horst Schmid"
# maintainer_url=""
thirdparty="yes"
support_center="no"
dsmuidir="ui"
# distributor=""
# distributor_url=""
silent_upgrade="no"
# precheckstartstop="yes" # not working!!??
arch="noarch"
helpurl="http://www.synology-forum.de/showthread.html?18360-Autorun-fuer-ext.-Datentraeger"
support_url="https://github.com/reidemei/synology-autorun/issues"
dsmappname="SYNO.SDS._ThirdParty.App.autorun"
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
fi
# displayname=""  # if not set then $package will be used as displayname
# displayname_enu=""
# displayname_ger=""
description="Execute a script on external drive (USB / eSATA) when it's connected to the disk station."
description_enu="Execute a script on external drive (USB / eSATA) when it's connected to the disk station."
description_ger="Führt ein Skript auf einem externen Laufwerk (USB / eSATA) aus wenn dieses an die Diskstation angeschlossen wird."

if [[ "$1" != "" ]]; then # Generation without toolkit scripts
# copy of 'pkg_dump_info' from '/pkgscripts-ng/include/pkg_util.sh' ('local' removed):
	langs="enu cht chs krn ger fre ita spn jpn dan nor sve nld rus plk ptb ptg hun trk csy"
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

	for lang in $langs; do
		description="description_${lang}"
		if [ -n "${!description}" ]; then
			echo "${description}=\"${!description}\"" >> INFO
		fi
		displayname="displayname_${lang}"
		if [ -n "${!displayname}" ]; then
			echo "${displayname}=\"${!displayname}\"" >> INFO
		fi
	done
    # checksum  MD5 string to verify the package.tgz.
  return 0
fi

# Generation with toolkit:
[ "$(caller)" != "0 NULL" ] && return 0

if [[ "$1" == "" ]]; then
  pkg_dump_info
else
  echo "INFO.sh Error: pkg_dump_info not executed!"
  echo "pwd=$(pwd)"
  echo "ls -l: '$(ls -l)'"
fi

