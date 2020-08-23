#!/bin/sh
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/trojan_update.txt"
MODELTYPE=$(uci get trojan.config.download_core 2>/dev/null)
lang=$(uci get luci.main.lang 2>/dev/null)
source=$(uci get trojan.config.download_source 2>/dev/null)

if [ -f /tmp/trojan.zip ];then
rm -rf /tmp/trojan.zip >/dev/null 2>&1
fi
echo '' >/tmp/trojan_update.txt 2>/dev/null
  
rm -rf /usr/share/trojan/core_down_complete 2>/dev/null

rm -rf /usr/share/trojan/download_core_version

if [ $lang == "zh_cn" ];then
         echo "  ${LOGTIME} - 正在检查最新版本。。" >$LOG_FILE
elif [ $lang == "en" ] || [ $lang == "auto" ];then
         echo "  ${LOGTIME} - Checking latest version.." >$LOG_FILE
fi

version=`wget -qO- https://github.com/$source/tags | grep "/$source/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`

if [ $version ]; then
echo $version > /usr/share/trojan/download_core_version 2>&1 & >/dev/null
elif [ $version =="" ]; then
echo 0 > /usr/share/trojan/download_core_version 2>&1 & >/dev/null
fi

sleep 3

if [ -f /usr/share/trojan/download_core_version ];then
VER=$(sed -n 1p /usr/share/trojan/download_core_version 2>/dev/null) 
fi


update(){

		if [ -f /tmp/trojan/trojan-go-"$MODELTYPE".zip ];then
		rm -rf /tmp/trojan/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1
		fi
		
		if [ $lang == "zh_cn" ];then
			 echo "  ${LOGTIME} - 开始下载 trojan 内核..." >$LOG_FILE
		elif [ $lang == "en" ] || [ $lang == "auto" ];then
			 echo "  ${LOGTIME} - Starting trojan Core download" >$LOG_FILE
		fi				
		mkdir p /tmp/trojan >/dev/null 2>&1
		cd /tmp/trojan
		wget --no-check-certificate  https://github.com/"$source"/releases/download/"$VER"/trojan-go-"$MODELTYPE".zip -O 2>&1 >1 /tmp/trojan/trojan-go-"$MODELTYPE".zip
	  
	   
	   if [ "$?" -eq "0" ]; then
			if [ $lang == "zh_cn" ];then
			 echo "  ${LOGTIME} - 开始解压缩文件" >$LOG_FILE
			elif [ $lang == "en" ] || [ $lang == "auto" ];then 
			 echo "  ${LOGTIME} - Beginning to unzip file" >$LOG_FILE
			fi
			   
		        unzip /tmp/trojan/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1\
		        && rm -rf /tmp/trojan/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1\
		        && chmod 755 /tmp/trojan\
		        && chown root:root /tmp/trojan 
 
			if [ $lang == "zh_cn" ];then
			   echo "  ${LOGTIME} - 完成下载内核，正在更新..." >$LOG_FILE
			   elif [ $lang == "en" ] || [ $lang == "auto" ];then
			   echo "  ${LOGTIME} - Successfully downloaded core, updating now..." >$LOG_FILE
			fi
			  
		   
			  #rm -rf /etc/trojan/trojan >/dev/null 2>&1
			  mv /tmp/trojan/trojan-go /etc/trojan/trojan >/dev/null 2>&1
			  mv /tmp/trojan/geoip.dat /etc/trojan/ >/dev/null 2>&1
			  mv /tmp/trojan/geosite.dat /etc/trojan/ >/dev/null 2>&1
			  rm -rf /tmp/trojan >/dev/null 2>&1
			  rm -rf /usr/share/trojan/core_version >/dev/null 2>&1
			  mv /usr/share/trojan/download_core_version /usr/share/trojan/core_version >/dev/null 2>&1

			 if [ $lang == "zh_cn" ];then
			  echo "  ${LOGTIME} - TrojanGo内核更新成功！" >$LOG_FILE
			 elif [ $lang == "en" ] || [ $lang == "auto" ];then
			  echo "  ${LOGTIME} - TrojanGo Core Update Successful" >$LOG_FILE
			 fi

			

		    sleep 2
		    touch /usr/share/trojan/core_down_complete >/dev/null 2>&1
		    sleep 2
		    rm -rf /var/run/core_update >/dev/null 2>&1
		    echo "" > /tmp/trojan_update.txt >/dev/null 2>&1
			
	    else
		  if [ $lang == "zh_cn" ];then
		  echo "  ${LOGTIME} - 核心程序下载失败，请检查网络或稍后再试！" >$LOG_FILE
		  elif [ $lang == "en" ] || [ $lang == "auto" ];then     
		  echo "  ${LOGTIME} - Core Update Error" >$LOG_FILE
		  fi
		  rm -rf /tmp/trojan/trojan-go-"$MODELTYPE".zip >/dev/null 2>&1
		  echo "" > /tmp/trojan_update.txt >/dev/null 2>&1
	    fi 
		
		if pidof trojan >/dev/null; then
		   	/etc/init.d/trojan restart >/dev/null		
		fi
}

update


