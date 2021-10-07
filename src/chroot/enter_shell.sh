use start;
use box::user;
use run_prog;
function chroot::enter_shell() {

	local _mp;
	for _mp in dev proc sys; do {
		if ! mountpoint -q "$_distro_root/$_mp"; then {
			chroot::start;
			break;
		} fi
	} done

chroot::run_prog $(user::get_shell ${CUSER:-root}) || log::warn "Container environment shell exited with error code $?";
}
