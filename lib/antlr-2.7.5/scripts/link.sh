#!/bin/sh
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
## This file is part of ANTLR. See LICENSE.txt for licence  ##
## details. Written by W. Haefelinger.                      ##
##                                                          ##
##       Copyright (C) Wolfgang Haefelinger, 2004           ##
##                                                          ##
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
test -z "$1" && exit 0
## This script shall wrap/hide how we are going to link C++
## object files within the ANTLR (www.antlr.org) project.
CXX="g++"
CXXFLAGS=""

LIBNAME="/home/rodrigob/java/antlr-2.7.5/lib/cpp/src/libantlr.a"
TARGET="$1" ; shift

##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
##             Prepate input arguments                    ##
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
case "linux-gnu" in
  cygwin)
    ARGV="`cygpath -m ${*}`"
    test -n "${TARGET}" && {
      TARGET=`cygpath -m ${TARGET}`
    }
    test -n "${LIBNAME}" && {
      LIBNAME="`cygpath -m ${LIBNAME}`"
    }
    ;;
  *)
    ARGV="${*}"
    ;;
esac

# RK: Disabled it strips -l<lib> arguments
#L="${ARGV}" ; ARGV=""
#for x in $L ; do
#  if test -f "${x}" ; then
#    ARGV="$ARGV ${x}"
#  fi
#done
#unset L

if test -z "${ARGV}" ; then
cat <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Uuups, something went wrong. Have not been able to collect
a list of object files. Perhaps nothing has been compiled
so far?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOF
exit 0
fi

if test -z "${LD}" ; then
  LD="g++"
  ld="gcc"
else
  ld="`basename $LD`"
  ld="`echo $ld|sed 's,\..*$,,'`"
fi

##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
##       Here we set flags for well know programs         ##
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
##
## Do not set variable LDFLAGS here, just use it's sister
## variable 'ldflags'. This  allows  the call to override
## this settings - see handling of LDFLAGS below.

ldflags=""
case "${ld}" in
  cl)
    ldflags="${ldflags} /o${TARGET}.exe"
    ;;
  bcc32)
    ldflags="${ldflags} -e${TARGET}.exe"
    ;;
  *)
    ldflags="${ldflags} -o ${TARGET}"
    ;;
esac

test -f "${LIBNAME}" && {
  case "${ld}" in
    *)
      ARGV="${ARGV} ${LIBNAME}"
      ;;
  esac
}

##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
## **NO CHANGE NECESSARY BELOW THIS LINE - EXPERTS ONLY** ##
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##

## If specific flags have been configured then they overrule
## our precomputed flags. Still a user can override by using
## environment variable $LDFLAGS - see below.
test -n "" && {
  set x   ; shift
  case $1 in
    +)
      shift
      LDFLAGS="${ldflags} $*"
      ;;
    -)
      shift
      ldflags="$* ${ldflags}"
      ;;
    =)
      shift
      ldflags="$*"
      ;;
    *)
      if test -z "$1" ; then
        ldflags="${ldflags}"
      else
        ldflags="$*"
      fi
      ;;
  esac
}

## Regardless what has been configured, a user should always
## be able to  override  without  the need to reconfigure or
## change this file. Therefore we check variable $LDFLAGS.
## In almost all cases the precomputed flags are just ok but
## some  additional  flags are needed. To support this in an
## easy way, we check for the very first value. If this val-
## ue is
## '+'  -> append content of LDFLAGS to precomputed flags
## '-'  -> prepend content    -*-
## '='  -> do not use precomputed flags
## If none of these characters are given, the behaviour will
## be the same as if "=" would have been given.

set x ${LDFLAGS}  ; shift
case $1 in
  +)
    shift
    LDFLAGS="${ldflags} $*"
    ;;
  -)
    shift
    LDFLAGS="$* ${ldflags}"
    ;;
  =)
    shift
    LDFLAGS="$*"
    ;;
  *)
    if test -z "$1" ; then
      LDFLAGS="${ldflags}"
    else
      LDFLAGS="$*"
    fi
    ;;
esac

## Any special treatment goes here ..
case "${ld}" in
  ld)
    ;;
  *)
    ;;
esac

##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##
##    No  c u s t o m i z a t i o n  below this line          ##
##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##
test -z "${verbose}" && {
  verbose=0
}

##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
##    This shall be the command to be excuted below       ##
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##

cmd="${LD} ${LDFLAGS} ${ARGV}"

##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
##        standard template to execute a command          ##
##xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx##
case "${verbose}" in
  0|no|nein|non)
    echo "*** creating ${TARGET} .."
    ;;
  *)
    echo $cmd
    ;;
esac

$cmd || {
  rc=$?
  cat <<EOF

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                      >> E R R O R <<
============================================================

$cmd

============================================================
Got an error while trying to execute  command  above.  Error
messages (if any) must have shown before. The exit code was:
exit($rc)
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
  exit $rc
}
exit 0
