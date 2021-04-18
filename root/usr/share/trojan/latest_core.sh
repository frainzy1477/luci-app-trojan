#!/bin/sh

new_version=`curl -sL "https://github.com/frainzy1477/trojan_go/tags"| grep "/frainzy1477/trojan_go/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`

if [ "$?" -eq "0" ]; then
rm -rf /usr/share/trojan/trojan_core_new
if [ $new_version ]; then
echo $new_version > /usr/share/trojan/trojan_core_new 2>&1 & >/dev/null
else
echo "0" > /usr/share/trojan/trojan_core_new 2>&1 & >/dev/null
fi
fi

 