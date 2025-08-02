#!/bin/false
# This file should be sourced, not executed.

function likeBool {
  [[ ${1,,} =~ ^((t(rue)?|1)|(f(alse)?|0))?$ ]]
}
function normalizeBool {
  # Normalize input.
  if [[ -z $1 ]]; then
    : # Nothing in, nothing out.
  elif [[ ${1,,} =~ ^(t(rue)?|1)$ ]]; then
    printf "%s" "true"
  else
    printf "%s" "false"
  fi
}
function isTruthy {
  if (( $# == 0 )); then return 1; fi;
  while (( $# > 0 )); do
    [[ ${1,,} =~ ^(t(rue)?|1)$ ]] || return 1
    shift
  done
  return 0
}
