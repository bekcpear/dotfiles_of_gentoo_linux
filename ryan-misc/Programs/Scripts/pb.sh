#!/bin/bash
#
# Author: cwittlut <i@bitbili.net>
#
# TODO port to wayland clipboard

set -e

PB_URL="https://fars.ee/"

function _show_help(){
  echo "
Usage:  pb.sh [<PATH>]
        <some output> | pb.sh

    -h  show this help

This script will upload the clipboard contents if the argument is omitted (under X11).
"
}

if [[ ${1} == "-h" ]]; then
  _show_help
  exit 0
elif [[ -e ${1} ]]; then
  _PATH=${1}
elif [[ -n ${1} ]]; then
  echo "Wrong parameter or non-existent file!" >&2
  _show_help
  exit 1
fi

if [[ -t 0 ]]; then
  if [[ -z ${_PATH} ]]; then
    # Get contents from clipboard
    _TMP="$(xclip -selection clipboard -o)"
    if [[ $(<<<"${_TMP}" wc -l) == 1 && ${_TMP} =~ ^file:// ]]; then
      _PATH=${_TMP#file://}
    else
      _PIPE="${_TMP}"
    fi
    unset _TMP
    _FROM_CLIPBOARD=1
  fi
else
  # Get contents from stdin
  _PIPE="$(</dev/stdin)"
fi

if [[ -n ${_PATH} ]]; then
  read -r _ _MIME_TYPE <<<"$(file --mime-type ${_PATH})"
else
  read -r _ _MIME_TYPE <<<"$(<<<"${_PIPE}" file --mime-type -)"
fi

if [[ ${_MIME_TYPE} == "application/octet-stream" ]]; then
  echo "Unsupported type: ${_MIME_TYPE}" >&2
  exit 1
fi

_CACHE_DIR="${HOME}/.cache/pb.sh"
_KNOWN_SUFFIXES=
mkdir -p ${_CACHE_DIR}
_KNOWN_SUFFIXES_CACHE_FILE="${_CACHE_DIR}/_known_suffixes"
[[ -e "${_KNOWN_SUFFIXES_CACHE_FILE}" ]] && . "${_KNOWN_SUFFIXES_CACHE_FILE}"
if [[ ! $(declare -p _KNOWN_SUFFIXES) =~ declare\ -a ]]; then
  # https://gist.github.com/ppisarczyk/43962d06686722d26d176fad46879d41
  _EXT_BASE_URL="https://gist.githubusercontent.com/ppisarczyk/43962d06686722d26d176fad46879d41"
  _EXT_REV_HASH="211547723b4621a622fc56978d74aa416cbd1729"
  _EXT_NAME="Programming_Languages_Extensions.json"
  _CACHE_FILE="${_CACHE_DIR}/${_EXT_NAME}"
  if [[ ! $(file --mime-type ${_CACHE_FILE} | cut -d" " -f2) == "application/json" ]]; then
    set -- curl -Lfo ${_CACHE_FILE} "${_EXT_BASE_URL}/raw/${_EXT_REV_HASH}/${_EXT_NAME}"
    echo ">>> " "${@}"
    "${@}"
  fi
  _KNOWN_SUFFIXES=(
    ".bmp" ".eps" ".gif" ".ico" ".jpeg" ".jpg" ".pdf" ".png" ".tif" ".tiff" ".webp"
    $(jq -r '.[] | select(.extensions) .extensions[]' "${_CACHE_FILE}")
  )
  declare -p _KNOWN_SUFFIXES >"${_KNOWN_SUFFIXES_CACHE_FILE}"
fi

if [[ -n ${_PATH} ]]; then
  _TMP_NAME=$(basename "${_PATH}")
  _TMP_SUFFIX="${_TMP_NAME##*.}"
  if [[ "${_TMP_SUFFIX}" != "${_TMP_NAME}" ]]; then
    for _SUFF in "${_KNOWN_SUFFIXES[@]}"; do
      if [[ "${_SUFF}" == ".${_TMP_SUFFIX}" ]]; then
        _SUFFIX="/${_TMP_SUFFIX}"
        break
      fi
    done
  fi
  unset _SUFF _TMP_NAME _TMP_SUFFIX
fi
if [[ ${_MIME_TYPE} =~ ^image ]]; then
  if [[ -z ${_SUFFIX} ]]; then
    _SUFFIX=${_MIME_TYPE#image\/}
    _SUFFIX=".${_SUFFIX%+*}"
  else
    _SUFFIX=".${_SUFFIX#/}"
  fi
fi

if [[ -n ${_FROM_CLIPBOARD} ]]; then
  # notify the uploading contents are from clipboard
  # and wait a confirmation
  if [[ -n ${_PIPE} ]]; then
    if [[ ${#_PIPE} -gt 89 ]]; then
      _REMAINING_NOTICE="\\e[4m\\e[36m… and remaining $((${#_PIPE} - 89)) characters\\e[0m"
    fi
    _NOTIFY_CONTENTS="${_PIPE:0:89}${_REMAINING_NOTICE}"
  else
    _NOTIFY_CONTENTS="file://${_PATH}"
  fi
  echo -ne 'The uploading contents are from clipboard,

\e[36mContents:\e[0m\n'
  echo -e "${_NOTIFY_CONTENTS}"
  echo -ne "\n\e[1m\e[33mUpload? [y/N]\e[0m "
  while read -n 1 -re _param; do
    case ${_param} in
      [yY])
        break
        ;;
      *)
        echo "bye~" >&2
        exit 0
        ;;
    esac
  done
fi

: ${_PATH:=-}
set -- curl -sfL -F "c=@${_PATH}" "${PB_URL}"
if [[ -n ${_PIPE} ]]; then
  echo ">>> <pipe> |" "${@}"
  _R=$(echo "${_PIPE}" | "${@}")
else
  echo ">>>" "${@}"
  _R=$("${@}")
fi
echo $'\n'"${_R}" >>"${_CACHE_DIR}/_histories"

IFS=':'
while read -r _K _V; do
  eval "_r_${_K}='${_V# }'"
done <<<"${_R}"
_R_URL="${PB_URL%/}/${_r_short}${_SUFFIX}"

_bc() {
  eval "<<<\"scale=2; ${@}\" bc"
}
if [[ -n ${_r_size} ]]; then
  if [[ ${_r_size} -lt 600 ]]; then
    _r_size="${_r_size}B"
  elif [[ ${_r_size} -lt 614400 ]]; then
    _r_size="$(_bc ${_r_size} '/' 1024)KiB"
  else
    _r_size="$(_bc ${_r_size} '/' 1024 '/' 1024)MiB"
  fi
fi

set +e
_COPIED="\e[33m<not copied"
<<<"${_R_URL}" xclip -selection clipboard
if [[ ${?} == 0 ]]; then
  _COPIED="\e[32m<copied"
fi

echo -e "\
[${_r_status}${_r_size:+, size: }${_r_size}]\
${_r_uuid:+$'\n'UUID: }${_r_uuid}
\e[1m\e[36m\
URL: ${_R_URL} \e[0m${_COPIED}!>\
\e[0m"
