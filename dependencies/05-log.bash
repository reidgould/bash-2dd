#!/bin/false
# This file should be sourced, not executed.

# "-t" tests if the file descriptor given is open on a terminal.
# This is used to avoid printing color codes when output is to a file or program.

# values: always, never, auto
logColor=${logColor:-auto}
function useColor {
  if [[ $logColor == always ]]
  then return 0
  elif [[ $logColor == never ]]
  then return 1
  else # Handles case for [[ $logColor == auto ]]
    if [[ -t 1 ]]
    then return 0
    else return 1
    fi
  fi
}

function log {
  printf "%s\n" "$*" >&2
}
function logWarning {
  if useColor
  then printf "${tfx[fgYellow]}%s${tfx[fgOff]}\n" "$*" >&2
  else printf "Warning: %s\n" "$*" >&2
  fi
}
function logError {
  if useColor
  then printf "${tfx[fgRed]}%s${tfx[fgOff]}\n" "$*" >&2
  else printf "Error: %s\n" "$*" >&2
  fi
}
function logSection {
  if useColor
  then printf "${tfx[fgGreen]}%s${tfx[fgOff]}\n" "$*" >&2
  else printf "Section: %s\n" "$*" >&2
  fi
}
doLogDebug=${doLogDebug:-false}
function ifDebug {
  if [[ ! $doLogDebug == true ]]; then return; fi;
  "$@"
}
function logDebug {
  if [[ ! $doLogDebug == true ]]; then return; fi;
  if useColor
  then printf "${tfx[fgMid]}%s${tfx[fgOff]}\n" "$*" >&2
  else printf "Debug: %s\n" "$*" >&2
  fi
}
function logDebugMark {
  if [[ ! $doLogDebug == true ]]; then return; fi;
  local markText="${BASH_SOURCE[1]}::${FUNCNAME[1]}::${BASH_LINENO[0]}"
  if useColor
  then printf "${tfx[fgMid]}%s${tfx[fgOff]}\n" "$markText" >&2
  else printf "Debug: %s\n" "$markText" >&2
  fi
}
#function test-logDebugMark {
#  echo 2
#  echo 3
#  echo 4
#  logDebugMark
#  echo 6
#  logDebugMark
#}
#function logCommand {
#  # todo: use "isOneWord" in a loop to add quotes around words that would split.
#  if useColor
#  then printf "${tfx[fgBlue]}❯ %s${tfx[fgOff]}\n" "$*" >&2
#  #else printf "Command: %s\n" "$*" >&2
#  else printf "❯ %s\n" "$*" >&2
#  fi
#}
function logCommand {
  # Start line.
  if useColor
  then printf "${tfx[fgBlue]}❯ " >&2
  #else printf "Command: " >&2
  else printf "❯ " >&2
  fi
  #
  # Print words.
  declare separator=""
  for word in "$@"
  do
    if isOneWord $word
    then printf "$separator%s" "$word"
    else printf "$separator\"%s\"" "$word"
    fi
    separator=" "
  done
  #
  # End line.
  if useColor
  then printf "${tfx[fgOff]}\n" >&2
  else printf "\n" "$*" >&2
  fi
}


function logInvert {
  if useColor
  then printf "${tfx[invert]}%s${tfx[off]}\n" "$*" >&2
  else printf "%s\n" "$*" >&2
  fi
}
function logUnderline {
  if useColor
  then printf "${tfx[ul]}%s${tfx[off]}\n" "$*" >&2
  else printf "%s\n" "$*" >&2
  fi
}


function logh1 {
  if useColor
  then printf "${tfx[invert]}${tfx[fgGreen]}# %s${tfx[off]}\n" "$*" >&2
  else printf "\n\n# %s\n" "$*" >&2
  fi
}
function logh2 {
  if useColor
  then printf "${tfx[ul]}${tfx[fgGreen]}## %s${tfx[off]}\n" "$*" >&2
  else printf "## %s\n" "$*" >&2
  fi
}
function logh3 {
  if useColor
  then printf "${tfx[ul]}${tfx[fgGreen]}### %s${tfx[off]}\n" "$*" >&2
  else printf "### %s\n" "$*" >&2
  fi
}
function logh4 {
  if useColor
  then printf "${tfx[ul]}${tfx[fgGreen]}#### %s${tfx[off]}\n" "$*" >&2
  else printf "#### %s\n" "$*" >&2
  fi
}
function logh5 {
  if useColor
  then printf "${tfx[ul]}${tfx[fgGreen]}##### %s${tfx[off]}\n" "$*" >&2
  else printf "##### %s\n" "$*" >&2
  fi
}


function logTest {
  printf "${logTestIndent}%s\n" "$*" >&${logTestFD:-2}
}
function logPass {
  if useColor
  then printf "${logTestIndent}${tfx[fgGreen]}✓ pass${tfx[off]} %s\n" "$*" >&${logTestFD:-2}
  else printf "${logTestIndent}✓ pass %s\n" "$*" >&${logTestFD:-2}
  fi
}
function logFail {
  if useColor
  then printf "${logTestIndent}${tfx[fgRed]}✗ fail${tfx[off]} %s\n" "$*" >&${logTestFD:-2}
  else printf "${logTestIndent}✗ fail %s\n" "$*" >&${logTestFD:-2}
  fi
}
function logSkip {
  if useColor
  then printf "${logTestIndent}${tfx[fgBlue]}- skip${tfx[off]} %s\n" "$*" >&${logTestFD:-2}
  else printf -- "${logTestIndent}- skip %s\n" "$*" >&${logTestFD:-2}
  fi
}


# Chop lines to the width of the terminal.
# Adds a character indicating that the line is chopped.
# When color is in use, adds a character to prevent color from bleeding to next line.
# Color characters will cause line to appear shorter than the terminal width.
# Usage:
# > command-with-long-output | chop
function chop {
  declare numberChars=$(( COLUMNS - 1 ))
  if useColor
  then
    # Chop character with default color.
    #then cut -c"-$numberChars" | sed -e "s/$/${tfx[off]}/" -e "/.\{$numberChars,\}/s/$/${tfx[invert]}❯${tfx[off]}/"
    #sed "/.\{$numberChars,\}/s/^\(.\{$numberChars\}\).*$/\1${tfx[off]}${tfx[invert]}❯${tfx[off]}/"
    # Chop character with line color.
    #cut -c"-$numberChars" | sed -e "/.\{$numberChars,\}/s/$/${tfx[invert]}❯/" -e "s/$/${tfx[off]}/"
    sed "/.\{$numberChars,\}/s/^\(.\{$numberChars\}\).*$/\1${tfx[invert]}❯${tfx[off]}/"
  else
    #cut -c"-$numberChars" | sed "/.\{$numberChars,\}/s/$/❯/"
    sed "/.\{$numberChars,\}/s/^\(.\{$numberChars\}\).*$/\1❯/"
  fi
}
