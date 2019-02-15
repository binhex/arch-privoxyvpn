#!/bin/bash

mkdir -p /config/privoxy

if [[ ! -f "/config/privoxy/config" ]]; then

	echo "[info] Configuring Privoxy..."
	cp -R /etc/privoxy/ /config/

	LAN_IP=$(hostname -i)

	sed -i -e "s~confdir /etc/privoxy~confdir /config/privoxy~g" /config/privoxy/config
	sed -i -e "s~logdir /var/log/privoxy~logdir /config/privoxy~g" /config/privoxy/config
	sed -i -e "s~listen-address.*~listen-address ${LAN_IP}:8118~g" /config/privoxy/config

fi

# while loop to check ip and port
while true; do

	# reset triggers to negative values
	privoxy_running="false"
	ip_change="false"

	if [[ "${VPN_ENABLED}" == "yes" ]]; then

		# run script to check ip is valid for tunnel device (will block until valid)
		source /home/nobody/getvpnip.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then

			# check if privoxy is running, if not then skip shutdown of process
			if ! pgrep -fa "privoxy" > /dev/null; then

				echo "[info] Privoxy not running"

			else

				# mark as privoxy as running
				privoxy_running="true"

			fi

			if [[ "${privoxy_running}" == "false" ]]; then

				# run script to start privoxy
				source /home/nobody/privoxy.sh

			fi

		else

			echo "[warn] VPN IP not detected, VPN tunnel maybe down"

		fi

	else

		# check if privoxy is running, if not then start via privoxy.sh
		if ! pgrep -fa "privoxy" > /dev/null; then

			echo "[info] Privoxy not running"

			# run script to start privoxy
			source /home/nobody/privoxy.sh

		fi

	fi

	if [[ "${DEBUG}" == "true" && "${VPN_ENABLED}" == "yes" ]]; then
		echo "[debug] VPN IP is ${vpn_ip}"
	fi

	sleep 30s

done
