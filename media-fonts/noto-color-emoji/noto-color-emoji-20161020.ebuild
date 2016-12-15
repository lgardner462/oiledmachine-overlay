# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils font python

DESCRIPTION="NotoColorEmoji is colored emojis"
HOMEPAGE="https://www.google.com/get/noto/#emoji-qaae-color"
NOTO_EMOJI_COMMIT="f09b63d1ecfe19b93021b0a283f1aa539b7230a9"
NOTO_TOOLS_COMMIT="7515ea34e496aac20a6080743332fafe0c9dd18b"
SRC_URI="https://github.com/googlei18n/noto-emoji/archive/${NOTO_EMOJI_COMMIT}.zip -> noto-emoji-${NOTO_EMOJI_COMMIT}.zip
         https://github.com/googlei18n/nototools/archive/${NOTO_TOOLS_COMMIT}.zip -> noto-tools-${NOTO_TOOLS_COMMIT}.zip"
# renamed from upstream's unversioned NotoColorEmoji-unhinted.zip
# version number based on the timestamp of most recently updated file in the zip

S="${WORKDIR}"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="zopflipng optipng reassign-ugly-text-emojis" #break utr#51
REQUIRED_USE="^^ ( zopflipng optipng )"

RDEPEND=">=media-libs/fontconfig-2.11.91
         >=x11-libs/cairo-1.14.6[colored-emojis]
	 media-libs/freetype[png]
         optipng? ( media-gfx/optipng )
	 zopflipng? ( app-arch/zopfli )
         dev-python/fonttools
         !media-founts/noto-color-emoji-bin
"

DEPEND="${RDEPEND}
	dev-python/six"

FONT_SUFFIX="ttf"
FONT_CONF=( "${FILESDIR}/01-notosans.conf" "${FILESDIR}/61-notosans.conf" )

S="${WORKDIR}/noto-emoji-${NOTO_EMOJI_COMMIT}"

src_unpack() {
	unpack ${A}
}

src_prepare() {
	sed -i -e "s|from fontTools.misc.py23 import unichr|from six import unichr|" "${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}/nototools/unicode_data.py" || die "patch failed 1"
	#FILES=$(grep -l -r -e "unichr" ./)
	#for f in $FILES
	#do
	#	einfo "Patching $f"
	#	sed -i -e "s|unichr|chr|g" "$f" || die "patch failed 2 $f"
	#done
	if use zopflipng ; then
		sed -i -e 's|emoji: \$(EMOJI_FILES)|MISSING_OPTIPNG = fail\nundefine MISSING_ZOPFLI\nemoji: \$(EMOJI_FILES)|g' Makefile
	else
		sed -i -e 's|emoji: \$(EMOJI_FILES)|MISSING_ZOPFLI = fail\nundefine MISSING_OPTIPNG\nemoji: \$(EMOJI_FILES)|g' Makefile
	fi

	#noto-tools patch
	#sed -i -e 's|-vs 2640 2642 2695|-vs 2640 2642 2695|g' Makefile
	if use reassign-ugly-text-emojis ; then
		cd "${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}"
		#epatch "${FILESDIR}"/nototools-gentoo-exclude-text-presentation.patch
		#epatch "${FILESDIR}"/nototools-gentoo-exclude-text-presentation-2.patch
		#epatch "${FILESDIR}"/nototools-gentoo-exclude-text-presentation-3.patch
		#epatch "${FILESDIR}"/nototools-gentoo-exclude-text-presentation-4.patch
		##epatch "${FILESDIR}"/nototools-gentoo-exclude-text-presentation-5.patch
		#epatch "${FILESDIR}"/nototools-gentoo-exclude-text-presentation-6.patch
	fi
}

src_compile() {
	if use optipng ; then
		export ZOPFLIPNG=
	else
		export OPTIPNG=
	fi

	export PYTHONPATH="${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}:${PYTHONPATH}"
	echo "PYTHONPATH=${PYTHONPATH}"
	export PATH="${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}/nototools:${PATH}"
	echo "PATH=${PATH}"
	emake || die "failed to compile font"
}

rebuild_fontfiles() {
        einfo "Refreshing fonts.scale and fonts.dir..."
        cd ${FONT_ROOT}
        mkfontdir -- ${FONT_TARGETS}
        if [ "${ROOT}" = "/" ] &&  [ -x /usr/bin/fc-cache ]
        then
                einfo "Updating font cache..."
                HOME="/root" /usr/bin/fc-cache -f ${FONT_TARGETS}
        fi
}

pkg_postinst() {
	eselect fontconfig enable 01-notosans.conf
	if use reassign-ugly-text-emojis ; then
		eselect fontconfig enable 61-notosans.conf
		ewarn "You may need to manually add exceptions to 61-notosans.conf based on fonts installed and what was in the serif and sans-serif section of 60-latin.conf and run \`fc-cache -fv\`."
	fi
	eselect fontconfig disable 70-no-bitmaps.conf
	ewarn "You may need to \`eselect fontconfig enable 01-notosans.conf\` manually and run \`fc-cache -fv\`."
	ewarn "You may need to \`eselect fontconfig disable 70-no-bitmaps.conf\` manually and run \`fc-cache -fv\`."
        rebuild_fontfiles
}