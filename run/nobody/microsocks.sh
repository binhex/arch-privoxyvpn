#!/usr/bin/dumb-init /bin/bash

echo "[info] Attempting to start microsocks..."

microsocks_cli="nohup /usr/local/bin/microsocks -i "0.0.0.0" -p 9118"

if [[ -n "${SOCKS_USER}" ]]; then
	microsocks_cli="${microsocks_cli} -u ${SOCKS_USER} -P ${SOCKS_PASS}"
fi

if [[ "${VPN_ENABLED}" == "yes" ]]; then
	microsocks_cli="${microsocks_cli} -b ${vpn_ip}"
fi

${microsocks_cli} &

echo "[info] microsocks process started"
