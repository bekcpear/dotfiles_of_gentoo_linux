#!/usr/bin/env bash
#
# Author: cwittlut <i@bitbili.net>
#
# identity UUID, please don't remove it:
# 252075b9-149e-49fd-925d-f0ccccde7825
#
# TODO port to wayland clipboard
#

set -e

PB_URL="https://fars.ee/"
INFO_CMD="emerge --info"

function _show_help(){
  echo "
  Usage:

     1. pb [-i] [-p] [<PATH>...]
          post files or contents from clipboard (X11, by xclip) if no file provided
     2. pb [-i] -c <COMMAND-AND-OPTIONAL-ARGS>
          execute the command and post stdout and stderr
          it will prepend the command and arguments to the contents
     3. <some output command> | pb [-i]
          post stdin from pipe
     4. pb [-i] -o
          try to open a file picker through DBus, and post selected files

    -p      prevent reading contents from clipboard
    -i      also append the stdout of command \`${INFO_CMD}\` to the contents
    -u      fetch the latest version of this script
    -h      show this help

    All histories are recorded in the '\${HOME}/.cache/pb.sh/_histories' file.

    Version: 20221220.1"
}

# parse args --start--
declare -a args
shopt -s extglob
while :; do
  case "${1}" in
    -h)
      _show_help
      exit 0
      ;;
    -u)
      MODE="UPGRADE"
      break
      ;;
    -p)
      PREVENT_CLIPBOARD=1
      shift
      ;;
    -o)
      MODE="PORTAL"
      shift
      ;;
    -i)
      APPEND_INFO=1
      shift
      ;;
    -c)
      MODE="COMMAND"
      shift
      if [[ ${1} == '-i' ]] && [[ -z ${APPEND_INFO} ]]; then
        APPEND_INFO=1
        shift
      else
        break
      fi
      ;;
    --)
      shift
      break
      ;;
    -+([pichuo]))
      _tmp_arg=${1:1}
      declare -a _tmp_args
      shift
      while [[ ${_tmp_arg:0:1} != "" ]]; do
        _tmp_args+=( "-${_tmp_arg:0:1}" )
        _tmp_arg=${_tmp_arg:1}
      done
      set -- "${_tmp_args[@]}" "${@}"
      unset _tmp_arg _tmp_args
      ;;
    -*)
      echo "unknown argument: '${1}'" >&2
      _show_help
      exit 1
      ;;
    "")
      break
      ;;
    *)
      args+=( "${1}" )
      shift
      ;;
  esac
done
shopt -u extglob
set -- "${args[@]}" "${@}"
# parse args --end--

if [[ ! -t 0 ]]; then
  if [[ -n ${MODE} ]]; then
    echo "PIPE mode, ignore other mode options" >&2
  fi
  MODE="PIPE"
fi

cliptool_ready() {
  # TODO: wayland detected and tool
  if command -v xclip &>/dev/null; then
    return 0
  else
    return 1
  fi
}

if [[ -z ${MODE} ]]; then
  if [[ -n ${1} ]]; then
    if [[ -f ${1} ]]; then
      MODE="FILE"
    elif command -v ${1} &>/dev/null; then
      echo "warning: file '${1}' does not exist, but it's a command, fallback to COMMAND mode .." >&2
      MODE="COMMAND"
    else
      echo "error: file '${1}' does not exist, exit .." >&2
      exit 1
    fi
  elif [[ -z ${PREVENT_CLIPBOARD} ]] && cliptool_ready; then
    MODE="CLIP"
  elif [[ -n ${APPEND_INFO} ]]; then
    MODE="INFO"
  else
    echo "error: no mode detected, exit ..." >&2
    exit 1
  fi
fi

_is_binary() {
  if [[ ! -e ${1} ]]; then
    echo "error: file '${1}' does not exist, exit ..." >&2
    exit 1
  fi
  if [[ $(file -b --mime-encoding ${1}) == binary ]]; then
    return 0
  else
    return 1
  fi
}

PS1="\$ "
if [[ ${EUID} == 0 ]]; then
  PS1="# "
fi

main() {
  case ${MODE} in
    UPGRADE)
      TMPEXE=$(mktemp -u)
      trap 'rm -f ${TMPEXE}' EXIT
      EXEURL="https://d0a.io/pb"
      if command -v curl &>/dev/null; then
        set -- curl -Lfo ${TMPEXE} "${EXEURL}"
      else
        set -- wget -O ${TMPEXE} "${EXEURL}"
      fi
      "${@}"
      chmod +x ${TMPEXE}
      eval "${TMPEXE}"
      exit
      ;;
    PIPE)
      # Get contents from stdin
      _PIPE="$(</dev/stdin)"
      ;;
    FILE)
      _PATH=${1}
      shift
      if [[ -f "${1}" ]]; then
        _binary_exit() {
          echo "error: '${1}' is a binary file, cannot concat to other files, exit ..." >&2
          exit 1
        }
        if _is_binary ${_PATH}; then
          _binary_exit ${_PATH}
        else
          _file_block_start() {
            echo "================================================================="
            echo "=== FILE: ${1}"
            echo "================================================================="
          }
          _PIPE="$(_file_block_start ${_PATH})"$'\n'"$(<${_PATH})"$'\n'
          unset _PATH
          while [[ -f "${1}" ]]; do
            if _is_binary ${1}; then
              _binary_exit ${1}
            fi
            _PIPE="${_PIPE}"$'\n'"$(_file_block_start ${1})"$'\n'"$(<${1})"$'\n'
            shift
          done
        fi
      fi
      ;;
    CLIP)
      # Get contents from clipboard
      _TMP="$(xclip -selection clipboard -o)"
      if [[ $(<<<"${_TMP}" wc -l) == 1 && ${_TMP} =~ ^file:// ]]; then
        _PATH=${_TMP#file://}
      else
        _PIPE="${_TMP}"
      fi
      unset _TMP
      _FROM_CLIPBOARD=1
      ;;
    COMMAND)
      if [[ ${#} -lt 1 ]]; then
        echo "error: no command provided, exit ..." >&2
        exit 1
      fi
      _prompt="${PS1}${*//\"/\\\"}"$'\n'
      echo -e "\x1b[32m\x1b[1m>>>\x1b[0m" "${@}"
      _PIPE="${_prompt}"$("${@}" 2>&1) || ret=$?
      if [[ ${ret} == "127" ]]; then
        echo "error: command '${@}' not found, exit ..." >&2
        exit 1
      fi
      unset _prompt
      ;;
    INFO)
      _PIPE=""
      ;;
  esac

  if [[ -n ${_PATH} ]]; then
    _MIME_TYPE=$(file -b --mime-type ${_PATH})
  else
    _MIME_TYPE=$(<<<"${_PIPE:-0}" file -b --mime-type -)
  fi

  if [[ ${_MIME_TYPE} == "application/octet-stream" ]]; then
    echo "error: unsupported type: ${_MIME_TYPE}" >&2
    exit 1
  fi

  _CACHE_DIR="${HOME}${HOME:+/}.cache/pb.sh"
  _KNOWN_SUFFIXES=
  mkdir -p ${_CACHE_DIR}
  _KNOWN_SUFFIXES_CACHE_FILE="${_CACHE_DIR}/_known_suffixes"
  [[ -e "${_KNOWN_SUFFIXES_CACHE_FILE}" ]] && . "${_KNOWN_SUFFIXES_CACHE_FILE}"
  if [[ ! $(declare -p _KNOWN_SUFFIXES) =~ declare\ -a ]]; then
    # parsed from https://gist.github.com/ppisarczyk/43962d06686722d26d176fad46879d41
    # _KNOWN_SUFFIXES=(
    #   ".bmp" ".eps" ".gif" ".ico" ".jpeg" ".jpg" ".pdf" ".png" ".tif" ".tiff" ".webp"
    #   $(jq -r '.[] | select(.extensions) .extensions[]' "Programming_Languages_Extensions.json")
    # )
    #_EXT_BASE_URL="https://gist.githubusercontent.com/bekcpear/5e6248e94b07600944cc14d57b7e2b55"
    #_EXT_REV_HASH="fb25c0f8921ec2396f7f537416c44b68e3d58dc0"
    #_EXT_NAME="_known_suffixes"
    _EXT_BASE_URL="https://gitlab.com/-/snippets/2473947"
    _EXT_REV_HASH="main"
    _EXT_NAME="_known_suffixes.sh"
    echo "Getting _known_suffixes file from gitlab ..."
    if command -v curl &>/dev/null; then
      set -- curl -Lfo ${_KNOWN_SUFFIXES_CACHE_FILE} "${_EXT_BASE_URL}/raw/${_EXT_REV_HASH}/${_EXT_NAME}"
    else
      set -- wget -O ${_KNOWN_SUFFIXES_CACHE_FILE} "${_EXT_BASE_URL}/raw/${_EXT_REV_HASH}/${_EXT_NAME}"
    fi
    echo -e "\x1b[32m\x1b[1m>>>\x1b[0m" "${@}"
    "${@}"
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
      _NOTIFY_CONTENTS="file: ${_PATH}"
    fi
    echo -ne '
  The uploading contents are from clipboard,

  \e[36mContents:\e[0m\n'
    echo -e "${_NOTIFY_CONTENTS}"
    while read -p $'\n\e[1m\e[33mUpload? [y/N]\e[0m ' -n 1 -re _param; do
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

  # append info of INFO_CMD
  if [[ -n ${APPEND_INFO} ]]; then
    if [[ -n ${_PATH} ]] && _is_binary ${_PATH}; then
      echo "warning: cannot append informations to binary file, ignore '-i' option" >&2
    elif command -v ${INFO_CMD% *} &>/dev/null; then
      echo -e "\x1b[32m\x1b[1m>>>\x1b[0m" "${INFO_CMD}"
      INFO=$(eval ${INFO_CMD} 2>&1)
      if [[ -n ${_PATH} ]]; then
        _PIPE="$(<${_PATH})"
        unset _PATH
      fi
      _PIPE="${_PIPE}"${_PIPE:+$'\n\n'}"${PS1}${INFO_CMD}"$'\n'"${INFO}"
    else
      echo "warning: command '${INFO_CMD% *}' does not exist, ignore '-i' option" >&2
    fi
  fi

  : ${_PATH:=-}
  if command -v curl &>/dev/null; then
    set -- curl -fL -F "c=@${_PATH}" "${PB_URL}"
  else
    if [[ -z ${_PIPE} ]]; then
      if _is_binary ${_PATH}; then
        echo "I don't known how to upload binary file by 'wget', please use 'curl' instead, exit ..." >&2
        exit 1
      fi
      _PIPE=$(<${_PATH})
    fi
    _WGET_TMP=$(mktemp)
    _WGET_HEADER="Content-Type: multipart/form-data; boundary=------------------------7742583d48a00ce6"
    echo "--------------------------7742583d48a00ce6
  Content-Disposition: form-data; name=\"c\"; filename=\"-\"
  Content-Type: application/octet-stream

  ${_PIPE}
  --------------------------7742583d48a00ce6--
  " >${_WGET_TMP}
    unset _PIPE
    set -- wget -O - --header="${_WGET_HEADER}" --post-file="${_WGET_TMP}" "${PB_URL}"
    trap 'rm -f ${_WGET_TMP}' EXIT
  fi
  if [[ -n ${_PIPE} ]]; then
    echo -e "\x1b[32m\x1b[1m>>>\x1b[0m <pipe> |" "${@}"
    _R=$(echo "${_PIPE}" | "${@}")
  else
    echo -e "\x1b[32m\x1b[1m>>>\x1b[0m" "${@}"
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
    elif command -v bc &>/dev/null; then
      if [[ ${_r_size} -lt 614400 ]]; then
        _r_size="$(_bc ${_r_size} '/' 1024)KiB"
      else
        _r_size="$(_bc ${_r_size} '/' 1024 '/' 1024)MiB"
      fi
    fi
  fi

  set +e
  _COPIED="\e[33m<not copied"
  if cliptool_ready; then
    echo -n "${_R_URL}" | xclip -selection clipboard
    if [[ ${?} == 0 ]]; then
      _COPIED="\e[32m<copied"
    fi
  fi

  echo -e "
[${_r_status}${_r_size:+, size: }${_r_size}]\
${_r_uuid:+$'\n'UUID: }${_r_uuid}
\e[1m\e[36mURL: ${_R_URL} \e[0m${_COPIED}!>\\e[0m"
}

if [[ ${MODE} != "PORTAL" ]]; then
  main "${@}"
else
  ret=0
  if command -v dbus-monitor &>/dev/null \
    && command -v dbus-send &>/dev/null; then
    dbus-send --type=method_call \
      --dest=org.freedesktop.DBus \
      /org/freedesktop/DBus \
      org.freedesktop.DBus.GetNameOwner \
      string:org.freedesktop.portal.Desktop &>/dev/null || ret=$?
    if [[ ${ret} != "0" ]]; then
      echo "error: DBus: org.freedesktop.portal.Desktop is not ready, exit ..."
      exit 1
    fi
  else
    echo "error: dbus-send and dbus-monitor are not ready, exit ..."
    exit 1
  fi

  _handle_portal() {
    local -a log
    local -i i
    local serial

    while read -r input; do
      read key value <<<"${input}"
      if [[ ${key} == "res:" ]]; then
        for (( i = 0; i < ${#log[@]}; i++ )); do
          if [[ ${log[$i]} == "object path \"${value}\"" ]]; then
            serial=${log[$(($i - 1))]}
            serial=${serial#* serial=}
            serial=${serial%% *}
            break 2
          fi
        done
      else
        log+=( "${input}" )
      fi
    done

    if [[ ! ${serial} =~ ^[0-9]+$ ]]; then
      echo "error: wrong serial number for dbus: ${serial}, exit ..." >&2
      exit 1
    fi

    _get_files() {
      local -a _log _files
      while read -r line; do
        if [[ ${line} =~ [[:space:]]reply_serial=${serial} ]]; then
          _right_pos=1
        fi
        if [[ -n ${_right_pos} ]];then
          if [[ ${line} =~ ^method[[:space:]]+call ]]; then
            break
          fi
          _log+=( "${line}" )
        fi
      done

      local _file
      for l in "${_log[@]}"; do
        if [[ ${l} =~ ^[[:space:]]*string[[:space:]]+\"file:/// ]]; then
          read _ _file <<<"${l}"
          _file=${_file#\"file://}
          _files+=( "${_file%\"}" )
        fi
      done

      MODE="FILE"
      main "${_files[@]}"
    }

    export APPEND_INFO INFO_CMD PB_URL PS1
    exec {_GET_FILES_FD}> >(_get_files)
    eval "dbus-monitor >&${_GET_FILES_FD}"
  }

  export APPEND_INFO INFO_CMD PB_URL PS1
  exec {MONITOR}> >(_handle_portal)
  _files_process_pid=$!
  eval "dbus-monitor 'interface=org.freedesktop.impl.portal.FileChooser,member=OpenFile' >&${MONITOR} &"
  _monitor_1_pid=$!

  res=$(dbus-send --print-reply=literal --type=method_call \
    --dest="org.freedesktop.portal.Desktop" \
    /org/freedesktop/portal/desktop \
    org.freedesktop.portal.FileChooser.OpenFile \
    string: string:B dict:string:variant:multiple,boolean:true)

  kill -s TERM ${_monitor_1_pid}
  eval "echo \"res: ${res}\" >&${MONITOR}"

  wait
fi
