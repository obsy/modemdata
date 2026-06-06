#!/bin/sh

IP=$1
ARG=$2

error() {
	case "$ARG" in
		"params")
			cat <<EOF
{
"csq":"",
"signal":"",
"operator_name":"",
"operator_mcc":"",
"operator_mnc":"",
"country":"",
"mode":"",
"registration":"",
"lac_dec":"",
"lac_hex":"",
"cid_dec":"",
"cid_hex":"",
"addon":[]
}
EOF
			;;
		"product")
			cat <<EOF
{
"vendor":"",
"product":"",
"revision":"",
"imei":"",
"iccid":"",
"imsi":""
}
EOF
			;;
		*)
			echo "{}"
			;;
	esac
	exit 0
}

getvaluen() {
	echo $(awk -F[\<\>] '/<'$2'>/ {print $3}' /tmp/$1 | sed 's/[^0-9]//g')
}

getvaluens() {
	echo $(awk -F[\<\>] '/<'$2'>/ {print $3}' /tmp/$1 | sed 's/[^0-9-]//g')
}

getvalue() {
	echo $(awk -F[\<\>] '/<'$2'>/ {print $3}' /tmp/$1)
}

addon() {
	[ -n "$ADDON" ] && ADDON="$ADDON,"
	ADDON="$ADDON"'{"idx":'$1',"key":"'$2'","value":"'${3//$'\r'/}'"}'
}

product() {
	VENDOR="Huawei"
	device=$(getvalue device-information DeviceName)
	if [ -n "$device" ]; then
		class=$(getvalue device-information Classify)
		PRODUCT="$device $class"
		T1=$(getvalue device-information SoftwareVersion)
		T2=$(getvalue device-information WebUIVersion)
		REVISION="${T1}/${T2}"
		IMEI=$(getvalue device-information Imei)
		ICCID=$(getvalue device-information Iccid)
		IMSI=$(getvalue device-information Imsi)
	else
		device=$(getvalue device-basic_information devicename)
		class=$(getvalue device-basic_information classify)
		[ -n "$device" ] && PRODUCT="$device $class"
	fi

	cat <<EOF
{
"vendor":"${VENDOR}",
"product":"${PRODUCT}",
"revision":"${REVISION}",
"imei":"${IMEI}",
"iccid":"${ICCID}",
"imsi":"${IMSI}"
}
EOF
}

params() {
	RSSI=$(getvaluen device-signal rssi)
	if [ -n "$RSSI" ]; then
		addon 35 "RSSI" "$RSSI dBm"
		CSQ=$(((-1*RSSI + 113)/2))
		CSQ_PER=$((CSQ * 100/31))
	else
		CSQ_PER=$(getvaluen monitoring-status SignalStrength)
		[ -n "$CSQ_PER" ] && CSQ=$(((CSQ_PER * 31)/100))
	fi

	COPS=$(getvalue net-current-plmn FullName)
	COPS_NUM=$(getvaluen net-current-plmn Numeric)
	COPS_MCC=$(echo "$COPS_NUM" | cut -c1-3)
	COPS_MNC=$(echo "$COPS_NUM" | cut -c4- )
	COUNTRY=""
	[ -n "$COPS_NUM" ] && COUNTRY=$(awk -F[\;] '/^'$COPS_NUM';/ {print $2}' /usr/share/modemdata/libs/mccmnc.dat)

	T=$(getvaluen monitoring-status CurrentNetworkType)
	case $T in
		1)  MODE="GSM";;
		2)  MODE="GPRS";;
		3)  MODE="EDGE";;
		4)  MODE="WCDMA";;
		5)  MODE="HSDPA";;
		6)  MODE="HSUPA";;
		7)  MODE="HSPA";;
		8)  MODE="TDSCDMA";;
		9)  MODE="HSPA+";;
		10) MODE="EVDO rev. 0";;
		11) MODE="EVDO rev. A";;
		12) MODE="EVDO rev. B";;
		13) MODE="1xRTT";;
		14) MODE="UMB";;
		15) MODE="1xEVDV";;
		16) MODE="3xRTT";;
		17) MODE="HSPA+64QAM";;
		18) MODE="HSPA+MIMO";;
		19) MODE="LTE";;
		21) MODE="IS95A";;
		22) MODE="IS95B";;
		23) MODE="CDMA1x";;
		24) MODE="EVDO rev. 0";;
		25) MODE="EVDO rev. A";;
		26) MODE="EVDO rev. B";;
		27) MODE="Hybrid CDMA1x";;
		28) MODE="Hybrid EVDO rev. 0";;
		29) MODE="Hybrid EVDO rev. A";;
		30) MODE="Hybrid EVDO rev. B";;
		31) MODE="EHRPD rev. 0";;
		32) MODE="EHRPD rev. A";;
		33) MODE="EHRPD rev. B";;
		34) MODE="Hybrid EHRPD rev. 0";;
		35) MODE="Hybrid EHRPD rev. A";;
		36) MODE="Hybrid EHRPD rev. B";;
		41) MODE="WCDMA (UMTS)";;
		42) MODE="HSDPA";;
		43) MODE="HSUPA";;
		44) MODE="HSPA";;
		45) MODE="HSPA+";;
		46) MODE="DC-HSPA+";;
		61) MODE="TD SCDMA";;
		62) MODE="TD HSDPA";;
		63) MODE="TD HSUPA";;
		64) MODE="TD HSPA";;
		65) MODE="TD HSPA+";;
		81) MODE="802.16E";;
		101) MODE="LTE";;
		*)  MODE="-";;
	esac

	STATUS=$(getvaluen monitoring-status ConnectionStatus)
	#[ "x$STATUS" = "x901" ] && REG="1"
	REG="1"
	SIMSTATUS=$(getvaluen monitoring-status SimStatus)
	[ "$SIMSTATUS" != "1" ] && REG="SIM error"

	LAC_DEC=$(getvalue net-signal-para Lac)
	if [ -n "$LAC_DEC" ]; then
		LAC_HEX=$(printf %0X $LAC_DEC)
	else
		getfile "http://$IP/config/deviceinformation/add_param.xml" /tmp/add-param
		LAC_HEX=$(getvalue add-param lac)
		LAC_DEC=$(printf %d "0x${LAC_HEX}")
		rm /tmp/add-param
	fi

	CID_HEX=$(getvalue net-signal-para CellID)
	if [ -n "$CID_HEX" ]; then
		CID_DEC=$(printf %d "0x${CID_HEX}")
	else
		CID_DEC=$(getvalue device-signal cell_id)
		[ -n "$CID_DEC" ] && CID_HEX=$(printf %0X $CID_DEC)
	fi

	if [ "x$MODE" = "xLTE" ]; then
		RSRP=$(getvaluens device-signal rsrp)
		[ -n "$RSRP" ] && addon 36 "RSRP" "$RSRP dBm"
		RSRQ=$(getvaluens device-signal rsrq)
		[ -n "$RSRQ" ] && addon 37 "RSRQ" "$RSRQ dB"
		SINR=$(getvaluens device-signal sinr)
		[ -n "$SINR" ] && addon 38 "SINR" "$SINR dB"
	else
		RSCP=$(getvaluens device-signal rscp)
		[ -z "$RSCP" ] && RSCP=$(getvaluens net-signal-para Rscp)
		[ -n "$RSCP" ] && addon 35 "RSCP" "$RSCP dBm"
		ECIO=$(getvaluens net-signal-para ecio)
		[ -z "$ECIO" ] && ECIO=$(getvaluens net-signal-para Ecio)
		[ -n "$ECIO" ] && addon 36 "ECIO" "$ECIO dB"
	fi

	PCI=$(getvalue device-signal pci)
	[ -n "$PCI" ] && addon 33 "PCI" "$PCI"

	cat <<EOF
{
"csq":"$CSQ",
"signal":"$CSQ_PER",
"operator_name":"$COPS",
"operator_mcc":"$COPS_MCC",
"operator_mnc":"$COPS_MNC",
"country":"$COUNTRY",
"mode":"$MODE",
"registration":"$REG",
"lac_dec":"$LAC_DEC",
"lac_hex":"$LAC_HEX",
"cid_dec":"$CID_DEC",
"cid_hex":"$CID_HEX",
"addon":[$ADDON]
}
EOF
}

cleanup() {
	for f in $files webserver/token; do
		nf=$(echo $f | sed 's!/!-!g')
		[ -e "/tmp/$nf" ] && rm /tmp/$nf
	done
	[ -e "$cookie" ] && rm $cookie
}

getfile() {
	if [ -n "$UCLIENT" ]; then
		$UCLIENT -O "$2" ${3:+--header "$3"} "$1" >/dev/null 2>&1
	elif [ -n "$WGET" ]; then
		$WGET -O "$2" ${3:+--header "$3"} "$1"   >/dev/null 2>&1
	elif [ -n "$CURL" ]; then
		$CURL -o "$2" ${3:+-H "$3"} "$1" 2>/dev/null
	else
		cleanup
		error
	fi
}

[ -z "$IP" ] && error
[ -z "$ARG" ] && error

WGET=""
CURL=""
UCLIENT=""
[ -e "/usr/libexec/wget-ssl" ] && WGET="/usr/libexec/wget-ssl -q -t 3"
[ -e "/usr/libexec/wget-nossl" ] && WGET="/usr/libexec/wget-nossl -q -t 3"
[ -e "/usr/bin/curl" ] && CURL="/usr/bin/curl -s --retry 3"
if [ -z "$WGET" ] && [ -z "$CURL" ]; then
	[ -e "/bin/uclient-fetch" ] && UCLIENT="/bin/uclient-fetch -q"
fi
if [ -z "$WGET" ] && [ -z "$CURL" ] && [ -z "$UCLIENT" ]; then
	error
fi

cookie=$(mktemp)
getfile "http://$IP/api/webserver/token" /tmp/webserver-token
token=$(getvaluen webserver-token token)
if [ -z "$token" ]; then
	getfile "http://$IP/api/webserver/SesTokInfo" /tmp/webserver-token
	sesinfo=$(getvalue webserver-token SesInfo)
fi
if [ -z "$sesinfo" ]; then
	if [ -n "$UCLIENT" ]; then
		cleanup
		error
	elif [ -n "$WGET" ]; then
		$WGET -O /dev/null --keep-session-cookies --save-cookies $cookie "http://$IP/html/home.html"
	else
		$CURL -o /dev/null -c "$cookie" "http://$IP/html/home.html"
	fi
fi

files="device/signal monitoring/status net/current-plmn net/signal-para device/information device/basic_information"
for f in $files; do
	nf=$(echo $f | sed 's!/!-!g')
	if [ -n "$token" ]; then
		getfile "http://$IP/api/$f" /tmp/$nf "__RequestVerificationToken: $token"
	elif [ -n "$sesinfo" ]; then
		getfile "http://$IP/api/$f" /tmp/$nf  "Cookie: $sesinfo"
	else
		if [ -n "$WGET" ]; then
			$WGET -O /tmp/$nf "http://$IP/api/$f" --load-cookies=$cookie >/dev/null 2>&1
		elif [ -n "$CURL" ]; then
			$CURL -o "/tmp/$nf" -b "$cookie" "http://$IP/api/$f" 2>/dev/null
		else
			cleanup
			error
		fi
	fi
done

case "$ARG" in
	"params")
		params
		cleanup
		;;
	"product")
		product
		cleanup
		;;
	*)
		cleanup
		error
		;;
esac

exit 0
