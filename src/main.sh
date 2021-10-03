use std::print::log;
use chroot;
use configure;
# TODO: Add starting ssh, x11, vnc
# TODO: Re-execute self as root1 namespace if not so. (nsenter)

function enter::ns_one() {
	

	if grep -qE '/dev/block/.* /data .*nosuid|/dev/block/.* /data .*nodev|/dev/block/.* /data .*noexec' /proc/mounts; then {
		mount -oremount,suid,dev,exec /data && SUID=true && return \
			|| log::warn "Tried to remount as suid but failed, so continuing...";
	} fi

	if test "${NS_ONE:-}" == "true"; then {
		return 0
	} fi

	function ns::cut_id() {
		local _str="$1";
		_str="${_str#*[}" && _str="${_str%]*}";
		echo "$_str";
	}

	if test "$(ns::cut_id "$(readlink -f /proc/1/ns/mnt)")" != \
		"$(ns::cut_id "$(readlink -f /proc/self/ns/mnt)")"; then {
		export NS_ONE=true;
		exec nsenter -t 1 "$0" "$@";

	} fi

}

function main() {
	#local _orig_arg=("$@");
	function parse_arg() {
		local _arg;
		for _arg in "$@"; do {
			case "$_arg" in
				--components=*)
					COMPONENTS="${_arg##*=}";
					shift;
				;;
				--root=*)
					ROOT="${_arg##*=}";
					shift;
				;;
				--user=*)
					CUSER="${_arg##*=}";
					shift;
				;;
				--distrib=*)
					DISTRIB="${_arg##*=}";
					shift
				;;

			esac
		} done

		_distro_root="$(readlink -f "${ROOT}")";
	}
	case "${!#}" in
		start)
			enter::ns_one "$@";
			parse_arg "$@";
			chroot::start
		;;
		stop)
			enter::ns_one "$@";
			parse_arg "$@";
			chroot::stop
		;;
		enter-shell)
			enter::ns_one "$@";
			parse_arg "$@";
			chroot::enter_shell;
		;;
		configure)
			enter::ns_one "$@";
			parse_arg "$@";
			chroot::start;
			distro::configure;


	esac
}

