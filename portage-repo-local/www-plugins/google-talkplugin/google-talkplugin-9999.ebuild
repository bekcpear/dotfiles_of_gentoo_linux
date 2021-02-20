# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils multilib nsplugins unpacker

if [ "${PV}" != "9999" ]; then
	DEB_PATCH="1"
	#https://dl.google.com/linux/talkplugin/deb/dists/stable/main/binary-i386/Packages
	MY_URL="https://dl.google.com/linux/talkplugin/deb/pool/main/${P:0:1}/${PN}"
	MY_PKG="${PN}_${PV}-${DEB_PATCH}_i386.deb"
	SRC_URI="x86? ( ${MY_URL}/${MY_PKG} )
		amd64? ( ${MY_URL}/${MY_PKG/i386/amd64} )"
	KEYWORDS="-* ~amd64 ~x86"
else
	MY_URL="https://dl.google.com/linux/direct"
	MY_PKG="${PN}_current_i386.deb"
	SRC_URI=""
	#PROPERTIES="live"
fi

DESCRIPTION="Video chat browser plug-in for Google Talk"
HOMEPAGE="https://www.google.com/chat/video"
IUSE=""
SLOT="0"

#GoogleTalkPlugin binary contains openssl and celt
LICENSE="GPL-2"

#RESTRICT="bindist strip mirror"
RESTRICT="bindist strip"

RDEPEND=""
DEPEND=""

# nofetch means upstream bumped and thus needs version bump
#pkg_nofetch() {
#	if [[ ${OBSOLETE} = yes ]]; then
#		elog "This version is no longer available from Google and the license prevents mirroring."
#		elog "This ebuild is intended for users who already downloaded it previously and have problems"
#		elog "with ${PV}+. If you can get the distfile from e.g. another computer of yours, or search"
#		use amd64 && MY_PKG="${MY_PKG/i386/amd64}"
#		elog "it with google: https://www.google.com/search?q=intitle:%22index+of%22+${MY_PKG}"
#		elog "and copy ${MY_PKG} to your DISTDIR directory."
#	else
#		einfo "This version is no longer available from Google."
#		einfo "Note that Gentoo cannot mirror the distfiles due to license reasons, so we have to follow the bump."
#		einfo "Please file a version bump bug on https://bugs.gentoo.org (search	existing bugs for ${PN} first!)."
#	fi
#}

src_unpack() {
	local pkg="${A:=${MY_PKG}}"
	if [ "${PV}" = "9999" ]; then
		use amd64 && pkg="${pkg/i386/amd64}"
		einfo "Fetching ${pkg}"
		wget "${MY_URL}/${pkg}" || die
	fi
	unpacker ${pkg}
}

src_install() {
	sleep 1000000
	:
}
