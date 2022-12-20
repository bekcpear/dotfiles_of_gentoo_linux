#!/bin/bash
#

p=$(dirname $(realpath $0))
p=${p%.tools}
g="/var/lib/z16"
s=$(sha256sum ${p}pb | cut -d' ' -f1)
h=$(git -C ${g} log --pretty=format:%H ${p#${g}/}pb | head -1)

c=$(eval "sed -E 's/@@COMMIT-HASH@@/${h}/;s/@@SHA256-SUM@@/${s}/' ${p}.tools/install.sh")
c="${c//\'/\'\\\'\'}"

. ~/walletinfo
token=$(kwallet-query -f ${wfolder_gitlab} -r ${wentry_gitlab} ${wname})
eval "curl --request PUT 'https://gitlab.com/api/v4/snippets/2473971' \
     --header 'Content-Type: application/json' \
     --header 'PRIVATE-TOKEN: ${token}' \
     -d '
{
  \"title\": \"pb.sh installation script\",
  \"files\": [
    {
      \"action\": \"update\",
      \"content\": \"${c//\"/\\\"}\"
    }
  ]
}
'"
