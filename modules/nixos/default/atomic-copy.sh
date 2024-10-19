#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

src=$(readlink -f "$1")
dst="$2"

# Create $dst atomically to prevent partially copied files
# if this script is ever interrupted.
if ! test -e $dst; then
	dstTmp=$dst.tmp.$$
	cp -r $src $dstTmp
	mv $dstTmp $dst
fi
