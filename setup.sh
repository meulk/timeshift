#!/bin/sh
#
# Fix EPG times
# Timeshift Setup v2.0

# Regular Colors
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

#Calculate time offset between local time and the EPG creator which is based in Germany I'm guessing
#Currently returns +0200 during BST
OFFSET=$(TZ=Europe/Berlin date +%z)

clear
printf -- "${Yellow}EPG Timeshift v2.0 ${COL_NC}\n";
printf -- "\nStarting new installation \n\n";

#point it to the USB stick instead of the HDD
workdir="/media/usb/epg"
epgimport="/etc/epgimport"
installdir="/usr/script"

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

printf -- "This script will fix EPG offset issue for IPTV i.e. if your EPG is ahead or behind and showing wrong program information.\n\n";
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
url=$(grep -o 'http.*$' ${source} | cut -f 1 -d ']')
#get name from source file, remove illegal file characters with underscore and make lower case
name=$(grep -o 'catname=.*$' ${source} | cut -c10- | cut -f 1 -d '"' | \
sed -e 's|<|_|g; s|>|_|g; s|:|_|g; s|"|_|g; s|/|_|g; s|\\|_|g; s/|/_/g; s|?|_|g; s|*|_|g; s| |_|g')

#download (xmltv.sh) to filename $xmltvfilename - replace old time with new time
xmltvfilename="${workdir}/${name}.xml"

printf -- "\n${TICK} Downloading ${Green}xmltv.sh${COL_NC} from Github\n\n";
wget -O ${installdir}/xmltv.sh "https://raw.githubusercontent.com/meulk/timeshift/main/xmltv.sh"
sed -i "s|\\&|$url|" "${installdir}/xmltv.sh"
sed -i "s|dddddd|$xmltvfilename|; s|ssssss|$source|" "${installdir}/xmltv.sh"
chmod 755 ${installdir}/xmltv.sh

printf -- "\n${TICK} Downloading ${Green}uninstall.sh${COL_NC} from Github\n\n";
wget -O ${installdir}/uninstall.sh "https://raw.githubusercontent.com/meulk/timeshift/main/uninstall.sh"
sed -i "s|dddddd|$xmltvfilename|; s|ssssss|$source|" "${installdir}/uninstall.sh"
chmod 755 ${installdir}/uninstall.sh

#stop cron error
touch /etc/cron/crontabs/root
#Add cronjob to run script at 8:15am
crontab -l | { cat; echo "15 08 * * * /bin/sh /usr/script/xmltv.sh"; } | crontab -
printf -- "\n${TICK} Daily cron added to run script daily at 08:15am\n\n";
sleep 2

#testing bits download xml file here once
printf -- "\n${TICK} Downloading EPG data...${COL_NC}\n\n";
wget -O ${xmltvfilename} "${url}"
#printf -- "\n";

#Check only the first line instead of the whole file
HHMM=$(head -n 1 ${xmltvfilename} | grep -o 'start=".*$' | cut -c 23-27 | cut -f 1 -d '"')
printf -- "\n\nXML file HHMM is currently ${Red}$HHMM\n${COL_NC}";
sleep 2

if [ "$HHMM" = "+0000" ]; then
   sh ${installdir}/xmltv.sh

else
printf -- "\n${CROSS} ERROR: Script has been installed though it won't work until you follow one more step manually. Please make a note of following text\n";
printf -- "\nMy xml HHMM is: $HHMM and I want to adjust it by: $time\n";
printf -- "\nPlease follow the additional step mentioned in original post\n";
fi
rm /tmp/setup.sh
printf -- "\n";
exit 0;








