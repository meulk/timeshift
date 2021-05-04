#!/bin/sh
#
#Install timeshift into ppanel 

Green="\e[0;32m"  
COL_NC="\e[0m"   
TICK="[${Green}✓${COL_NC}]"

ppaneldir="/var/etc/ppanels"

#Create directories if they don't exist
if [ ! -d "${ppaneldir}" ]; then
  mkdir -p "${ppaneldir}" 
fi

printf -- "\n${TICK} Downloading ${Green}timeshift.xml${COL_NC} from Github\n";
wget -O ${ppaneldir}/timeshift.xml "https://raw.githubusercontent.com/meulk/timeshift/main/timeshift.xml"
rm /tmp/ppsetup.sh
printf -- "\n";
exit 0;
