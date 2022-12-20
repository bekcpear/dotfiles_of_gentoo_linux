#!/usr/bin/env bash
#

set -e

URL="https://gitlab.com/cwittlut/dotfiles_of_gentoo_linux/-/raw/"
# Commit ID:
URL+="@@COMMIT-HASH@@"
# Path:
URL+="/ryan-misc/Programs/Scripts/pb.sh"
SUM="@@SHA256-SUM@@"

if [[ $EUID == 0 ]]; then
  DST="/usr/local/bin/pb"
else
  DST="${HOME}${HOME:+/}.local/bin/pb"
fi

#
# **BEGIN**
# BASHFUNC00: _do [-p PREFIX] COMMAND {ARGUMENT}
#
#  Author: Ryan Qian <i@bitbili.net>
# License: GPL-2
#
# Print command and arguments to default stdout with
# a different FD number, so it won't affect or be affected by FD 1,
# and run it with all passed arguments
#
#
[[ -z ${_BASHFUNC_DO} ]] || return 0
_BASHFUNC_DO=1

if [[ -z ${_BASHFUNC_DO_OFD} ]]; then
  eval "exec {_BASHFUNC_DO_OFD}>&1"
fi

: ${_BASHFUNC_DO_DATE:=on}
: ${_BASHFUNC_DO_DATE_FORMAT:="+[%Y-%m-%d %H:%M:%S] "}

_do() {
  local prefix
  if [[ ${1} == "-p" ]]; then
    shift
    prefix="${1}"
    shift
  fi

  [[ -n ${1} ]] || return 0

  local msg='\x1b[1m\x1b[32m'
  if [[ ${_BASHFUNC_DO_DATE} == "on" ]]; then
    msg+=$(date "${_BASHFUNC_DO_DATE_FORMAT}")
  fi
  msg+="${prefix}${prefix:+ }"
  msg+='>>>\x1b[0m '
  msg+="${@}"
  eval ">&${_BASHFUNC_DO_OFD} echo -e \${msg}"
  "${@}"
}
#
# BASHFUNC00: _do [-p PREFIX] COMMAND {ARGUMENT}
# **END**
#

while [[ -e ${DST} ]]; do
  if [[ -f ${DST} ]] && [[ $(file -b --mime-type ${DST}) == "text/x-shellscript" ]]; then
    set -o pipefail
    if head ${DST} | grep 252075b9-149e-49fd-925d-f0ccccde7825 &>/dev/null; then
      echo "Refreshing '${DST}' to the latest version ..."
      break
    fi
  fi
  if [[ ! -t 0 ]]; then
    SELFURL="https://d0a.io/pb"
    echo "
    Attention: '${DST}' is an existing file,
    please download this installer with the following command:
     $ curl -Lfo pb-install ${SELFURL}
     OR
     $ wget -O pb-install ${SELFURL}
    and execute it directly in pipeless mode to enter your specified pb name:
     $ bash pb-install
" >&2
    exit 1
  fi
  read -p "Attention: '${DST}' is an existing file,"$'\n'"please enter another proper name for this pastebin script ('f' to overwrite it): " DST_NAME
  if [[ ${DST_NAME} == f ]]; then
    break
  fi
  DST="$(dirname ${DST})/$(basename ${DST_NAME})"
done

if [[ ! -d $(dirname ${DST}) ]]; then
  _do mkdir -p $(dirname ${DST})
fi

if command -v curl &>/dev/null; then
  set -- curl -Lfo ${DST} ${URL}
else
  set -- wget -O ${DST} ${URL}
fi

_do "${@}"
set -o pipefail
_SUM=$(_do sha256sum ${DST} | tee /dev/stderr)
_SUM=${_SUM%% *}
if [[ ${SUM} != ${_SUM} ]]; then
  echo "sha256sum mismatch, clean ..."
  _do rm -f ${DST}
  exit 1
fi
_do chmod +x "${DST}"

NOTINPATH=1
OIFS=$IFS
IFS=":"
PATHS=( ${PATH} )
IFS=$OIFS
for p in "${PATHS[@]}"; do
  _DST="${p%/}/$(basename ${DST})"
  if [[ -e ${_DST} ]]; then
    _SUM=$(sha256sum ${_DST})
    _SUM=${_SUM%% *}
    if [[ ${SUM} == ${_SUM} ]]; then
      NOTINPATH=0
      break
    fi
  fi
done

if [[ ${NOTINPATH} == 1 ]]; then
  echo -e "\x1b[33m" >&2
  echo "  The '$(dirname ${DST})' path is not in the PATH variable," >&2
  echo "  please add" >&2
  echo -e "    \x1b[1m\x1b[3mexport PATH=\$PATH:$(dirname ${DST})\x1b[0m\x1b[33m" >&2
  echo -e "  to your env file to make the '$(basename ${DST})' command available.\x1b[0m" >&2
fi
echo
echo "    Enter '$(basename ${DST}) -h' for help."
echo
