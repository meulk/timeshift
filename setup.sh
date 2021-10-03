#!/bin/sh
#
# Timeshift Setup v2.02
# Corrects IPTV EPG times on OpenPLi 8.1

set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

# Regular Colours
Red="\e[0;31m"          # Red
Green="\e[0;32m"        # Green
Yellow="\e[0;33m"       # Yellow
Blue="\e[0;34m"         # Blue
Purple="\e[0;35m"       # Purple
Cyan="\e[0;36m"         # Cyan
White="\e[0;37m"        # White

Blink="\e[5m"           #Blinking
Underlined="\e[4m"      #Underlined
Reversed="\e[7m"        #Inverted

## Reset
COL_NC="\e[0m"       # Text Reset

TICK="[${Green}✓${COL_NC}]"
CROSS="[${Red}✗${COL_NC}]"

#Return time offset between UTC and the EPG creator which is based in Germany I'm guessing
#Currently returns +0200 during BST
OFFSET=$(TZ=Europe/Berlin date +%z)

clear
printf -- "${Yellow}EPG Timeshift v2.02 ${COL_NC}\n";


#point it to the USB stick instead of the HDD
workdir="/media/usb/epg"
epgimport="/etc/epgimport"
installdir="/usr/script"
ppaneldir="/var/etc/ppanels"
#ppaneldir="/etc/enigma2/ppanels/"

printf -- "\nUninstalling previous version of this script \n\n";
sleep 2
# Remove old script data
rm ${epgimport}/new.EPG.sources.xml
rm ${workdir}/iptvepg.xml.gz

# Removing Previous Cronjob
cron=$(crontab -l | grep -F "15 08 * * * /bin/sh /usr/script/timeshift.sh " | wc -m)
if [ $cron -eq "0" ]; then
printf -- "\n${CROSS} No cronjob found\n\n";
else
crontab -l | grep -v "15 08 * * * /bin/sh /usr/script/timeshift.sh " | crontab -
printf -- "\n${TICK} Old cronjob removed\n\n";
fi
sleep 1
printf -- "\nStarting new installation \n\n";

#Create directories if they don't exist
if [ ! -d "${workdir}" ]; then
  mkdir -p "${workdir}" 
fi

if [ ! -d "${epgimport}" ]; then
  mkdir -p "${epgimport}" 
fi

if [ ! -d "${installdir}" ]; then
  mkdir -p "${installdir}" 
fi
if [ ! -d "${ppaneldir}" ]; then
  mkdir -p "${ppaneldir}" 
fi

printf -- "This script will correct any EPG offset issues for IPTV i.e. if your EPG is ahead or behind and showing wrong program information.\n\n";
sleep 2

count=$(ls -d ${epgimport}/*jmx.*.sources.xml* | wc -l)
if [ "$count" = "1" ]; then
   filename=$(find ${epgimport}/ -name "jmx.*.sources.xml" -exec basename {} \;)
   printf -- "${TICK} One Jedimaker playlist found: ${Green}$filename${COL_NC}, proceeding with installation...\n"
sleep 1
else
printf -- "\nEnter full file name from below list starting with jmx.XXXX.sources.xml, For example: You want to fix EPG offset for provider's playlist named IPTV in Jedimakerxtreme then you should look for file named jmx.IPTV.sources.xml\n"
find $epgimport/ -name "jmx.*.sources.xml" -exec basename {} \;
printf -- "\n";
read -p "Enter file name: " filename
fi

filename1=$(ls ${epgimport}/${filename} | xargs -n 1 basename)

if [ "$filename1" = "$filename" ]; then 
printf -- "\n";
else
printf -- "\n${CROSS} Wrong input, installation aborted. Try running the script again by typing ./setup.sh below and hit enter\n\n";
exit 0;
fi

printf -- "\nThere is a time difference of ${Red}$OFFSET${COL_NC} between the current EPG and local time.\n\n";
sleep 1

source="${epgimport}/$filename"
# get url from source file
#url=$(grep -o 'http.*$' ${source} | cut -f 1 -d ']')
url=$(grep -o "<url><\!\[\CDATA.*$" ${source} | cut -c 15- | cut -f 1 -d ']')
#get name from source file, remove illegal file characters with underscore and make lower case
name=$(grep -o 'catname=.*$' ${source} | cut -c10- | cut -f 1 -d '"' | \
sed -e 's|<|_|g; s|>|_|g; s|:|_|g; s|"|_|g; s|/|_|g; s|\\|_|g; s/|/_/g; s|?|_|g; s|*|_|g; s| |_|g')

xmltvfilename="${workdir}/${name}.xml"

printf -- "\n${TICK} Downloading ${Green}timeshift.sh${COL_NC} from Github\n\n";
wget -O ${installdir}/timeshift.sh "https://raw.githubusercontent.com/meulk/timeshift/main/timeshift.sh"
sed -i "s|\\&|$url|" "${installdir}/timeshift.sh"
sed -i "s|dddddd|$xmltvfilename|; s|ssssss|$source|" "${installdir}/timeshift.sh"
chmod 755 ${installdir}/timeshift.sh
printf -- "\n${TICK}${Green} Download Complete.\n\n";

printf -- "\n${TICK} Downloading ${Green}uninstall.sh${COL_NC} from Github\n\n";
wget -O ${installdir}/uninstall.sh "https://raw.githubusercontent.com/meulk/timeshift/main/uninstall.sh"
sed -i "s|dddddd|$xmltvfilename|; s|ssssss|$source|" "${installdir}/uninstall.sh"
chmod 755 ${installdir}/uninstall.sh
printf -- "\n${TICK}${Green} Download Complete.\n\n";

printf -- "\n${TICK} Downloading ${Green}timeshift.xml${COL_NC} from Github\n\n";
wget -O ${ppaneldir}/timeshift.xml "https://raw.githubusercontent.com/meulk/timeshift/main/timeshift.xml"
printf -- "\n${TICK}${Green} Download Complete.\n\n";

#stop cron error
#touch /etc/cron/crontabs/root
#mkdir -p /var/spool/cron/crontabs
#touch /var/spool/cron/crontabs/root

#Add cronjob to run script at 8:15am
crontab -l | { cat; echo "15 08 * * * /bin/sh /usr/script/timeshift.sh"; } | crontab -
printf -- "\n${TICK} Daily cronjob added to run script daily at 08:15am\n\n";
sleep 2

#Download latest XML EPG file
printf -- "\n${TICK} Downloading EPG data...${COL_NC}\n\n";
wget -O ${xmltvfilename} "${url}"
printf -- "\n${TICK}${Green} Download Complete.\n\n";

#Check only the first line instead of the whole file
HHMM=$(head -n 1 ${xmltvfilename} | grep -o 'start=".*$' | cut -c 23-27 | cut -f 1 -d '"')
printf -- "\n\nXML file HHMM is currently ${Red}$HHMM\n${COL_NC}";
sleep 2

if [ "$HHMM" = "+0000" ]; then
   sh ${installdir}/timeshift.sh

else
printf -- "\n${CROSS} ERROR: Script has been installed though time is currently set to something other than +0000\n";
printf -- "\nMy xml HHMM is: $HHMM and I want to adjust it by: $OFFSET\n";
fi
rm /tmp/setup.sh
printf -- "\n";
exit 0;
