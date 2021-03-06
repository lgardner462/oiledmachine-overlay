# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit mono-env nupkg

HOMEPAGE="https://github.com/nant/${NAME}"
DESCRIPTION=".NET build tool"
LICENSE="GPL-2"

EGIT_COMMIT="19bec6eca205af145e3c176669bbd57e1712be2a"
EGIT_BRANCH="master"
GITHUBNAME="nant/nant"
GITHUBACC=${GITHUBNAME%/*}
GITHUBREPO=${GITHUBNAME#*/}
GITFILENAME=${GITHUBREPO}-${GITHUBACC}-${PV}-${EGIT_COMMIT}
GITHUB_ZIP="https://api.github.com/repos/${GITHUBACC}/${GITHUBREPO}/zipball/${EGIT_COMMIT} -> ${GITFILENAME}.zip"
SRC_URI="${GITHUB_ZIP} https://github.com/mono/mono/raw/master/mcs/class/mono.snk"
S="${WORKDIR}/${GITFILENAME}"

SLOT="0"

KEYWORDS="~amd64 ~x86"
IUSE="+net45 developer nupkg debug"
USE_DOTNET="net45"
REQUIRED_USE="|| ( ${USE_DOTNET} )"

RDEPEND=">=dev-lang/mono-4.4.0.40
	!dev-dotnet/nant
	nupkg? ( dev-dotnet/nuget )
        "
#	dev-dotnet/log4net
DEPEND="${RDEPEND}
	virtual/pkgconfig
"

SLN_FILE=NAnt.sln
METAFILETOBUILD="${S}/${SLN_FILE}"

# This build is not parallel build friendly
#MAKEOPTS="${MAKEOPTS} -j1"

src_unpack() {
	default_src_unpack
	mv "${WORKDIR}/${GITHUBACC}-${GITHUBREPO}-"* "${WORKDIR}/${GITFILENAME}" || die
}

src_prepare() {
	eapply_user
}

src_compile() {
	exbuild "${METAFILETOBUILD}"
	enuspec "${FILESDIR}/${SLN_FILE}.nuspec"
}

src_install() {
	DIR=""
	if use debug; then
		DIR="Debug"
	else
		DIR="Release"
	fi

	insinto "/usr/share/nant/"
	doins build/${DIR}/*

	make_wrapper nant "mono /usr/share/nant/NAnt.exe"

	enupkg "${WORKDIR}/NAnt.0.93.5019.nupkg"

	#has its own package
	rm "${D}/usr/share/nant/log4net.dll"

	dodoc README.txt
}

