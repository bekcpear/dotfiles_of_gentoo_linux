#!/bin/bash
#
set -e

_SNAPSHOTS_DIR="/.sss"
_SUBVOLS=(
  "/"
  "/home"
) # absolute paths


#######################################################
#######################################################
#######################################################

if [[ -n ${1} ]]; then
  case ${1} in
    -f)
      _FORCE_UPDATE=1
      ;;
    -c)
      _FORCE_CLEAN=1
      ;;
    *)
      echo "Only '-f' parameter defined to force update," >&2
      echo "  or '-c' parameter defined to clean snapshots older than today." >&2
      exit 1
      ;;
  esac
fi

_TIMESTAMP=$(date "+%s")
_ZONE=$(date "+%z")
_DATE=$(date -d "@${_TIMESTAMP}" "+%Y-%m-%d@%H:%M:%S%z")

_echo() {
  local _d=$(date "+%Y-%m-%d %H:%M:%S")
  local _color='\e[36m'
  local _marker=">>>"
  if [[ ${3} == "delete" ]]; then
    _color='\e[31m'
    _marker="<<<"
  fi
  if [[ ${1} == "btrfs" ]]; then
    eval "echo -e '\\n[${_d}] \\e[1m${_color}${_marker} ${@//\'/\'\\\'\'}\\e[0m'"
  else
    eval "echo '[${_d}] ${@//\'/\'\\\'\'}'"
  fi
}

declare -A _REMAINING_PATHS
# $1: path
_delete_snapshot() {
  if [[ ${1} == 1 ]]; then
    local _force=1
    shift
  fi

  local _key=${1%.T*}
  local _counts=${_REMAINING_PATHS["${_key}"]}
  if [[ ${_counts} -le 1 && -z ${_force} ]]; then
    return
  fi
  set -- btrfs subvolume delete "${1}"
  _echo "${@}"
  "${@}"
  _REMAINING_PATHS["${_key}"]=$(( ${_counts} - 1 ))
}

for _subvol in ${_SUBVOLS[@]}; do
  _snapshot="${_subvol/#\//root:}"
  _snapshot="${_snapshot//\//:}"
  _snapshot="${_snapshot%:}.SNAPSHOT.R"

  # remove outdated snapshots (all older than 28 days, 28:2419200)
  #                           (keep the three averagely between 28 days and 7 days
  #                                                    21:1814400, 14:1209600, 7:604800)
  #                           (keep one per day within 7 days
  #                                                    6:518400, 5:432000, 4:345600,
  #                                                    3:259200, 2:172800, 1:86400)
  #                           (at least keep one)
  OLDIFS=${IFS}
  IFS=$'\n'
  _PATHS=( $(ls -1d ${_SNAPSHOTS_DIR}/${_snapshot}.* || true) )
  IFS=${OLDIFS}
  _REMAINING_PATHS["${_SNAPSHOTS_DIR}/${_snapshot}"]=${#_PATHS[@]}
  declare -a _PATHS_TS
  declare -A _PATHS_TS_R
  for (( i = 0; i < ${#_PATHS[@]}; ++i  )); do
    _path=${_PATHS[i]}
    _d=${_path##*.T}
    _d=$(date -d "${_d/@/ }" "+%s")
    _PATHS_TS[${i}]=${_d}
    _PATHS_TS_R["${_d}"]=${i}
  done
  declare _S0 _S1 _S2 _S3 _S4 _S5 _S6 _S7 _S8 _S9
  for j in $(echo "${_PATHS_TS[@]/%/$'\n'}" | sort -n); do
    i=${_PATHS_TS_R[${j}]}
    _path=${_PATHS[${i}]}
    _t=${_PATHS_TS[${i}]}
    _tn=$(date -d "${_DATE%@*} 23:59:59${_ZONE}" "+%s")
    _do() {
      if [[ ${1} == "_S0" && ${_FORCE_UPDATE} == 1 ]]; then
        _delete_snapshot 1 "${_path}"
      elif [[ ${1} != "_S0" && ${_FORCE_CLEAN} == 1 ]]; then
        _delete_snapshot 1 "${_path}"
      else
        if [[ ${!1} != 1 ]]; then
          eval "${1}=1"
        else
          _delete_snapshot "${_path}"
        fi
      fi
    }
    if (( ${_tn} - ${_t} > 2419200 )); then
      _delete_snapshot "${_path}"
    elif (( ${_tn} - ${_t} > 1814400 )); then
      _do _S9
    elif (( ${_tn} - ${_t} > 1209600 )); then
      _do _S8
    elif (( ${_tn} - ${_t} > 604800 )); then
      _do _S7
    elif (( ${_tn} - ${_t} > 518400 )); then
      _do _S6
    elif (( ${_tn} - ${_t} > 432000 )); then
      _do _S5
    elif (( ${_tn} - ${_t} > 345600 )); then
      _do _S4
    elif (( ${_tn} - ${_t} > 259200 )); then
      _do _S3
    elif (( ${_tn} - ${_t} > 172800 )); then
      _do _S2
    elif (( ${_tn} - ${_t} > 86400 )); then
      _do _S1
    else
      _do _S0
    fi
  done

  # make a new readonly snapshot when has not been created today
  if [[ ${_S0} != 1 ]]; then
    set -- btrfs subvolume snapshot -r "${_subvol}" "${_SNAPSHOTS_DIR}/${_snapshot}.T${_DATE}"
    _echo "${@}"
    "${@}"
  else
    _echo Skip "${_subvol}"
  fi
  unset _PATHS _PATHS_TS _PATHS_TS_R _S0 _S1 _S2 _S3 _S4 _S5 _S6 _S7 _S8 _S9
done
