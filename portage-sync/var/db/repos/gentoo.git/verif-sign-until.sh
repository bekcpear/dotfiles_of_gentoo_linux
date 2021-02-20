#!/bin/bash

# Easily verify signature of commits in a git repo, from HEAD until the
# specified commit. Will stop on verification failure.

# Example:
# verif-sign-until.sh HEAD~100

# TODO: use trust levels to error out on untrusted keys

for commit in $(git rev-list "$1..HEAD"); do
    msg=$(git --no-pager log -1 --format="%h %s << %ce" "$commit")
    echo "Verifying $msg"
    output=$(git verify-commit --raw "$commit" 2>&1)
    res=$?
    if [[ $res != 0 ]]; then
        echo "Verification failed!"
        git --no-pager log -1 --pretty=fuller "$commit"
        echo "${output}"
        if grep "\\[GNUPG:\\] EXPKEYSIG" <<< "$output"; then
            echo "... but expired keys are alright..."
        else
            exit 1
        fi
    fi
done
exit 0
