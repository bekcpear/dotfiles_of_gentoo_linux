#!/bin/bash
#

p=$(dirname $(realpath $0))
p=${p%.tools}
g="/var/lib/z16"
s=$(sha256sum ${p}pb | cut -d' ' -f1)
h=$(git -C ${g} log --pretty=format:%H ${p#${g}/}pb | head -1)

t=$(mktemp -u)
c=$(eval "sed -E 's/@@COMMIT-HASH@@/${h}/;s/@@SHA256-SUM@@/${s}/' ${p}.tools/install.sh")
c=$(<<<"${c}" sed 's/\\/\\\\/g')
c=$(<<<"${c}" sed ':a;N;$!ba;s/\n/\\n/g')
echo -n '
{
  "files": [
    {
      "action": "update",
      "file_path": "pb-install.sh",
      "content": "' >${t}
echo -n "${c//\"/\\\"}" >>${t}
echo '"
    }
  ]
}' >>${t}
trap 'rm -f ${t}' EXIT

. ~/walletinfo
token=$(pass show ${snippets_token_path})
eval "curl --request PUT \
     https://gitlab.com/api/v4/snippets/2473971 \
     --header 'Content-Type: application/json' \
     --header 'PRIVATE-TOKEN: ${token}' \
     -d @${t}"

# Gist:
#eval "curl --verbose -X PATCH \
#  -H 'Content-Type: application/json' \
#  -H 'Accept: application/vnd.github+json' \
#  -H 'Authorization: Bearer ${token}'\
#  -H 'X-GitHub-Api-Version: 2022-11-28' \
#  https://api.github.com/gists/758db48a1393b70e18db23e76ba3709f \
#  -d @${t}"
