# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )
inherit desktop distutils-r1 systemd udev xdg

DESCRIPTION="A user-space daemon that allows you to manage your Razer peripherals."
HOMEPAGE="https://github.com/openrazer/openrazer"
SRC_URI="https://github.com/openrazer/openrazer/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="client"

DEPEND=""
RDEPEND="${DEPEND}
	dev-python/dbus-python[${PYTHON_USEDEP}]
	>=dev-python/daemonize-2.4[${PYTHON_USEDEP}]
	dev-python/notify2[${PYTHON_USEDEP}]
	dev-python/pygobject[${PYTHON_USEDEP}]
	dev-python/pyudev[${PYTHON_USEDEP}]
	dev-python/setproctitle[${PYTHON_USEDEP}]
	sys-apps/openrazer-drivers
	x11-libs/gtk+:3[introspection]
	x11-misc/xautomation
"
BDEPEND=""

python_prepare_all() {
	sed -i "s|##PREFIX##|${EROOT}/usr|" "daemon/resources/org.razer.service.in"
	sed -i "s|##PREFIX##|${EROOT}/usr|" "daemon/resources/openrazer-daemon.systemd.service.in"
	distutils-r1_python_prepare_all
}

python_compile() {
	pushd "daemon" > /dev/null || die
	distutils-r1_python_compile
	popd > /dev/null || die
	if use client; then
		pushd "pylib" > /dev/null || die
		distutils-r1_python_compile
		popd > /dev/null || die
	fi
}

python_install() {
	pushd "daemon" > /dev/null || die
	distutils-r1_python_install
	popd > /dev/null || die
	if use client; then
		pushd "pylib" > /dev/null || die
		distutils-r1_python_install
		popd > /dev/null || die
	fi
}

python_install_all() {
	#man page
	doman "daemon/resources/man/razer.conf.5"
	doman "daemon/resources/man/openrazer-daemon.8"

	#configuration example
	insinto /usr/share/openrazer
	newins "daemon/resources/razer.conf" razer.conf.example

	#exe
	exeinto /usr/bin
	newexe "daemon/run_openrazer_daemon.py" openrazer-daemon

	#dbus service
	insinto /usr/share/dbus-1/services
	newins "daemon/resources/org.razer.service.in" org.razer.service

	#udev rule
	udev_dorules "install_files/udev/99-razer.rules"
	exeinto $(get_udevdir)
	doexe "install_files/udev/razer_mount"

	#desktop menu
	domenu "install_files/desktop/openrazer-daemon.desktop"

	#openrc service
	#TODO

	#systemd service
	systemd_newunit "daemon/resources/openrazer-daemon.systemd.service.in" openrazer-daemon.service
}

pkg_postinst() {
	xdg_pkg_postinst
	udev_reload
}
