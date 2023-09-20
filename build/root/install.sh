#!/bin/bash

# exit script if return code != 0
set -e

# release tag name from buildx arg, stripped of build ver using string manipulation
RELEASETAG="${1//-[0-9][0-9]/}"

# target arch from buildx arg
TARGETARCH="${2}"

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${TARGETARCH}" ]]; then
	echo "[warn] Target architecture name from build arg is empty, exiting script..."
	exit 1
fi

# note do NOT download build scripts - inherited from int script with envvars common defined


# pacman packages
####

# define pacman packages
pacman_packages="base-devel privoxy"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages=""

# call aur install script (arch user repo)
source aur.sh

# github release - microsocks
####

# download and compile microsocks
github.sh --install-path "/tmp/compile" --github-owner "rofl0r" --github-repo "microsocks" --compile-src 'make install'

# container perms
####

# define comma separated list of paths
install_paths="/etc/privoxy,/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

export ENABLE_SOCKS=$(echo "${ENABLE_SOCKS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_SOCKS}" ]]; then
	echo "[info] ENABLE_SOCKS defined as '${ENABLE_SOCKS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_SOCKS not defined (via -e ENABLE_SOCKS), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_SOCKS="no"
fi

export ENABLE_PRIVOXY=$(echo "${ENABLE_PRIVOXY}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_PRIVOXY}" ]]; then
	echo "[info] ENABLE_PRIVOXY defined as '${ENABLE_PRIVOXY}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[warn] ENABLE_PRIVOXY not defined (via -e ENABLE_PRIVOXY), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_PRIVOXY="no"
fi

if [[ "${ENABLE_SOCKS}" == "yes" ]]; then

	export SOCKS_USER=$(echo "${SOCKS_USER}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
	if [[ ! -z "${SOCKS_USER}" ]]; then
		echo "[info] SOCKS_USER defined as '${SOCKS_USER}'" | ts '%Y-%m-%d %H:%M:%.S'
	else
		echo "[warn] SOCKS_USER not defined (via -e SOCKS_USER), disabling authentication for microsocks" | ts '%Y-%m-%d %H:%M:%.S'
		export SOCKS_USER=""
	fi

	if [[ -n "${SOCKS_USER}" ]]; then

		export SOCKS_PASS=$(echo "${SOCKS_PASS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
		if [[ ! -z "${SOCKS_PASS}" ]]; then
			echo "[info] SOCKS_PASS defined as '${SOCKS_PASS}'" | ts '%Y-%m-%d %H:%M:%.S'
		else
			echo "[warn] SOCKS_PASS not defined (via -e SOCKS_PASS), defaulting to 'socks'" | ts '%Y-%m-%d %H:%M:%.S'
			export SOCKS_PASS="socks"
		fi

	fi
fi

export APPLICATION="privoxy"

EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# call cleanup script
cleanup.sh
