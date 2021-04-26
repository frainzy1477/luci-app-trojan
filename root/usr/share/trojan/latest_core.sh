#!/bin/sh

new_version=`curl -L -k --retry 2 --connect-timeout 20 -o - https://api.github.com/repos/frainzy1477/trojan-go/releases/latest 2>/dev/null|grep -E 'tag_name' |grep -E 'v[0-9.]+' |awk -F ':'  '{
print $2}' | sed 's/\"//g' | sed 's/\,//g' | sed 's/\ //g'`
if [ "$?" -eq "0" ]; then
	rm -rf /usr/share/trojan/new_core
	if [ $new_version ]; then
		echo $new_version > /usr/share/trojan/new_core 2>&1 & >/dev/null
	else
		echo "0" > /usr/share/trojan/new_core 2>&1 & >/dev/null
	fi
fi

 