# Firejail profile for electron
# Description: Build cross platform desktop apps with web technologies
# This file is overwritten after every install/update
# Persistent local customizations
include electron.local
# Persistent global definitions
include globals.local

include disable-common.inc
#include disable-passwdmgr.inc
include disable-programs.inc

#whitelist ${DOWNLOADS}
whitelist ~/.config/qqmusic
whitelist ~/.fonts
whitelist ~/.cache/fontconfig
#whitelist /usr/share/fonts
#whitelist /usr/share/fontconfig

apparmor
caps.drop all
netfilter
nodvd
nogroups
nonewprivs
noroot
notv
protocol unix,inet,inet6,netlink
#seccomp

#dbus-user none
#dbus-system none
