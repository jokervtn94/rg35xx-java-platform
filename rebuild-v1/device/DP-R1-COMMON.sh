#!/bin/sh
JAMVM=/mnt/mmc/CFW/java/bin/jamvm
GLIBJ=/mnt/mmc/CFW/java/share/classpath/glibj.zip
EXPECTED_JAMVM=eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
EXPECTED_GLIBJ=d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea
APP="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
PLATFORM="$APP/rg35xx-dp-r1-platform.jar"
check_protected() {
  [ -f "$JAMVM" ] && [ -f "$GLIBJ" ] || return 1
  [ "$(sha256sum "$JAMVM"|awk '{print $1}')" = "$EXPECTED_JAMVM" ] || return 2
  [ "$(sha256sum "$GLIBJ"|awk '{print $1}')" = "$EXPECTED_GLIBJ" ] || return 3
  return 0
}
