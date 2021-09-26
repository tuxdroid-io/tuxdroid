use chroot;
# TODO: Add starting ssh, x11, vnc
# TODO: Re-execute self as root1 namespace if not so. (nsenter)


function main() {
	local _distro_root="$(readlink -f "${ROOT}")";
	
	case "$1" in
		start)
			chroot::start
		;;
		stop)
			chroot::stop
		;;
		enter-shell)
			chroot::enter_shell;
		;;
	esac

}

