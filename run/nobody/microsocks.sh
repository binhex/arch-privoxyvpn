#!/bin/bash

# source script to get currently assigned vpn ip (vpn_ip)
source /root/getvpnip.sh

if [[ "${ENABLE_SOCKS}" == "yes" ]];then

	echo "[info] Attempting to start microsocks..."
	/usr/local/bin/microsocks -i "0.0.0.0" -p 9118 -u "${SOCKS_USER}" -P "${SOCKS_PASS}" -b "${vpn_ip}"

else

	if [[ "${DEBUG}" == "true" ]]; then
		echo "[info] microsocks set to disabled"
	fi

fi
