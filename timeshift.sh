#!/bin/sh
#
# Timeshift v2.0

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

COL_NC="\e[0m"       # Text Reset

TICK="[${Green}✓${COL_NC}]"
CROSS="[${Red}✗${COL_NC}]"

#Return time offset between UTC and the EPG creator which is based in Germany I'm guessing
#Currently returns +0200 during BST
OFFSET=$(TZ=Europe/Berlin date +%z)

xmltvfilename="dddddd"
url="&"
time=$OFFSET
source="ssssss"

#Check on first run if XML file exists. It will be gzipped after this so wont exist on second run.
if [ ! -f "$xmltvfilename" ]; then
    printf -- "\n${TICK} Downloading new EPG data...${COL_NC}\n\n";
    wget -O ${xmltvfilename} "${url}"
fi

HHMMnew=$(head -n 1 ${xmltvfilename} | grep -o 'start=".*$' | cut -c 23-27 | cut -f 1 -d '"')
printf -- "${COL_NC}\n\nXML HHMM is currently set to ${Red}$HHMMnew${COL_NC}\n";

if [ "$HHMMnew" = "$time" ]; then
   printf -- "\n${COL_NC}${TICK} Time already set to $time nothing to do.\n\n"
exit 0;
  
else
printf -- "\n${CROSS} EPG Time set incorrectly${COL_NC}\n\n";

clock=$(date '+%H:%M:%S:')
printf -- "\n$clock ${Cyan}${Blink}CORRECTING TIME. PLEASE WAIT, IT COULD TAKE BETWEEN 10-50 MINUTES SO BE PATIENT...${COL_NC}\n"

sed -i "/+0000/ s//$time/g" ${xmltvfilename}
gzip -f  ${xmltvfilename} > ${xmltvfilename}.gz
sed -i "s|$url|$xmltvfilename.gz|g" $source
clock1=$(date '+%H:%M:%S:')

printf -- "\n\n${TICK} $clock1 ${Green}All done!${COL_NC}\n";
printf -- "\nTime in EPG XML file has been changed to ${Green}$time${COL_NC}\n\n";
printf -- "\nGo to EPG importer, Look for option named 'Clearing current EPG before import' and turn it to yes and Import EPG manually by pressing yellow button.\n\n"
exit 0;
fi

