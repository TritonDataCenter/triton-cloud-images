#!/bin/bash

if [ $# -ne 1 ]; then
	echo "usage: $0 <image file>" >&2
	exit 1
fi

imagefile=$1; shift

imagename=$(basename ${imagefile})
imagedir=$(dirname ${imagefile})

case "${imagefile}" in
*.gz)
	;;
*)
	echo "Did you forget to compress the image first?" >&2
	exit 1
	;;
esac

case "${imagename}" in
almalinux-8*)
	name="almalinux-8"
	description="AlmaLinux 8.x"
	;;
almalinux-9*)
	name="almalinux-9"
	description="AlmaLinux 9.x"
	;;
rocky-8*)
	name="rockylinux-8"
	description="Rocky Linux 8.x"
	;;
rocky-9*)
	name="rockylinux-9"
	description="Rocky Linux 9.x"
	;;
ubuntu-22.04*)
	name="ubuntu-22.04"
	description="Ubuntu 22.04"
	;;
*)
	echo "Add support for ${imagename} to script." >&2
	exit 1
esac

uuid=$(uuid)
published_at=$(date '+%Y-%m-%dT%H:%M:%SZ')
sha1=$(shasum ${imagefile} | awk '{print $1}')
size=$(ls -l ${imagefile} | awk '{print $5}')
# Extract e.g. "20230516" from "almalinux-8.7-smartos-20230516.x86_64.raw.gz"
version=${imagename##*-}
version=${version%%.*}

sed \
	-e "s,@DESCRIPTION@,${description},g" \
	-e "s,@NAME@,${name},g" \
	-e "s,@PUBLISHED_AT@,${published_at},g"\
	-e "s,@SHA1@,${sha1},g" \
	-e "s,@SIZE@,${size},g" \
	-e "s,@UUID@,${uuid},g" \
	-e "s,@VERSION@,${version},g" \
	< $(dirname $0)/manifest.in \
	> ${imagedir}/${imagename/x86_64.raw.gz/json}
