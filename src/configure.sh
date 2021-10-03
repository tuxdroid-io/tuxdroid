use chroot::run_prog;

function distro::configure() {


    : "${DISTRIB:="archlinux"}";

    # Install packages
    if test $DISTRIB == archlinux; then
	    echo 'Server = http://sg.mirror.archlinuxarm.org/$arch/$repo' > "$_distro_root/etc/pacman.d/mirrorlist";
    else
	echo 'Server = http://mirror.xeonbd.com/manjaro/arm-stable/$repo/$arch' > "$_distro_root/etc/pacman.d/mirrorlist";
    fi	
    	local _key;
	# Enable pacman stuff
    	for _key in "DisableDownloadTimeout"; do {
		if grep -q "^#${_key}" "$_distro_root/etc/pacman.conf"; then {
			sed -i "s|^#${_key}|${_key}|" "$_distro_root/etc/pacman.conf";
		} else {
			sed -i "s|^\[options\]|\[options\]\n${_key}|" \
				"$_distro_root/etc/pacman.conf";
		} fi
	} done
	# Disable pacman stuff
    	for _key in "CheckSpace"; do {
		sed -i "s|^${_key}|#${_key}|" "$_distro_root/etc/pacman.conf";
	} done

	CUSER=root chroot::run_prog pacman-key --init;
	local _keyring _found_keyring;
	for _keyring in archlinuxarm archlinux manjaro-arm; do {
		if test -e "$_distro_root/usr/share/pacman/keyrings/$_keyring"; then {
			_found_keyring+=($_keyring);
		} fi
	} done
	CUSER=root chroot::run_prog pacman-key --populate "${_found_keyring[@]}";

	local ARCHLINUX_PACKAGES=(
		sudo
		xorg
		xdg-utils
		xdg-desktop-portal
		gnome-keyring
		python
		base
		base-devel
		htop
		firefox
		neovim
		strace
		tree
		lsof
		wget
		rsync
		usbutils
		git
		github-cli
		file
		coreutils
		e2fsprogs
		grep
		wget
		cdrtools
		squashfs-tools
		xclip
		scrot
		neofetch
		busybox
		fish
		code
		feh
		ranger
		openssh
		tigervnc
	)
	if test $DISTRIB == manjaro; then
		ARCHLINUX_PACKAGES+=(manjaro-release);
	fi

	CUSER=root chroot::run_prog pacman -Syyuu --noconfirm --needed "${ARCHLINUX_PACKAGES[@]}";

    log::info "Configuring LOCALE";
	echo 'en_US.UTF-8 UTF-8' > "$_distro_root/etc/locale.gen";
	echo 'LANG=en_US.UTF-8' > "$_distro_root/etc/locale.conf";
	CUSER=root chroot::run_prog locale-gen;
    local LOCALE="en_US.UTF-8";
#    if test -e "$_distro_root/usr/share/xbps.d"; then
#	return
#    fi
    if echo ${LOCALE} | grep -q '\.'; then
        local inputfile=$(echo ${LOCALE} | awk -F. '{print $1}')
        local charmapfile=$(echo ${LOCALE} | awk -F. '{print $2}')
        CUSER=root chroot::run_prog localedef -i ${inputfile} -c -f ${charmapfile} ${LOCALE}
    fi

    # Time
    CUSER=root chroot::run_prog ln -sf \
	    "/usr/share/zoneinfo/Asia/Dhaka" "/etc/localtime";
    hwclock --systohc;

    log::info "Configuring AXON";

    if ! grep -q axon "$_distro_root/etc/group"; then
	    CUSER=root chroot::run_prog groupadd --gid 60000 axon;
	    CUSER=root chroot::run_prog useradd --uid 60000 --gid 60000 \
		    --create-home --shell /bin/bash axon;
	    echo 'axon:q' | CUSER=root chroot::run_prog chpasswd;

    fi

    log::info "Configuring SU";
    local item pam_su
    for item in /etc/pam.d/su /etc/pam.d/su-l
    do
        pam_su="${_distro_root}/${item}"
        if [ -e "${pam_su}" ]; then
            if ! grep -q '^auth.*sufficient.*pam_succeed_if.so uid = 0 use_uid quiet$' "${pam_su}"; then
                sed -i '1,/^auth/s/^\(auth.*\)$/auth\tsufficient\tpam_succeed_if.so uid = 0 use_uid quiet\n\1/' "${pam_su}"
            fi
        fi
    done
 
    log::info "Configuring SUDO";
	local _sudo_str="axon ALL=(ALL:ALL) NOPASSWD:ALL";
	if ! grep -q "$_sudo_str" "$_distro_root/etc/sudoers"; then
		echo "$_sudo_str" >> "$_distro_root/etc/sudoers";
	fi


#	CUSER=root chroot::run_prog localepurge
}
