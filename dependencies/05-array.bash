#!/bin/false
# This file should be sourced, not executed.

containsElement () {
  # https://stackoverflow.com/a/8574392
  # Usage of "containsElement".
  # $ array=("something to search for" "a string" "test2000")
  # $ containsElement "a string" "${array[@]}"
  # $ echo $?
  # 0
  # $ containsElement "blaha" "${array[@]}"
  # $ echo $?
  # 1
  #
  local match element
  match="$1"; shift;
  # If "in words" is not present, the for command executes the commands once for each positional parameter that is set, as if 'in "$@"' had been specified.
  for element; do [[ "$element" == "$match" ]] && return 0; done
  return 1
}

function getElementsOfAWithoutB {
  # Usage:
  # arrayRemaining=''
  # arrayA=('a' 'b')
  # arrayB=('a' 'c')
  # getElementsOfAWithoutB arrayRemaining arrayA arrayB
  # # arrayRemaining contains a single element 'b'.
  #
  # Parse arguments.
  # Use "local -n" to pass by reference.
  if [[ -n $1 ]]
  then local -n arrayRemaining="$1"; shift;
  else logError 'Must provide argument arrayRemaining'; return 1;
  fi;
  #
  if [[ -v $1 ]]
  then local -n arrayA="$1"; shift;
  else logError 'Must provide argument arrayA'; return 1;
  fi;
  #
  if [[ -v $1 ]]
  then local -n arrayB="$1"; shift;
  else logError 'Must provide argument arrayB'; return 1;
  fi;
  #
  # Create "arrayRemaining".
  # https://stackoverflow.com/a/16861932
  local i elementToRemove
  arrayRemaining=("${arrayA[@]}")
  for elementToRemove in "${arrayB[@]}"; do
    for i in "${!arrayRemaining[@]}"; do
      if [[ ${arrayRemaining[i]} = $elementToRemove ]]; then
        unset "arrayRemaining[i]"
      fi
    done
  done
}

function isAssociativeArray {
  if [[ "$(declare -p "$1" 2>/dev/null)" == "declare -A"* ]]
  then return 0
  else return 1
  fi
}

function printAssociativeArray {
  local -n arrayName="$1"
  for element in "${!arrayName[@]}"
  do printf "[%s]=%s\n" "$element" "${arrayName[$element]}"
  done
}

function logAssociativeArray {
  # arrayAssoc must be an associative array, declared with the "-A" option.
  if isAssociativeArray "$1"
  then declare -n arrayAssoc="$1"; shift;
  else logError 'Must provide first argument as an associative array.'; return 4;
  fi
  #
  for e in "${!arrayAssoc[@]}"
  do
    log "[$e]=${arrayAssoc[$e]}"
  done
}
