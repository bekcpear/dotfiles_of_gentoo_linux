# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils multilib nsplugins unpacker

DESCRIPTION="Support for printing to ZjStream-based printers"
HOMEPAGE="http://foo2zjs.rkkda.com/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="test"
PROPERTIES="live"


RDEPEND=""
DEPEND=""

S="${WORKDIR}/${PN}"

src_unpack() {
	einfo "Fetching ${PN} tarball"
	wget "http://foo2zjs.rkkda.com/${PN}.tar.gz" || die
	tar zxf "${WORKDIR}/${PN}.tar.gz" || die

	eapply "${FILESDIR}/${PN}-udev.patch"\
		"${FILESDIR}/${PN}-usbbackend.patch"

	cd "${S}" || die

	einfo "Fetching additional files (firmware, etc)"
	emake getweb

	# Display wget output, downloading takes some time.
	sed -e '/^WGETOPTS/s/-q//g' -i getweb || die

	./getweb all || die
}

src_prepare() {
	default
}

src_install() {
	sleep 100000
	:
}

src_test() {
	# see bug 419787
	: ;
}
