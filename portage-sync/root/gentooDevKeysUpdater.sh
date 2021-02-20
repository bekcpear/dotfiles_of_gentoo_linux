#!/usr/bin/env bash
# author: @Bekcpear
#

set -e

LISTFILE="${HOME}/.gnupg/gentooDevKeysLists/list"
PROXYC="proxychains -q "
if [[ "${1}" != "updateList" ]]; then
  source "${LISTFILE}"
  colorM="\e[35m"
  colorU="\e[36m"
  colorX="\e[1m"
  colorE="\e[0m"
  KEYSTA=1
  KEYORD=1
  KEYNUM=${#KEYIDS[@]}
  TMSG=""
  UPMSGS=""
  if [[ ${1} -gt ${KEYORD} && ${1} -lt ${KEYNUM} ]]; then
    KEYSTA=${1}
    echo "Start from index ${KEYSTA}:"
  fi
  pkill dirmngr || true
  set +e
  EXECERR=0
  for keyid in ${KEYIDS[@]}; do
    if [ ${KEYORD} -ge ${KEYSTA} ];then
      echo -e "${colorU}[${KEYORD}/${KEYNUM}]Updating key: ${keyid} ...${colorE}"
      echo -e "${colorX}  > ${PROXYC}gpg --recv-keys ${keyid}${colorE}"
      eval "TMSG=\$(${PROXYC}gpg --recv-keys ${keyid} 2>/dev/stdout)"
      [ $? -ne 0 ] && EXECERR=${?}
      printf "${TMSG}\n"
      [ ${EXECERR} -ne 0 ] && break
      if [[ ! "${TMSG}" =~ .*"not changed".*  ]]; then
        UPMSGS="${UPMSGS}${TMSG}\n${colorM}------${colorE}\n"
      fi
    fi
    eval "KEYORD=\$(( ${KEYORD} + 1 ))"
  done
  set -e
  echo ""
  echo -e "${colorM}Updated keys:${colorE}"
  if [[ "${UPMSGS}" == "" ]]; then
    echo "NONE."
  else
    printf "${UPMSGS%\\e*m------\\e\[0m\\n}"
    echo -e "${colorM}End.${colorE}"
  fi
  exit ${EXECERR}
fi

# update gpg keys list file
URL="https://qa-reports.gentoo.org/output/committing-devs.gpg"
GPGFILE="/tmp/committing-devs"
SUFFIX=$(date +%Y%m%d_%H)
GPGFILE="${GPGFILE}_${SUFFIX}.gpg"

if [ ! -e "${GPGFILE}" ]; then
  eval "${PROXYC}wget '${URL}' -O '${GPGFILE}_tmp'" && \
  mv "${GPGFILE}_tmp" "${GPGFILE}"
fi

mkdir -p "${LISTFILE%/*}"
LISTFILE="${LISTFILE}_${SUFFIX}"
if [[ ! -e "${LISTFILE}" ]]; then
  echo "#${SUFFIX/_/ }+ o'clock" > "${LISTFILE}_tmp"
  echo "KEYIDS=(" >> "${LISTFILE}_tmp"
  gpg --show-keys "${GPGFILE}" 2>/dev/null | sed '/^pub/d;/^sub/d;/^uid.*/bs;/^\s\+Key\sfingerp.*/bs;d;:s;s/^uid\s\+\[\srevoked\]\s\(.*\)/#(REVOKED) \1/;s/^uid\s\+\[\sexpired\]\s\(.*\)/#(EXPIRED) \1/;s/^uid\s\+\(.*\)/#\1/;s/^uid\s\+.*\]\s\(.*\)/#\1/;s/^\s\+Key\sfin.*=\s\(.*\)/0x\1/;/^0x.*/s/\s//g' >> "${LISTFILE}_tmp"
  echo ")" >> "${LISTFILE}_tmp"
  LISTFILEL=${LISTFILE%%_*}
  if [ -e "${LISTFILEL}" ]; then
    colordiff "${LISTFILEL}" "${LISTFILE}_tmp" || :
    while read -n 1 -rep 'continue?[y/N] ' read_parm; do
      case ${read_parm} in
        [yY])
          mv "${LISTFILE}_tmp" "${LISTFILE}"
          break
          ;;
        *)
          if [[ "${read_parm}" == "" ]]; then
            echo
          fi
          echo "bye~" > /dev/stderr
          exit 1
          ;;
      esac
    done
    unlink ${LISTFILEL}
  else
    mv "${LISTFILE}_tmp" "${LISTFILE}"
  fi
  ln -s "${LISTFILE}" "${LISTFILEL}"
  LISTFILE="${LISTFILEL}"
fi
echo "LIST FILE: ${LISTFILE}"
