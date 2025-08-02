#!/bin/false
# This file should be sourced, not executed.

function ifDo {
  if isTruthy "$1"
  then shift; "$@"
  else return 0
  fi
}

# Assert that the last command exited successfully.
# Useful especially when not using "errexit" option.
# Usage:
# > function somethingUseful {
# >   commandThatFails
# >   assertLast || return $?
# > }
# > somethingUseful && echo ok || echo nok
# # Output: "nok"
function assertLast {
  local e=$?
  if (( $e != 0 ))
  then
    logError "\$?=$e"
    return $e
  fi
}

# Usage:
# > assertDefined undefinedVar || return $?
function assertDefined {
  if ! [[ -v ${1} ]]
  then
    logError "Must define variable \"${1}\"."
    return 4
  fi
}

# Check if input is one word. Useful for verifying if an argument is broken by word splitting.
# Usage:
# #> if ! isOneWord $var
# #> then echo "Var must not have characters that cause word splitting, like spaces."; exit 1;
# #> fi
function isOneWord {
  if [[ -z $2 ]]
  then return 0
  else return 1
  fi
}

#https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function joinBy {
  local d="$1"; shift;
  printf "%s" "$1"; shift;
  # "Pattern substitution" expansion adds the delimiter at the beginning of each word in arguments.
  printf "%s" "${@/#/$d}"
}
function joinByB {
  local d="$1"; shift;
  printf "%b" "$1"; shift;
  for x in "$@"
  do
    printf "%s" "$d"
    printf "%b" "$x"
  done
}

# Find Up
# Usage:
# find-up <starting-path> <args-to-find>...
function find-up {
  local nextPath="${1:?Must give path to search.}"; shift;
  local pathsUp=()
  #
  (
    cd "$nextPath"
    while [[ "$PWD" != / ]]
    do
      pathsUp+=("$PWD")
      cd ..
    done
    #
    find "${pathsUp[@]}" -maxdepth 1 "$@"
  )
}

function fzf-help {
  logUnderline "KEY      | ACTION               "
  log          "Letters  | Search."
  log          "Ctl-W    | Backspace word."
  log          "Arrows   | Navigate."
  log          "Tab      | Add row to selection."
  log          "Enter    | Accept selection."
  log          "Esc, Esc | Cancel selection."
}

declare patternValidVarName='^[a-zA-Z_][a-zA-Z_0-9]*$'
function isValidVarName {
  # Use all arguments. If there are multiple, the whitespace will cause unsuccessful return.
  [[ "$*" =~ $patternValidVarName ]]
}
function logVars {
  declare varName
  for varName in "$@"
  do log "$varName=${!varName}"
  done
}

# "timeout" is a binary, not a shell builtin, so it cannot be used on functions or builtins.
# Usage:
# > timeoutCmd 1 sleep 2
# Exits after 1 second with code 143.
function timeoutCmd {
  declare cmd_pid sleep_pid retval
  declare sleepTime="$1"; shift;
  #
  # Run the given command in the background.
  # stdin is connected to the terminal by using "<&1". By default it wasn't.
  # stdout and stderr are still connected to the terminal by default.
  #"$@" <&1 &
  "$@" &
  cmd_pid=$!
  #
  # Run the killer process in the background so we can return from timeoutCmd
  # in the case the command exits within time.
  {
    sleep "$sleepTime"
    kill "$cmd_pid" 2>/dev/null
  } &
  sleep_pid=$!
  #
  wait "$cmd_pid"
  retval=$?
  # In the case that the command completed on it's own, kill the killer process so it doesn't linger.
  kill "$sleep_pid" 2>/dev/null
  return "$retval"
}
# "timeout" is a binary, not a shell builtin, so it cannot be used on functions or builtins.
# Use "&" to background a function or subshell to make it run in a subprocess that can be killed with timeoutPid.
# Usage:
# > timeoutPid <termTime>[,<killTime>][,<waitPollTime>] <processId>
# It can be backgrounded:
# > timeoutPid <termTime>[,<killTime>][,<waitPollTime>] <processId> &
timeoutPid () {
  declare termTime killTime waitPollTime
  IFS=',' read termTime killTime waitPollTime <<<"$1"
  termTime=${termTime:-1}
  killTime=${killTime:-1}
  waitPollTime=${waitPollTime:-0.01}
  declare pid="$2"
  #
  if ! [[ -d "/proc/$pid" ]]
  then return 0 # Return early if the process doesn't exist.
  fi
  #
  sleep $termTime
  if [[ -d "/proc/$pid" ]]
  then kill $pid
  else return 0 # Return early if the process doesn't exist.
  fi
  # Set killTime to "n" to not use SIGKILL
  if [[ $killTime != n ]]
  then
    sleep $killTime
    if [[ -d "/proc/$pid" ]]
    then kill -s SIGKILL $pid
    fi
  else
    # wait for a process that is not a child of the current shell.
    while [[ -d "/proc/$pid" ]]
    do sleep "$waitPollTime"
    done
  fi
}
