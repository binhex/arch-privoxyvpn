#!/bin/bash

echo "[info] Attempting to start microsocks..."
if [[ "${VPN_ENABLED}" == "yes" ]]; then
	nohup /usr/local/bin/microsocks -i "0.0.0.0" -p 9118 -b "${vpn_ip}" &
else
	nohup /usr/local/bin/microsocks -i "0.0.0.0" -p 9118 &
fi
echo "[info] microsocks process started"
