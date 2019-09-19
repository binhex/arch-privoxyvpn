#!/bin/bash

echo "[info] Attempting to start microsocks..."
nohup /usr/local/bin/microsocks -i "0.0.0.0" -p 9118 -u "${SOCKS_USER}" -P "${SOCKS_PASS}" -b "${vpn_ip}" &
echo "[info] microsocks process started"

