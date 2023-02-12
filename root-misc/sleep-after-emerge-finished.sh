#!/bin/bash
#

set -e

#OPTS:   suspend    (the default)
#      hibernate
#       poweroff
#         reboot
#declare -i TIMEOUT=10800 #seconds, 3 hours
declare -i TIMEOUT=36000

# @FUNCTION: _log
# @USAGE: [-d|-i|-w|-e] <message>
# @INTERNAL
# @DESCRIPTION:
# Echo messages with a unified format.
#  '-d' means it's an DEBUG level msg;
#  '-i' means it's an  INFO level msg;
#  '-w' means it's an  WARN level msg;
#  '-e' means it's an ERROR level msg;
# Msg will be printed to the standard output normally
# when this function is called without any option.
function _log() {
  local lv="normal"
  local color='\e[36m'
  local reset='\e[0m'
  local outfd='&1'
  if [[ ${1} =~ ^\- ]] && [[ -n ${2} ]]; then
    case ${1} in
      -d)
        lv="DEBUG"
        color='\e[0m'
        outfd='&1'
        ;;
      -i)
        lv=" INFO"
        color='\e[0m'
        outfd='&1'
        ;;
      -w)
        lv=" WARN"
        color='\e[33m'
        outfd='&2'
        ;;
      -e)
        lv="ERROR"
        color='\e[31m'
        outfd='&2'
        ;;
      *)
        echo "UNRECOGNIZED OPTION OF _log FUNCTION!" >&2
        return 1
        ;;
    esac
    shift
  fi
  local prefix=""
  local msg="${1}"
  if [[ ${lv} != normal ]]; then
    prefix="[$(date '+%Y-%m-%d %H:%M:%S') ${lv}] "
  fi
  eval ">${outfd} echo -e '${color}${prefix}${msg//\'/\'\\\'\'}${reset}'"
}

# define the power control command and options
declare -a ACTIONS=( 'suspend' 'hibernate' 'poweroff' 'reboot' )
DEFAULT_ACTION="suspend"
if loginctl --version >/dev/null; then
  CMD="loginctl"
#elif systemctl --version >/dev/null; then
#  CMD="systemctl"
else
  _log -e "Unknown power control tool!"
fi
action="${1}"
: ${action:=${DEFAULT_ACTION}}
actions_pattern="${ACTIONS[@]}"
actions_pattern="^(${actions_pattern// /|})$"
if [[ ! ${action} =~ ${actions_pattern} ]]; then
  _log -e "Unknown action '${action}'."
  exit 1
fi

# check emerge log dir
_log "Checking emerge log file dir..."
LOG_DIR=$(emerge --info -v | egrep '^EMERGE_LOG_DIR' | cut -d'"' -f2)
: ${LOG_DIR:=/var/log}
LOG_DIR="${LOG_DIR%\"}"
_log "The log dir is ${LOG_DIR}"
LOG_FILE="${LOG_DIR%/}/emerge.log"

# @FUNCTION: _countdown
# @USAGE: <seconds> [--async] [<message>] [<defined-function> [<parameters>...]]
# @INTERNAL
# @DESCRIPTION:
# This is a countdown function. If a message is provided,
# the counting down will apper at the end of the message.
# If a '%cd' is contained in the message, it will be replaced
# by the counting down.
# It will run <defined-function> everytime it counts down, if
# the <defined-function> return a non-zero code, the whole countdown
# function will exit with a non-zero code. ATTENTION: long time execution
# in <defined-function> will block the countdown function.
# TODO: async countdown to run some commands.
function _countdown() {
  if [[ ${1} =~ ^[[:digit:]]+A?$ ]]; then
    if [[ ${2} == "--async" ]]; then
      local ctime=${1}A
      shift 2
      set -- ${ctime} "$@"
      _countdown _NvATruV2countdown "$@" &
    else
      _countdown _NvATruV2countdown "$@"
    fi
  elif [[ ${1} == _NvATruV2countdown ]]; then
    local -i begin=$(date +%s)
    local    msg arg ctime=${2}
    shift 2
    local -i shiftnum=0
    for arg; do
      if ! declare -F ${arg} >/dev/null; then
        msg+="${arg}"
        shiftnum+=1
      else
        break
      fi
    done
    shift ${shiftnum}

    local    ctimecount=${ctime%A}
    local -i ctimecount=${#ctimecount}
    local    lastifs=${IFS}
    local    pos_row pos_col
    IFS=';'
    read -sdR -p $'\E[6n' pos_row pos_col
    local -i pos_row=${pos_row#*[}
    local    linecount="${msg//[!$'\n']/}"
    local -i linecount=${#linecount}
    IFS=${lastifs}

    #handle msg
    #USAGE: <remaining seconds>
    local __first_handle_msg=1
    function __handle_msg() {
      local s=${1} lmsg
      if [[ ${#s} < ${ctimecount} ]]; then
        local diff=
        local -i i
        for (( i = ${ctimecount} - ${#s}; i > 0; --i )); do
          diff+=' '
        done
        s="${diff}${s}"
      fi
      if [[ ${msg} =~ %cd ]]; then
        lmsg="${msg/\%cd/${s}}"
      else
        lmsg="${msg:-Remaining: }${s}"
      fi
      echo -ne "\e[${pos_row};${pos_col}H" #\e[J
      echo -n "${lmsg}"
      if [[ __first_handle_msg -eq 1 ]]; then
        __first_handle_msg=0
        local    lastifs=${IFS}
        local    pos_row_re
        IFS=';'
        read -sdR -p $'\E[6n' pos_row_re _
        local -i pos_row_re=${pos_row_re#*[}
        if [[ ${pos_row_re} -lt ${pos_row}+${linecount} ]]; then
          pos_row=${pos_row_re}-${linecount}
        fi
      fi
    }

    if [[ ${ctime} =~ A$ ]]; then
      ctime=${ctime%A}
      __handle_msg ${ctime}
      echo
      sleep ${ctime}
      #TODO: run some commands
    else
      local -i i current=$(date +%s)
      i=${ctime}-${current}+${begin}
      for (( ; i > 0; )); do
        __handle_msg ${i}
        "${@}"
        if [[ $? -eq 0 ]]; then
          sleep 1
        else
          return 1
        fi
        current=$(date +%s)
        i=${ctime}-${current}+${begin}
      done
      __handle_msg ${i}
      echo
    fi
  else
    echo "_countdown function error with args $@" >&2
    return 1
  fi
}


#---

_last_emerge_state=unset
function _check_finished_or_not() {
  if [[ -r ${LOG_FILE} ]]; then
    lastlog="$(tail -1 ${LOG_FILE})"
    if [[ "${lastlog}" =~ \*\*\*[[:space:]]terminating\.$ ]]; then
      if [[ ${_last_emerge_state} == unset ]]; then
        _log -w "emerge already terminated."
        return 1
      else
        _do_action ${action}
      fi
    elif [[ ${_last_emerge_state} == unset ]]; then
      _last_emerge_state=running
    fi
  else
    _log -e "Cannot access log file: ${LOG_FILE}"
    exit 1
  fi
}

function _do_action() {
  echo
  echo -n "This computer will ${1} after 30 seconds.. "
  eval "su -c 'notify-send -u critical \"sleep-after-emerge-finished.sh\" \"This computer will ${1} after 30 seconds ...\"' - ryan"
  declare -i i
  for (( i = 11; i >= 0; i-- )); do
    if [[ ${i} -lt 10 ]]; then
      ii=" "${i}
    else
      ii=${i}
    fi
    echo -en "\e[13D\e[K${ii} seconds.. "
    if [[ ${i} != 0 ]]; then sleep 1; fi
  done
  echo $'\n'"sleeping now.. "
  echo

  eval "${CMD} ${1}"
  exit
}

_countdown ${TIMEOUT} "\

        This computer will do action [${action}]
            when it completes the emerge
              or after %cd seconds!

" _check_finished_or_not && \
_do_action ${action}
