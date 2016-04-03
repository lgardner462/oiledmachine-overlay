# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="2"

inherit eutils toolchain-funcs git-r3 cmake-utils

MY_P=${P/pp/++}

DESCRIPTION="A tool to integrate C/C++ code with Lua"
HOMEPAGE="http://www.codenix.com/~tolua/"
SRC_URI=""

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 ppc ppc64 sparc x86"
IUSE="static"

RESTRICT="fetch"

RDEPEND="dev-lang/lua:5.2"
DEPEND="${RDEPEND}
	dev-util/cmake
	sys-apps/util-linux"

S=${WORKDIR}/${MY_P}

src_unpack() {
        EGIT_REPO_URI="https://github.com/waltervn/toluapp.git"
        EGIT_BRANCH="master"
        EGIT_COMMIT="51831803cdd0ddf72d9ccd54f6b111cf839ea157"
        git-r3_fetch
        git-r3_checkout
}

src_prepare() {
	#epatch "${FILESDIR}"/tolua++-1.0.93-lua-5_2.patch
	if use static; then
		true
	else
		sed -i -e "s|add_library(libtolua++|add_library(libtolua++ SHARED|" src/lib/CMakeLists.txt
	fi
	cmake-utils_src_prepare
}

src_configure() {
        local mycmakeargs=(
        )

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	#cmake-utils_src_install
	mkdir -p "${D}/usr/bin"
	mkdir -p "${D}/usr/include"
	mkdir -p "${D}/usr/$(get_libdir)"
	cd "${WORKDIR}/tolua++-1.0.93_build/bin"
	cp "tolua++" "${D}/usr/bin" || die

	cd "${WORKDIR}/tolua++-1.0.93_build/lib"
	if use static; then
		cp "libtolua++.a" "${D}/usr/$(get_libdir)" || die
	else
		cp "libtolua++.so" "${D}/usr/$(get_libdir)" || die
	fi

	cd "${WORKDIR}/tolua++-1.0.93/include"
	cp "tolua++.h" "${D}/usr/include" || die

	cd "${WORKDIR}/tolua++-1.0.93"
	dodoc README
}