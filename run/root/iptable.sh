#!/bin/bash

# change openvpn config 'tcp-client' to compatible iptables 'tcp'
if [[ "${VPN_PROTOCOL}" == "tcp-client" ]]; then
	export VPN_PROTOCOL="tcp"
fi

# identify docker bridge interface name by looking at routing to
# vpn provider remote endpoint (first ip address from name 
# lookup in /root/start.sh)
docker_interface=$(ip route show to match "${remote_dns_answer_first}" | grep -P -o -m 1 '[a-zA-Z0-9]+\s?+$' | tr -d '[:space:]')
if [[ "${DEBUG}" == "true" ]]; then
	echo "[debug] Docker interface defined as ${docker_interface}"
fi

# identify ip for docker bridge interface
docker_ip=$(ifconfig "${docker_interface}" | grep -P -o -m 1 '(?<=inet\s)[^\s]+')
if [[ "${DEBUG}" == "true" ]]; then
	echo "[debug] Docker IP defined as ${docker_ip}"
fi

# identify netmask for docker bridge interface
docker_mask=$(ifconfig "${docker_interface}" | grep -P -o -m 1 '(?<=netmask\s)[^\s]+')
if [[ "${DEBUG}" == "true" ]]; then
	echo "[debug] Docker netmask defined as ${docker_mask}"
fi

# convert netmask into cidr format
docker_network_cidr=$(ipcalc "${docker_ip}" "${docker_mask}" | grep -P -o -m 1 "(?<=Network:)\s+[^\s]+")
echo "[info] Docker network defined as ${docker_network_cidr}"

# ip route
###

# split comma separated string into list from LAN_NETWORK env variable
IFS=',' read -ra lan_network_list <<< "${LAN_NETWORK}"

# process lan networks in the list
for lan_network_item in "${lan_network_list[@]}"; do

	# strip whitespace from start and end of lan_network_item
	lan_network_item=$(echo "${lan_network_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

	echo "[info] Adding ${lan_network_item} as route via docker ${docker_interface}"
	ip route add "${lan_network_item}" via "${DEFAULT_GATEWAY}" dev "${docker_interface}"

done

echo "[info] ip route defined as follows..."
echo "--------------------"
ip route
echo "--------------------"

# input iptable rules
###

# set policy to drop ipv4 for input
iptables -P INPUT DROP

# set policy to drop ipv6 for input
ip6tables -P INPUT DROP 1>&- 2>&-

# accept input to/from docker containers (172.x range is internal dhcp)
iptables -A INPUT -s "${docker_network_cidr}" -d "${docker_network_cidr}" -j ACCEPT

# accept input to vpn gateway
iptables -A INPUT -i "${docker_interface}" -p $VPN_PROTOCOL --sport $VPN_PORT -j ACCEPT

# additional port list for scripts or container linking
if [[ ! -z "${ADDITIONAL_PORTS}" ]]; then

	# split comma separated string into list from ADDITIONAL_PORTS env variable
	IFS=',' read -ra additional_port_list <<< "${ADDITIONAL_PORTS}"

	# process additional ports in the list
	for additional_port_item in "${additional_port_list[@]}"; do

		# strip whitespace from start and end of additional_port_item
		additional_port_item=$(echo "${additional_port_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

		echo "[info] Adding additional incoming port ${additional_port_item} for ${docker_interface}"

		# accept input to additional port for "${docker_interface}"
		iptables -A INPUT -i "${docker_interface}" -p tcp --dport "${additional_port_item}" -j ACCEPT
		iptables -A INPUT -i "${docker_interface}" -p tcp --sport "${additional_port_item}" -j ACCEPT

	done

fi

# process lan networks in the list
for lan_network_item in "${lan_network_list[@]}"; do

	# strip whitespace from start and end of lan_network_item
	lan_network_item=$(echo "${lan_network_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

	# accept input to privoxy
	iptables -A INPUT -i "${docker_interface}" -p tcp -s "${lan_network_item}" -d "${docker_network_cidr}" -j ACCEPT

done

# accept input icmp (ping)
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

# accept input to local loopback
iptables -A INPUT -i lo -j ACCEPT

# accept input to tunnel adapter
iptables -A INPUT -i "${VPN_DEVICE_TYPE}" -j ACCEPT

# forward iptable rules
###

# set policy to drop ipv4 for forward
iptables -P FORWARD DROP

# set policy to drop ipv6 for forward
ip6tables -P FORWARD DROP 1>&- 2>&-

# set policy to nat traffic from opened port @ vpn provider to plex
iptables -t nat -I PREROUTING -p tcp --dport 60474 -j REDIRECT --to-ports 32400

# output iptable rules
###

# set policy to drop ipv4 for output
iptables -P OUTPUT DROP

# set policy to drop ipv6 for output
ip6tables -P OUTPUT DROP 1>&- 2>&-

# accept output to/from docker containers (172.x range is internal dhcp)
iptables -A OUTPUT -s "${docker_network_cidr}" -d "${docker_network_cidr}" -j ACCEPT

# accept output from vpn gateway
iptables -A OUTPUT -o "${docker_interface}" -p $VPN_PROTOCOL --dport $VPN_PORT -j ACCEPT

# additional port list for scripts or container linking
if [[ ! -z "${ADDITIONAL_PORTS}" ]]; then

	# split comma separated string into list from ADDITIONAL_PORTS env variable
	IFS=',' read -ra additional_port_list <<< "${ADDITIONAL_PORTS}"

	# process additional ports in the list
	for additional_port_item in "${additional_port_list[@]}"; do

		# strip whitespace from start and end of additional_port_item
		additional_port_item=$(echo "${additional_port_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

		echo "[info] Adding additional outgoing port ${additional_port_item} for ${docker_interface}"

		# accept output to additional port for lan interface
		iptables -A OUTPUT -o "${docker_interface}" -p tcp --dport "${additional_port_item}" -j ACCEPT
		iptables -A OUTPUT -o "${docker_interface}" -p tcp --sport "${additional_port_item}" -j ACCEPT

	done

fi

# process lan networks in the list
for lan_network_item in "${lan_network_list[@]}"; do

	# strip whitespace from start and end of lan_network_item
	lan_network_item=$(echo "${lan_network_item}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')

	# accept output from privoxy
	iptables -A OUTPUT -o "${docker_interface}" -p tcp -s "${docker_network_cidr}" -d "${lan_network_item}" -j ACCEPT

done

# accept output for icmp (ping)
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# accept output from local loopback adapter
iptables -A OUTPUT -o lo -j ACCEPT

# accept output from tunnel adapter
iptables -A OUTPUT -o "${VPN_DEVICE_TYPE}" -j ACCEPT

echo "[info] iptables defined as follows..."
echo "--------------------"
iptables -S 2>&1 | tee /tmp/getiptables
chmod +r /tmp/getiptables
echo "--------------------"

# change iptable 'tcp' to openvpn config compatible 'tcp-client' (this file is sourced)
if [[ "${VPN_PROTOCOL}" == "tcp" ]]; then
	export VPN_PROTOCOL="tcp-client"
fi
