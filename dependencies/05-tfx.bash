#!/bin/false
# This file should be sourced, not executed.

# Usage examples:
# Simple use in "echo":
# echo "${tfx[fgRed]}hello world${tfx[off]}"
# Use in both pattern and string argument in "printf" to combine effects:
# printf "${tfx[fgRed]}%s${tfx[off]}\n" "hello" "${tfx[underline]}amazing" "world"
#
# "tfx" is short for "text effects".
# It is used to store terminal control codes that give the terminal
# ANSI SGR (Select Graphic Rendition) parameters.
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
#
# There are commented uses of "tput" here. I'm not sure if I want to switch to that from "printf".
# It doesn't seem to have all the ANSI SGR codes, and I don't know how it works on a system that can't display these anyway.
# printf runs faster because it is a builtin, where tput is a program so it forks.
#
# "printf" is used so the variable contains the actual control character,
# not the string with the escape character. This makes it usable
# directly in "echo" without the "-e" flag.
declare -A tfx

# Dark mode is the default.
# Mode can be chosen by setting "tfxTheme" to "dark" or "light" before this script runs,
# or by calling "tfxLight" and "tfxDark" after this script runs.
#
# The lines below can be uncommented if a warning about the mode is desried.
#if [[ ! -v tfxTheme || ! "$tfxTheme" =~ ^dark|light$ ]]; then
#  printf "%s\n" "\"tfxTheme\" was not a valid value. Dark theme will be used."
#fi

# Foreground
#tfx[fg0]="$(tput setaf 0 2>/dev/null)"
#tfx[fg1]="$(tput setaf 1 2>/dev/null)"
#tfx[fg2]="$(tput setaf 2 2>/dev/null)"
#tfx[fg3]="$(tput setaf 3 2>/dev/null)"
#tfx[fg4]="$(tput setaf 4 2>/dev/null)"
#tfx[fg5]="$(tput setaf 5 2>/dev/null)"
#tfx[fg6]="$(tput setaf 6 2>/dev/null)"
#tfx[fg7]="$(tput setaf 7 2>/dev/null)"
tfx[fg0]="$(printf "\e[30m")"
tfx[fg1]="$(printf "\e[31m")"
tfx[fg2]="$(printf "\e[32m")"
tfx[fg3]="$(printf "\e[33m")"
tfx[fg4]="$(printf "\e[34m")"
tfx[fg5]="$(printf "\e[35m")"
tfx[fg6]="$(printf "\e[36m")"
tfx[fg7]="$(printf "\e[37m")"
# Foreground Proper Name
#tfx[fgBlack]="${tfx[fg0]}"
tfx[fgRed]="${tfx[fg1]}"
tfx[fgGreen]="${tfx[fg2]}"
tfx[fgYellow]="${tfx[fg3]}"
tfx[fgBlue]="${tfx[fg4]}"
tfx[fgMagenta]="${tfx[fg5]}"
tfx[fgCyan]="${tfx[fg6]}"
#tfx[fgWhite]="${tfx[fg7]}"
# Foreground Bright
#tfx[fg8]="$(tput setaf 8 2>/dev/null)"
#tfx[fg9]="$(tput setaf 9 2>/dev/null)"
#tfx[fg10]="$(tput setaf 10 2>/dev/null)"
#tfx[fg11]="$(tput setaf 11 2>/dev/null)"
#tfx[fg12]="$(tput setaf 12 2>/dev/null)"
#tfx[fg13]="$(tput setaf 13 2>/dev/null)"
#tfx[fg14]="$(tput setaf 14 2>/dev/null)"
#tfx[fg15]="$(tput setaf 15 2>/dev/null)"
tfx[fg8]="$(printf "\e[90m")"
tfx[fg9]="$(printf "\e[91m")"
tfx[fg10]="$(printf "\e[92m")"
tfx[fg11]="$(printf "\e[93m")"
tfx[fg12]="$(printf "\e[94m")"
tfx[fg13]="$(printf "\e[95m")"
tfx[fg14]="$(printf "\e[96m")"
tfx[fg15]="$(printf "\e[97m")"
# Foreground Bright Numbers Shifted With Suffix
tfx[fg0b]="${tfx[fg8]}"
tfx[fg1b]="${tfx[fg9]}"
tfx[fg2b]="${tfx[fg10]}"
tfx[fg3b]="${tfx[fg11]}"
tfx[fg4b]="${tfx[fg12]}"
tfx[fg5b]="${tfx[fg13]}"
tfx[fg6b]="${tfx[fg14]}"
tfx[fg7b]="${tfx[fg15]}"
# Foreground Bright Proper Name
#tfx[fgBlackBright]="${tfx[fg8]}"
tfx[fgRedBright]="${tfx[fg9]}"
tfx[fgGreenBright]="${tfx[fg10]}"
tfx[fgYellowBright]="${tfx[fg11]}"
tfx[fgBlueBright]="${tfx[fg12]}"
tfx[fgMagentaBright]="${tfx[fg13]}"
tfx[fgCyanBright]="${tfx[fg14]}"
#tfx[fgWhiteBright]="${tfx[fg15]}"
# Foreground Strong/Weak Scale
function tfxLightFg {
    # Foreground Strong/Weak Scale
    tfx[fgStrong]="${tfx[fg7]}"
    tfx[fgStrongBright]="${tfx[fg15]}"
    #
    tfx[fgStrongMid]="$(printf "\e[38;5;235m")"
    tfx[fgMidStrong]="$(printf "\e[38;5;239m")"
    tfx[fgMid]="$(printf "\e[38;5;244m")"
    tfx[fgMidWeak]="$(printf "\e[38;5;247m")"
    tfx[fgWeakMid]="$(printf "\e[38;5;251m")"
    #
    tfx[fgWeak]="${tfx[fg0]}"
    tfx[fgWeakBright]="${tfx[fg8]}"
}
function tfxDarkFg {
    tfx[fgStrong]="${tfx[fg0]}"
    tfx[fgStrongBright]="${tfx[fg8]}"
    #
    tfx[fgStrongMid]="$(printf "\e[38;5;251m")"
    tfx[fgMidStrong]="$(printf "\e[38;5;247m")"
    tfx[fgMid]="$(printf "\e[38;5;244m")"
    tfx[fgMidWeak]="$(printf "\e[38;5;239m")"
    tfx[fgWeakMid]="$(printf "\e[38;5;235m")"
    #
    tfx[fgWeak]="${tfx[fg7]}"
    tfx[fgWeakBright]="${tfx[fg15]}"
}
case "$tfxTheme" in
  light ) tfxLightFg ;;
  dark | * ) tfxDarkFg ;;
esac
# Foreground Reset to Default
tfx[fgD]="$(printf '\e[39m')"
tfx[fgDefault]="${tfx[fgD]}"
tfx[fgOff]="${tfx[fgD]}"

# Background
#tfx[bg0]="$(tput setab 0 2>/dev/null)"
#tfx[bg1]="$(tput setab 1 2>/dev/null)"
#tfx[bg2]="$(tput setab 2 2>/dev/null)"
#tfx[bg3]="$(tput setab 3 2>/dev/null)"
#tfx[bg4]="$(tput setab 4 2>/dev/null)"
#tfx[bg5]="$(tput setab 5 2>/dev/null)"
#tfx[bg6]="$(tput setab 6 2>/dev/null)"
#tfx[bg7]="$(tput setab 7 2>/dev/null)"
tfx[bg0]="$(printf "\e[40m")"
tfx[bg1]="$(printf "\e[41m")"
tfx[bg2]="$(printf "\e[42m")"
tfx[bg3]="$(printf "\e[43m")"
tfx[bg4]="$(printf "\e[44m")"
tfx[bg5]="$(printf "\e[45m")"
tfx[bg6]="$(printf "\e[46m")"
tfx[bg7]="$(printf "\e[47m")"
# Background Proper Name
#tfx[bgBlack]="${tfx[bg0]}"
tfx[bgRed]="${tfx[bg1]}"
tfx[bgGreen]="${tfx[bg2]}"
tfx[bgYellow]="${tfx[bg3]}"
tfx[bgBlue]="${tfx[bg4]}"
tfx[bgMagenta]="${tfx[bg5]}"
tfx[bgCyan]="${tfx[bg6]}"
#tfx[bgWhite]="${tfx[bg7]}"
# Background Bright
#tfx[bg8]="$(tput setab 8 2>/dev/null)"
#tfx[bg9]="$(tput setab 9 2>/dev/null)"
#tfx[bg10]="$(tput setab 10 2>/dev/null)"
#tfx[bg11]="$(tput setab 11 2>/dev/null)"
#tfx[bg12]="$(tput setab 12 2>/dev/null)"
#tfx[bg13]="$(tput setab 13 2>/dev/null)"
#tfx[bg14]="$(tput setab 14 2>/dev/null)"
#tfx[bg15]="$(tput setab 15 2>/dev/null)"
tfx[bg8]="$(printf "\e[100m")"
tfx[bg9]="$(printf "\e[101m")"
tfx[bg10]="$(printf "\e[102m")"
tfx[bg11]="$(printf "\e[103m")"
tfx[bg12]="$(printf "\e[104m")"
tfx[bg13]="$(printf "\e[105m")"
tfx[bg14]="$(printf "\e[106m")"
tfx[bg15]="$(printf "\e[107m")"
# Background Bright Numbers Shifted With Suffix
tfx[bg0b]="${tfx[bg8]}"
tfx[bg1b]="${tfx[bg9]}"
tfx[bg2b]="${tfx[bg10]}"
tfx[bg3b]="${tfx[bg11]}"
tfx[bg4b]="${tfx[bg12]}"
tfx[bg5b]="${tfx[bg13]}"
tfx[bg6b]="${tfx[bg14]}"
tfx[bg7b]="${tfx[bg15]}"
# Background Bright Proper Name
#tfx[bgBlackBright]="${tfx[bg8]}"
tfx[bgRedBright]="${tfx[bg9]}"
tfx[bgGreenBright]="${tfx[bg10]}"
tfx[bgYellowBright]="${tfx[bg11]}"
tfx[bgBlueBright]="${tfx[bg12]}"
tfx[bgMagentaBright]="${tfx[bg13]}"
tfx[bgCyanBright]="${tfx[bg14]}"
#tfx[bgWhiteBright]="${tfx[bg15]}"
# Background Strong/Weak Scale
function tfxLightBg {
    # Background Strong/Weak Scale
    tfx[bgStrong]="${tfx[bg7]}"
    tfx[bgStrongBright]="${tfx[bg15]}"
    #
    tfx[bgStrongMid]="$(printf "\e[48;5;235m")"
    tfx[bgMidStrong]="$(printf "\e[48;5;239m")"
    tfx[bgMid]="$(printf "\e[48;5;244m")"
    tfx[bgMidWeak]="$(printf "\e[48;5;247m")"
    tfx[bgWeakMid]="$(printf "\e[48;5;251m")"
    #
    tfx[bgWeak]="${tfx[bg0]}"
    tfx[bgWeakBright]="${tfx[bg8]}"
}
function tfxDarkBg {
    tfx[bgStrong]="${tfx[bg0]}"
    tfx[bgStrongBright]="${tfx[bg8]}"
    #
    tfx[bgStrongMid]="$(printf "\e[48;5;251m")"
    tfx[bgMidStrong]="$(printf "\e[48;5;247m")"
    tfx[bgMid]="$(printf "\e[48;5;244m")"
    tfx[bgMidWeak]="$(printf "\e[48;5;239m")"
    tfx[bgWeakMid]="$(printf "\e[48;5;235m")"
    #
    tfx[bgWeak]="${tfx[bg7]}"
    tfx[bgWeakBright]="${tfx[bg15]}"
}
case "$tfxTheme" in
  light ) tfxLightBg ;;
  dark | * ) tfxDarkBg ;;
esac
# Background Reset to Default
tfx[bgD]="$(printf "\e[49m")"
tfx[bgDefault]="${tfx[bgD]}"
tfx[bgOff]="${tfx[bgD]}"

# Underline attributes.
#tfx[ul]="$(tput smul 2>/dev/null)"
tfx[ul]="$(printf "\e[4m")"
tfx[underline]="${tfx[ul]}"
tfx[ul2]="$(printf "\e[21m")"
tfx[underline2]="${tfx[ul]}"
#tfx[ulOff]="$(tput rmul 2>/dev/null)"
tfx[ulOff]="$(printf "\e[24m")"
tfx[underlineOff]="${tfx[ulOff]}"

# Bold and Faint attributes.
#tfx[bold]="$(tput bold 2>/dev/null)"
tfx[bold]="$(printf "\e[1m")"
tfx[boldOff]="$(printf "\e[22m")"
tfx[faint]="$(printf "\e[2m")"
# Same as boldOff, there are not separate codes.
tfx[faintOff]="${tfx[boldOff]}"

# "Standout" mode inverts the foreground and background colors.
#tfx[standout]="$(tput smso 2>/dev/null)"
tfx[standout]="$(printf "\e[7m")"
tfx[invert]="${tfx[standout]}"
#tfx[standoutOff]="$(tput rmso 2>/dev/null)"
tfx[standoutOff]="$(printf "\e[27m")"
tfx[invertOff]="${tfx[standoutOff]}"

# Crossed out attribute.
tfx[crossout]="$(printf "\e[9m")"
tfx[strikeout]="${tfx[crossout]}"
tfx[crossoutOff]="$(printf "\e[29m")"
tfx[strikeoutOff]="${tfx[crossoutOff]}"

# All text attributes off.
#tfx[off]="$(tput sgr0 2>/dev/null)"
tfx[off]="$(printf "\e[0m")"
# Set to "original pair" of fg and bg colors.
#tfx[op]="$(tput op 2>/dev/null)"
tfx[op]="$(printf "\e[39m\e[49m")"
tfx[fgBgDefault]="${txf[op]}"
tfx[fgBgOff]="${txf[op]}"

# Functions to change to light mode or dark mode on demand.
function tfxLight {
  tfxLightFg
  tfxLightBg
}
function tfxDark {
  tfxDarkFg
  tfxDarkBg
}

# Convert any SGR sequence into it's actual terminal code.
function tfxSgr {
  printf "\e[%sm" "$@"
}

# "5;" is for the 8-bit lookup table (256 colors).
# 0-7 are standard colors.
# 8-15 are bright colors.
# 16-231 are various colors.
# 232-255 are grayscale colors (24 total shades).
function tfxFg {
  printf "\e[38;5;%sm" "$1"
}
function tfxBg {
  printf "\e[48;5;%sm" "$1"
}
function tfxFgBg {
  printf "\e[38;5;%sm\e[48;5;%sm" "$1" "$2"
}

# "2;" is for RGB values (0-255).
function tfxFgRgb {
  printf "\e[38;2;%s;%s;%sm" "$1" "$2" "$3"
}
function tfxBgRgb {
  printf "\e[48;2;%s;%s;%sm" "$1" "$2" "$3"
}
