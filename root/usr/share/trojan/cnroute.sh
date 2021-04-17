#!/bin/sh

mv /usr/share/trojan/china_v4.txt /usr/share/trojan/china.bak

china=`curl -Lfsm 9 https://cdn.jsdelivr.net/gh/f6UiINtMDSmglMK4/A9xehMB2/ht2ix0v4Aj/zp2XmWPY9R4 | base64 -d > /usr/share/trojan/china_v4.txt || curl -Lfsm 9 https://raw.githubusercontent.com/f6UiINtMDSmglMK4/A9xehMB2/master/ht2ix0v4Aj/zp2XmWPY9R4 | base64 -d > /usr/share/trojan/china_v4.txt`
if [ "$?" -eq "0" ]; then
	if [ $china ]; then
		rm -rf /usr/share/trojan/china_v4.bak 
	fi	
fi
rm -rf /usr/share/trojan/china_v4.bak 