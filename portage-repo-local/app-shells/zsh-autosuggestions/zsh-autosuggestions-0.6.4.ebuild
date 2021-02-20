# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit readme.gentoo-r1

DESCRIPTION="Fish-like autosuggestions for zsh"
HOMEPAGE="https://github.com/zsh-users/zsh-autosuggestions"
SRC_URI="https://github.com/zsh-users/zsh-autosuggestions/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="app-shells/zsh"
DISABLE_AUTOFORMATTING=1
DOC_CONTENTS="In order to use ${CATEGORY}/${PN} add
source ${EPREFIX%/}/usr/share/zsh/site-functions/zsh-autosuggestions.zsh
at the end of your ~/.zshrc"

src_compile() {
	emake clean
	emake
}

src_install() {
	insinto /usr/share/zsh/site-functions
	doins zsh-autosuggestions.zsh
	readme.gentoo_create_doc
}

pkg_postinst() {
	readme.gentoo_print_elog
}
