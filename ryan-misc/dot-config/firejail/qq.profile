# Persistent global definitions
include globals.local

include disable-common.inc
include disable-devel.inc
include disable-exec.inc
include disable-interpreters.inc
include disable-passwdmgr.inc
include disable-programs.inc

#whitelist ${DOWNLOADS}
whitelist ~/.config/tencent-qq
whitelist ~/.fonts
whitelist ~/.cache/fontconfig

apparmor
caps.drop all
netfilter
nodvd
nogroups
nonewprivs
noroot
notv
protocol unix,inet,inet6,netlink
seccomp

disable-mnt
#dbus-user none
#dbus-system none
