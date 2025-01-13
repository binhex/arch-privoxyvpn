# Application

<!-- markdownlint-disable MD033 -->

[Privoxy](http://www.privoxy.org/)<br/>
[microsocks](https://github.com/rofl0r/microsocks)<br/>
[OpenVPN](https://openvpn.net/)<br/>
[WireGuard](https://www.wireguard.com/)

## Description

Privoxy is a free non-caching web proxy with filtering capabilities for enhancing privacy, manipulating cookies and modifying web page data and HTTP headers before the page is rendered by the browser. Privoxy is a "privacy enhancing proxy", filtering web pages and removing advertisements. Privoxy can be customized by users, for both stand-alone systems and multi-user networks. Privoxy can be chained to other proxies and is frequently used in combination with Squid and can be used to bypass Internet censorship.<br/>

microsocks is a SOCKS5 service that you can run on your remote boxes to tunnel connections through them, if for some reason SSH doesn't cut it for you. It's very lightweight, and very light on resources too: for every client, a thread with a stack size of 8KB is spawned. the main process basically doesn't consume any resources at all. The only limits are the amount of file descriptors and the RAM.<br/>

This Docker includes OpenVPN and WireGuard to ensure a secure and private connection to the Internet, including use of iptables to prevent IP leakage when the tunnel is down.

## Build notes

Latest stable Privoxy release from Arch Linux repo.<br/>
Latest stable microsocks release from GitHub.<br/>
Latest stable OpenVPN release from Arch Linux repo.<br/>
Latest stable WireGuard release from Arch Linux repo.

## Usage

```text
docker run -d \
    --cap-add=NET_ADMIN \
    -p 8118:8118 \
    -p 9118:9118 \
    -p 58946:58946 \
    -p 58946:58946/udp \
    --name=<container name> \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=<yes|no> \
    -e VPN_USER=<vpn username> \
    -e VPN_PASS=<vpn password> \
    -e VPN_PROV=<pia|airvpn|protonvpn|custom> \
    -e VPN_CLIENT=<openvpn|wireguard> \
    -e VPN_OPTIONS=<additional openvpn cli options> \
    -e LAN_NETWORK=<lan ipv4 network>/<cidr notation> \
    -e NAME_SERVERS=<name server ip(s)> \
    -e ENABLE_STARTUP_SCRIPTS=<yes|no> \
    -e ENABLE_PRIVOXY=<yes|no> \
    -e STRICT_PORT_FORWARD=<yes|no> \
    -e USERSPACE_WIREGUARD=<yes|no> \
    -e ENABLE_SOCKS=<yes|no> \
    -e SOCKS_USER=<socks username> \
    -e SOCKS_PASS=<socks password> \
    -e VPN_INPUT_PORTS=<port number(s)> \
    -e VPN_OUTPUT_PORTS=<port number(s)> \
    -e DEBUG=<true|false> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-privoxyvpn
```

Please replace all user variables in the above command defined by <> with the correct values.

## Access Privoxy

`http://<host ip>:8118`

## Access microsocks

`<host ip>:9118`

default credentials: admin/socks

## PIA example

```bash
docker run -d \
    --cap-add=NET_ADMIN \
    -p 8118:8118 \
    -p 9118:9118 \
    -p 58946:58946 \
    -p 58946:58946/udp \
    --name=privoxyvpn \
    -v /root/docker/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_USER=myusername \
    -e VPN_PASS=mypassword \
    -e VPN_PROV=pia \
    -e VPN_CLIENT=openvpn \
    -e LAN_NETWORK=192.168.1.0/24 \
    -e NAME_SERVERS=1.1.1.1,1.0.0.1 \
    -e ENABLE_STARTUP_SCRIPTS=no \
    -e ENABLE_PRIVOXY=yes \
    -e STRICT_PORT_FORWARD=no \
    -e USERSPACE_WIREGUARD=no \
    -e ENABLE_SOCKS=yes \
    -e SOCKS_USER=admin \
    -e SOCKS_PASS=socks \
    -e VPN_INPUT_PORTS=1234 \
    -e VPN_OUTPUT_PORTS=5678 \
    -e DEBUG=false \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-privoxyvpn
```

## OpenVPN

Please note this Docker image does not include the required OpenVPN configuration file and certificates. These will typically be downloaded from your VPN providers website (look for OpenVPN configuration files), and generally are zipped.

PIA users - The URL to download the OpenVPN configuration files and certs is:-

[PIA OpenVPN configuration](https://www.privateinternetaccess.com/openvpn/openvpn.zip)

Once you have downloaded the zip (normally a zip as they contain multiple ovpn files) then extract it to /config/openvpn/ folder (if that folder doesn't exist then start and stop the docker container to force the creation of the folder).

If there are multiple ovpn files then please delete the ones you don't want to use (normally filename follows location of the endpoint) leaving just a single ovpn file and the certificates referenced in the ovpn file (certificates will normally have a crt and/or pem extension).

## WireGuard

If you wish to use WireGuard (defined via 'VPN_CLIENT' env var value ) then due to the enhanced security and kernel integration WireGuard will require the container to be defined with privileged permissions and sysctl support, so please ensure you change the following docker options:-  <br/>

from

``` bash
    --cap-add=NET_ADMIN \
```

to

``` bash
    --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
    --privileged=true \
```

**PIA users** - The WireGuard configuration file will be auto generated and will be stored in ```/config/wireguard/wg0.conf``` AFTER the first run, if you wish to change the endpoint you are connecting to then change the ```Endpoint``` line in the config file (default is Netherlands).

**Other users** - Please download your WireGuard configuration file from your VPN provider, start and stop the container to generate the folder ```/config/wireguard/``` and then place your WireGuard configuration file in there.

## Notes

Due to Google and OpenDNS supporting EDNS Client Subnet it is recommended NOT to use either of these NS providers.
The list of default NS providers in the above example(s) is as follows:-

1.x.x.x = Cloudflare

---
**IMPORTANT**<br/>
Please note `VPN_INPUT_PORTS` is **NOT** to define the incoming port for the VPN, this environment variable is used to define port(s) you want to allow in to the VPN network when network binding multiple containers together, configuring this incorrectly with the VPN provider assigned incoming port COULD result in IP leakage, you have been warned!.

---
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

`id <username>`

---
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/78028-support-binhex-privoxyvpn/)