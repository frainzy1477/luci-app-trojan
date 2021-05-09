#!/bin/sh
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/trojan_update.txt"
NAME=trojan
TSHARE=/usr/share/$NAME
MODELTYPE=$(uci get $NAME.config.download_core 2>/dev/null)
lang=$(uci get luci.main.lang 2>/dev/null)
source=$(uci get $NAME.config.download_source 2>/dev/null)

if [ -f /tmp/trojan-go.zip ];then
	rm -rf /tmp/trojan-go.zip >/dev/null 2>&1
fi

echo '' >/tmp/trojan_update.txt 2>/dev/null

rm -rf $TSHARE/core_down_complete /var/run/core_update_error 2>/dev/null

rm -rf $TSHARE/download_core_version 2>/dev/null

if [ $lang == "zh_cn" ];then
    echo "${LOGTIME} - 正在检查最新版本。。" >$LOG_FILE
elif [ $lang == "en" ] || [ $lang == "auto" ];then
    echo "${LOGTIME} - Checking latest version.." >$LOG_FILE
fi

version=`wget --no-check-certificate -qO- https://github.com/$source/tags | grep "/$source/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`

if [ $version ]; then
	echo $version > $TSHARE/download_core_version 2>&1 & >/dev/null
elif [ $version =="" ]; then
	echo 0 > $TSHARE/download_core_version 2>&1 & >/dev/null
fi

sleep 3

if [ -f $TSHARE/download_core_version ];then
	VER=$(sed -n 1p $TSHARE/download_core_version 2>/dev/null)
fi


update(){
	if [ -f /tmp/trojan-go/trojan-go-"$MODELTYPE".zip ];then
		rm -rf /tmp/trojan-go/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1
	fi
	if [ $lang == "zh_cn" ];then
		echo "${LOGTIME} - 开始下载 trojan-go 内核..." >$LOG_FILE
	elif [ $lang == "en" ] || [ $lang == "auto" ];then
		echo "${LOGTIME} - Starting trojan-go Core download" >$LOG_FILE
	fi
	mkdir p /tmp/trojan-go >/dev/null 2>&1
	cd /tmp/trojan-go
	wget --no-check-certificate  https://github.com/"$source"/releases/download/"$VER"/trojan-go-"$MODELTYPE".zip -O 2>&1 >1 /tmp/trojan-go/trojan-go-"$MODELTYPE".zip

	 if [ "$?" -eq "0" ]; then
		if [ $lang == "zh_cn" ];then
			echo "${LOGTIME} - 开始解压缩文件" >$LOG_FILE
		elif [ $lang == "en" ] || [ $lang == "auto" ];then
			echo "${LOGTIME} - Beginning to unzip file" >$LOG_FILE
		fi
		unzip /tmp/trojan-go/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1\
		&& rm -rf /tmp/trojan-go/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1\
		&& chmod 755 /tmp/trojan-go\
		&& chown root:root /tmp/trojan-go
		if [ $lang == "zh_cn" ];then
			echo "${LOGTIME} - 完成下载内核，正在更新..." >$LOG_FILE
		elif [ $lang == "en" ] || [ $lang == "auto" ];then
			echo "${LOGTIME} - Successfully downloaded core, updating now..." >$LOG_FILE
		fi
		mv /tmp/trojan-go/* /usr/bin >/dev/null 2>&1
		chmod +x /usr/bin/trojan-go 
		chmod +x /usr/bin/geoip.dat 
		chmod +x /usr/bin/geosite.dat 
		rm -rf /tmp/trojan-go >/dev/null 2>&1
		rm -rf $TSHARE/core_version >/dev/null 2>&1
		mv $TSHARE/download_core_version $TSHARE/core_version >/dev/null 2>&1

		if [ $lang == "zh_cn" ];then
			echo "${LOGTIME} - TrojanGo内核更新成功！" >$LOG_FILE
		elif [ $lang == "en" ] || [ $lang == "auto" ];then
			echo "${LOGTIME} - TrojanGo Core Update Successful" >$LOG_FILE
		fi
		sleep 2
		touch $TSHARE/core_down_complete >/dev/null 2>&1
		sleep 2
		rm -rf /var/run/core_update >/dev/null 2>&1
		echo "" > /tmp/trojan_update.txt >/dev/null 2>&1
	    else
		if [ $lang == "zh_cn" ];then
			echo "${LOGTIME} - 核心程序下载失败，请检查网络或稍后再试！" >$LOG_FILE
		elif [ $lang == "en" ] || [ $lang == "auto" ];then     
			echo "${LOGTIME} - Core Update Error" >$LOG_FILE
		fi
		rm -rf /tmp/trojan-go/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1
		echo "" > /tmp/trojan_update.txt >/dev/null 2>&1
		touch /var/run/core_update_error >/dev/null 2>&1
		fi
		if pidof $NAME >/dev/null; then
		   	/etc/init.d/$NAME restart >/dev/null
		fi
}
update


