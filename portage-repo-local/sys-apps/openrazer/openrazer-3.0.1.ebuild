# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )
inherit distutils-r1 udev

DESCRIPTION="A user-space daemon that allows you to manage your Razer peripherals."
HOMEPAGE="https://github.com/openrazer/openrazer"
SRC_URI="https://github.com/openrazer/openrazer/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=""
RDEPEND="${DEPEND}
	sys-apps/openrazer-drivers
"
BDEPEND=""

python_compile() {
	pushd "daemon" > /dev/null || die
	distutils-r1_python_compile
	popd > /dev/null || die
	pushd "pylib" > /dev/null || die
	distutils-r1_python_compile
	popd > /dev/null || die
}

python_install() {
	pushd "daemon" > /dev/null || die
	distutils-r1_python_install
	popd > /dev/null || die
	pushd "pylib" > /dev/null || die
	distutils-r1_python_install
	popd > /dev/null || die
}
