use start;
use box::user;
use run_prog;
function chroot::enter_shell() {

	local _mp;
	for _mp in dev proc sys; do {
		if ! mountpoint -q "$_distro_root/$_mp"; then {
			chroot::start;
			return || break;
		} fi
	} done

	chroot::run_prog /bin/bash -l || log::warn "Container environment shell exited with error code $?";
}
