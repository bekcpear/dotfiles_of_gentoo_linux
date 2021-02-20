#!/bin/bash

# Performs a git pull on the current gentoo repo and verify signatures of the
# newly pulled commits. After than, regenerate the metadata cache
# Takes no argument.

WDIR=/var/db/repos/gentoo.git

echo "cd /var/db/repos/gentoo.git/gentoo"
cd /var/db/repos/gentoo.git/gentoo

BEGIN_COMMIT=$(git rev-list -n1 master)

echo "Pulling..."
#proxychains git pull
git pull

echo "Verifying..."
${WDIR}/verif-sign-until.sh $BEGIN_COMMIT
if [[ $? != 0 ]]; then
	echo "BEGIN COMMIT: "${BEGIN_COMMIT}
	exit 1
fi

for x in dtd glsa news xml-schema; do
	pushd ./metadata/${x}
	BEGIN_COMMIT=$(git rev-list -n1 master)
	#proxychains git pull
	git pull
	echo "Verifying ${x}..."
	${WDIR}/verif-sign-until.sh $BEGIN_COMMIT
	if [[ $? != 0 ]]; then
		echo "BEGIN COMMIT: "${BEGIN_COMMIT}
		popd
		exit 1
	fi
	popd
done

echo "Regenerating cache..."
egencache --jobs=30 --repo=gentoo --update --update-pkg-desc-index --update-use-local-desc -v

date -R > metadata/timestamp.chk
cat metadata/timestamp.chk
