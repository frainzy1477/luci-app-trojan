#!/bin/sh

new_version=`curl -sL "https://github.com/frainzy1477/trojan-go/tags"| grep "/frainzy1477/trojan-go/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`
if [ "$?" -eq "0" ]; then
	cat /dev/null >  /usr/share/trojan/new_core
	if [ $new_version ]; then
		echo $new_version > /usr/share/trojan/new_core 2>&1 & >/dev/null
	else
		echo "0" > /usr/share/trojan/new_core 2>&1 & >/dev/null
	fi
fi


