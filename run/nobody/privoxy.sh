#!/bin/bash

if [[ "${privoxy_running}" == "false" ]]; then

	echo "[info] Attempting to start Privoxy..."

	# run Privoxy (daemonized, non-blocking)
	/usr/bin/privoxy /config/privoxy/config

	# make sure process privoxy DOES exist
	retry_count=30
	while true; do

		if ! pgrep -x "privoxy" > /dev/null; then

			retry_count=$((retry_count-1))
			if [ "${retry_count}" -eq "0" ]; then

				echo "[warn] Wait for Privoxy process to start aborted"
				break

			else

				if [[ "${DEBUG}" == "true" ]]; then
					echo "[debug] Waiting for Privoxy process to start..."
				fi

				sleep 1s

			fi

		else

			echo "[info] Privoxy process started"
			break

		fi

	done

	echo "[info] Waiting for Privoxy process to start listening on port 8118..."

	while [[ $(netstat -lnt | awk "\$6 == \"LISTEN\" && \$4 ~ \".8118\"") == "" ]]; do
		sleep 0.1
	done
	
	echo "[info] Privoxy process listening on port 8118"
fi

# set privoxy ip to current vpn ip (used when checking for changes on next run)
privoxy_ip="${vpn_ip}"
