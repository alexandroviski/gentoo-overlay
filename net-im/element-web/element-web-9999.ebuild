# Copyright 2009-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A glossy Matrix collaboration client for the web"
HOMEPAGE="https://element.io/"
LICENSE="Apache-2.0"
SLOT="0"
MATRIX_REACT_SDK="v3.13.1"
MATRIX_JS_SDK="v9.6.0"
SRC_URI="!build-online? (
	https://github.com/matrix-org/matrix-react-sdk/archive/${MATRIX_REACT_SDK}.tar.gz -> matrix-react-sdk-${MATRIX_REACT_SDK}.tar.gz
	https://github.com/matrix-org/matrix-js-sdk/archive/${MATRIX_JS_SDK}.tar.gz -> matrix-js-sdk-${MATRIX_JS_SDK}.tar.gz
) "

REPO="https://github.com/vector-im/element-web"
#ELEMENT_COMMIT_ID="ae245c9b1f06e79cec4829f8cd1555206b0ec8f2"

if [[ ${PV} = *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="${REPO}.git"
	EGIT_BRANCH="develop"
	DOWNLOAD=""
	IUSE="+build-online"
else
	IUSE="build-online"
	KEYWORDS="~amd64 ~x86"
	DOWNLOAD="${REPO}/archive/"
	if [ -z "$ELEMENT_COMMIT_ID" ]
	then
		DOWNLOAD+="v${PV}.tar.gz -> ${P}.tar.gz"
	else
		DOWNLOAD+="${ELEMENT_COMMIT_ID}.tar.gz -> ${PN}-${ELEMENT_COMMIT_ID}.tar.gz"
		S="${WORKDIR}/${PN}-${ELEMENT_COMMIT_ID}"
	fi
fi
SRC_URI+="${DOWNLOAD}"

RESTRICT="mirror build-online? ( network-sandbox )"

COMMON_DEPEND=""

RDEPEND="${COMMON_DEPEND}"

DEPEND="${COMMON_DEPEND}"

BDEPEND="
	${PYTHON_DEPS}
	sys-apps/yarn
	net-libs/nodejs
"

src_unpack() {
	if [ -z "$ELEMENT_COMMIT_ID" ]
	then
		if [ -f "${DISTDIR}/${P}.tar.gz" ]; then
			unpack "${P}".tar.gz || die
		else
			git-r3_src_unpack
		fi
	else
		unpack "${PN}-${ELEMENT_COMMIT_ID}.tar.gz" || die
	fi
}

src_configure() {
	export PATH="/usr/$(get_libdir)/node_modules/npm/bin/node-gyp-bin:$PATH"
	yarn config set disable-self-update-check true || die
	yarn config set nodedir /usr/include/node || die

	if ! use build-online
	then
		ONLINE_OFFLINE="--offline --frozen-lockfile"
		yarn config set yarn-offline-mirror "${DISTDIR}" || die
	fi

	einfo "Installing node_modules"
	node /usr/bin/yarn install ${ONLINE_OFFLINE} --no-progress || die

	pushd node_modules/matrix-js-sdk > /dev/null || die
		use build-online || tar -xf "${DISTDIR}/matrix-js-sdk-${MATRIX_JS_SDK}.tar.gz" --strip-components=1 --overwrite
		node /usr/bin/yarn install ${ONLINE_OFFLINE} --no-progress || die
	popd > /dev/null || die

	pushd node_modules/matrix-react-sdk > /dev/null || die
		use build-online || tar -xf "${DISTDIR}/matrix-react-sdk-${MATRIX_REACT_SDK}.tar.gz" --strip-components=1 --overwrite
		node /usr/bin/yarn install ${ONLINE_OFFLINE} --no-progress || die
	popd > /dev/null || die
}

src_compile() {
	node /usr/bin/yarn run build || die
}

src_install() {
	insinto /usr/share/element-web
	doins -r webapp/*
	dosym ../../etc/element-web/config.json /usr/share/element-web/config.json

	insinto /etc/element-web
	newins config.sample.json config.json
}

pkg_postinst() {
		elog
		elog "element-web provides only a web application ready to be served"
		elog "If you need a desktop application, consider element-desktop"
		elog
}
