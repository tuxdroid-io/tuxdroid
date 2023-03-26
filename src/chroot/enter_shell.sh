use start;
use run_prog;
function chroot::enter_shell() {

	local _mountpoint;
	for _mountpoint in dev proc sys; do {
		if ! mountpoint -q "$_distro_root/$_mountpoint" && ! grep -q " ${_mountpoint} " /proc/mounts; then {
			chroot::start;
			break;
		} fi
	} done

chroot::run_prog sh -c "cd && $(user::get_shell ${CUSER:-root}) -l" || log::warn "Container environment shell exited with error code $?";
}
