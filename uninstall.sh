#!/bin/bash
#
# Uninstall xmltv Timeshift v2.0
#

COL_NC="\e[0m"       # Text Reset
Yellow="\e[0;33m"       # Yellow

clear
printf -- "${Yellow}Uninstalling Timeshift scripts${COL_NC}\n";

#install directory
installdir="/usr/script"

xmltvfilename="dddddd"
url=$(grep -o 'url=".*$' ${installdir}/timeshift.sh | cut -c6- | cut -f 1 -d '"')
printf -- "\n$url\n";
source="ssssss"

# Removing epg data
rm ${xmltvfilename}.gz

sed -i "s|$xmltvfilename.gz|\\&|" $source
sed -i "s|\\&|$url|" $source

# Removing Cron
crontab -l | grep -v "15 08 * * * /bin/sh /usr/script/timeshift.sh" | crontab -

# Removing script
rm ${installdir}/xmltv.sh

printf -- "\n${TICK} Scripts and crontab successfully uninstalled and source file restored\n";
rm ${installdir}/uninstall.sh
printf -- "\n";
exit 0;
