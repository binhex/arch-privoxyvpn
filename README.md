**Application**

[Privoxy](http://www.privoxy.org/)  
[OpenVPN](https://openvpn.net/)  

**Description**

Privoxy is a free non-caching web proxy with filtering capabilities for enhancing privacy, manipulating cookies and modifying web page data and HTTP headers before the page is rendered by the browser. Privoxy is a "privacy enhancing proxy", filtering web pages and removing advertisements. Privoxy can be customized by users, for both stand-alone systems and multi-user networks. Privoxy can be chained to other proxies and is frequently used in combination with Squid and can be used to bypass Internet censorship.

**Build notes**

Latest stable Privoxy release from Arch Linux repo.

**Usage**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 8118:8118 \
    --name=<container name> \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=<yes|no> \
    -e VPN_USER=<vpn username> \
    -e VPN_PASS=<vpn password> \
    -e VPN_PROV=<pia|airvpn|custom> \
    -e VPN_OPTIONS=<additional openvpn cli options> \
    -e LAN_NETWORK=<lan ipv4 network>/<cidr notation> \
    -e NAME_SERVERS=<name server ip(s)> \
    -e DEBUG=<true|false> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-privoxyvpn
```
&nbsp;
Please replace all user variables in the above command defined by <> with the correct values.

**Access application**

`http://<host ip>:8118`

**PIA example**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 8118:8118 \
    --name=privoxyvpn \
    -v /root/docker/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_USER=myusername \
    -e VPN_PASS=mypassword \
    -e VPN_PROV=pia \
    -e LAN_NETWORK=192.168.1.0/24 \
    -e NAME_SERVERS=209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1 \
    -e DEBUG=false \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-privoxyvpn
```
&nbsp;
**AirVPN provider**

AirVPN users will need to generate a unique OpenVPN configuration
file by using the following link https://airvpn.org/generator/

1. Please select Linux and then choose the country you want to connect to
2. Save the ovpn file to somewhere safe
3. Start the delugevpn docker to create the folder structure
4. Stop delugevpn docker and copy the saved ovpn file to the /config/openvpn/ folder on the host
5. Start delugevpn docker
6. Check supervisor.log to make sure you are connected to the tunnel

**AirVPN example**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 8118:8118 \
    --name=privoxyvpn \
    -v /root/docker/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_PROV=airvpn \
    -e LAN_NETWORK=192.168.1.0/24 \
    -e NAME_SERVERS=209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1 \
    -e DEBUG=false \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-privoxyvpn
```
&nbsp;
**Notes**

Please note this Docker image does not include the required OpenVPN configuration file and certificates. These will typically be downloaded from your VPN providers website (look for OpenVPN configuration files), and generally are zipped.

PIA users - The URL to download the OpenVPN configuration files and certs is:-

https://www.privateinternetaccess.com/openvpn/openvpn.zip

Once you have downloaded the zip (normally a zip as they contain multiple ovpn files) then extract it to /config/openvpn/ folder (if that folder doesn't exist then start and stop the docker container to force the creation of the folder).

If there are multiple ovpn files then please delete the ones you don't want to use (normally filename follows location of the endpoint) leaving just a single ovpn file and the certificates referenced in the ovpn file (certificates will normally have a crt and/or pem extension).

Due to Google and OpenDNS supporting EDNS Client Subnet it is recommended NOT to use either of these NS providers.
The list of default NS providers in the above example(s) is as follows:-

209.222.x.x = PIA
84.200.x.x = DNS Watch
37.235.x.x = FreeDNS
1.x.x.x = Cloudflare

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

`id <username>`
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Support forum](https://forums.unraid.net/topic/78028-support-binhex-privoxyvpn/)