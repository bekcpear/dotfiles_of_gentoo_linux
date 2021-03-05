# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 xdg cmake

DESCRIPTION="Qt-based interface for Optimus Manager"
HOMEPAGE="https://github.com/Shatur95/optimus-manager-qt"
SRC_URI="${HOMEPAGE}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
IUSE="plasma"
RESTRICT="test"

COMMON_DEPEND="
	dev-qt/qtcore:5
	dev-qt/qtx11extras:5
	dev-qt/qtsvg:5
	dev-qt/qtdbus:5
	plasma? (
		kde-plasma/plasma-desktop:5
		kde-frameworks/knotifications:5
		kde-frameworks/kiconthemes:5
	)"

DEPEND="
	${COMMON_DEPEND}
	dev-qt/linguist-tools:5
	kde-frameworks/extra-cmake-modules
	x11-libs/libXrandr"

RDEPEND="
	${COMMON_DEPEND}
	>=x11-misc/optimus-manager-1.4"

src_unpack() {
	default
	EGIT_REPO_URI=https://github.com/HatScripts/circle-flags
	git-r3_fetch ${EGIT_REPO_URI}
	git-r3_checkout ${EGIT_REPO_URI} ${S}/CircleFlags
}

src_configure() {
	if use plasma; then
		local mycmakeargs=(
			-DWITH_PLASMA=ON
		)
	fi
	cmake_src_configure
}

src_install() {
	default
	rm "${D}/usr/share/icons/hicolor/icon-theme.cache"
}
