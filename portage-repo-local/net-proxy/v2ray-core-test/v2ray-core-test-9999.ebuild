# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 systemd

DESCRIPTION="A platform for building proxies to bypass network restrictions."
HOMEPAGE="https://github.com/v2fly/v2ray-core"

EGIT_REPO_URI="https://github.com/v2fly/v2ray-core.git"

LICENSE="MIT"
SLOT="0"
IUSE="+tool"

BDEPEND=">=dev-lang/go-1.15:="
DEPEND=""
RDEPEND="!net-proxy/v2ray !net-proxy/v2ray-bin"

pkg_pretend() {
	cngoproxyset=0
	if [[ -e "${ROOT}"/etc/portage/mirrors ]]; then
		grep '^\s*goproxy\s' "${ROOT}"/etc/portage/mirrors >/dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			cngoproxyset=1
		fi
	fi
	if [[ ${cngoproxyset} -eq 0 ]]; then
		ewarn "You may need to set a goproxy for fetching go modules:"
		ewarn "  echo -e '\\\\ngoproxy https://goproxy.cn/' >> /etc/portage/mirrors"
		ewarn "Can safely ignore this warning if emerge succeeded."
	fi
}

src_compile() {
	go build -v -work -o "bin/v2ray" -trimpath -ldflags "-s -w" ./main || die
	if use tool; then
		go build -v -work -o "bin/v2ctl" -trimpath -ldflags "-s -w" -tags confonly ./infra/control/main || die
	fi
}

src_install() {
	dobin bin/v2ray
	if use tool; then
		dobin bin/v2ctl
	fi

	insinto /usr/share/v2ray
	doins release/config/*.dat

	insinto /etc/v2ray
	doins release/config/*.json

	newinitd "${FILESDIR}/v2ray.initd" v2ray
	systemd_newunit release/config/systemd/system/v2ray.service v2ray.service
	systemd_newunit release/config/systemd/system/v2ray@.service v2ray@.service
}
