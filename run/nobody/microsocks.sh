#!/bin/bash

echo "[info] Attempting to start microsocks..."
if [[ "${VPN_ENABLED}" == "yes" ]]; then
	nohup /usr/local/bin/microsocks -i "0.0.0.0" -p 9118 -u "${SOCKS_USER}" -P "${SOCKS_PASS}" -b "${vpn_ip}" &
else
	nohup /usr/local/bin/microsocks -i "0.0.0.0" -p 9118 -u "${SOCKS_USER}" -P "${SOCKS_PASS}" &
fi
echo "[info] microsocks process started"
