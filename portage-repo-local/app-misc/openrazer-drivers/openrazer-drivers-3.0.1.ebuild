# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MODULES_OPTIONAL_USE="modules"
MODULES_OPTIONAL_USE_IUSE_DEFAULT="1"
inherit linux-mod optfeature

ORAZER_P="openrazer-${PV}"
DESCRIPTION="A collection of kernel drivers for Razer devices."
HOMEPAGE="https://github.com/openrazer/openrazer"
SRC_URI="https://github.com/openrazer/openrazer/archive/refs/tags/v${PV}.tar.gz -> ${ORAZER_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

IUSE="dkms"
REQUIRED_USE="|| ( modules dkms )"

S="${WORKDIR%/}/${ORAZER_P}/driver"
MODULE_NAMES="
	razerkbd(kernel/drivers/hid)
	razermouse(kernel/drivers/hid)
	razerkraken(kernel/drivers/hid)
	razeraccessory(kernel/drivers/hid)
"
BUILD_TARGETS="clean modules"

src_compile() {
	[[ ${KV_DIR} != '' ]] || die "Empry kernel source directory path!"
	BUILD_PARAMS="-C ${KV_DIR} M=${S}"
	linux-mod_src_compile
}

src_install() {
	linux-mod_src_install
	if use dkms; then
		insinto /usr/src/openrazer-driver-${PV}
		doins ../Makefile ../install_files/dkms/dkms.conf
		insinto /usr/src/openrazer-driver-${PV}/driver
		doins Makefile *.c *.h
	fi
}

pkg_postinst() {
	linux-mod_pkg_postinst
	if use modules; then
		if [[ $(uname -r) != "${KV_FULL}" ]]; then
			ewarn "You have just built openrazer-drivers for kernel ${KV_FULL}, yet the currently running"
			ewarn "kernel is $(uname -r). If you intend to use these openrazer-drivers on the currently"
			ewarn "running machine, you will first need to reboot it into the kernel ${KV_FULL}, for"
			ewarn "which this module was built."
		else
			local i old
			local -a my_modules=( $(while read l; do echo ${l%(*}; done <<< "${MODULE_NAMES}") )
			for (( i = 0; i < ${#my_modules[@]}; ++i )); do
				if [[ -f /sys/module/${my_modules[i]}/version ]]; then
					old="$(< /sys/module/${my_modules[i]}/version)"
					break
				fi
			done
			if [[ ${old} != '' && ${old} != ${PV} ]]; then
				ewarn "You appear to have just upgraded openrazer-drivers from version v$old to v$PV."
				ewarn "However, the old version is still running on your system. In order to use the"
				ewarn "new version, you will need to remove the old module and load the new one. As"
				ewarn "root, you can accomplish this with the following commands:"
				ewarn
				ewarn "	# rmmod <module-name>"
				ewarn "	# modprobe <module-name>"
			fi
		fi  
	elif use dkms; then
		optfeature "For managing kernel modules." sys-kernel/dkms
	fi
}
