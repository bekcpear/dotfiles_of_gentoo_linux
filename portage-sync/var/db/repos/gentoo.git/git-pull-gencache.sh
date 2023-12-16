#!/bin/bash

# Performs a git pull on the current gentoo repo and verify signatures of the
# newly pulled commits. After than, regenerate the metadata cache
# Takes no argument.

set -e

REPO_PATH="/var/db/repos/gentoo.git/gentoo"
CONTINUED_COMMIT=/var/db/repos/gentoo.git/CONTINUED_COMMIT
LAST_COMMIT=

function verify-sign-until() {
	local dir=${1}
	shift
	commits=( $(git rev-list "$1..HEAD") )
	declare -i i=${#commits[@]}-1 len=0
	for (( ; i > -1; i-- )); do
		commit=${commits[i]}
		msg=$(git --no-pager log -1 --format="%h %s (%cr) << %ce" "$commit")
		echo "Verifying $msg"
		res=0
		output=$(git verify-commit --raw "$commit" 2>&1) || res=$?
		if [[ $res != 0 ]]; then
			echo "Verification failed!"
			git --no-pager log -1 --pretty=fuller "$commit"
			echo "${output}"
			if grep "\\[GNUPG:\\] EXPKEYSIG" <<< "$output"; then
				echo "... but expired keys are alright..."
			else
				echo -n ${dir}:${LAST_COMMIT} >${CONTINUED_COMMIT}
				return 1
			fi
		fi
		LAST_COMMIT=${commit}
	done
	return 0
}

echo "cd ${REPO_PATH}"
eval "cd ${REPO_PATH}"

if [[ -e ${CONTINUED_COMMIT} ]]; then
	LAST_C=$(cat ${CONTINUED_COMMIT})
	LAST_C_DIR=${LAST_C%:*}
	LAST_COMMIT=${LAST_C##*:}
	pushd ${LAST_C_DIR}
	echo "Verifying unverified commits..."
	eval "verify-sign-until ${LAST_C_DIR} ${LAST_COMMIT}"
	if [[ $? != 0 ]]; then
		exit 1
	fi
	popd
fi

LAST_COMMIT=$(git rev-list -n1 master)
echo -n .:${LAST_COMMIT} >${CONTINUED_COMMIT}

echo "Pulling..."
git pull

echo "Verifying..."
eval "verify-sign-until . ${LAST_COMMIT}"
if [[ $? != 0 ]]; then
	exit 1
fi

for x in dtd glsa news xml-schema; do
	pushd ./metadata/${x}
	LAST_COMMIT=$(git rev-list -n1 master)
	echo -n ./metadata/${x}:${LAST_COMMIT} >${CONTINUED_COMMIT}
	git pull
	echo "Verifying ${x}..."
	eval "verify-sign-until ./metadata/${x} ${LAST_COMMIT}"
	if [[ $? != 0 ]]; then
		popd
		exit 1
	fi
	popd
done
rm -f ${CONTINUED_COMMIT}

echo "Regenerating cache..."
egencache --jobs=30 --repo=gentoo --update --update-pkg-desc-index --update-use-local-desc -v

date -R > metadata/timestamp.chk
cat metadata/timestamp.chk
