#! /bin/false
# This file should be sourced, not executed.


[[ -v pathSources ]] && printf "%s\n" "Variable name collision on \"pathSources\". It will be unset."
[[ -v script ]] && printf "%s\n" "Variable name collision on \"script\". It will be unset."

declare scriptDir="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
pathSources="$scriptDir/dependencies"

while read -d '' script
do
  {
    source "${script}"
  } <&3 # Restore the terminal as stdin.
done 3>&1 < <(find -L "${pathSources}" -maxdepth 1 -type f -printf "%p\0" | sort -z)

unset pathSources
unset script
