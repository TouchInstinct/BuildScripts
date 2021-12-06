#!/bin/sh

# Description:
#   Add user defined enviroment if programm not found
#
# Parameters:
#   $1 - programm
#
# Examples of usage:
#   . install_env.sh pmd
#

# When you run Git from the command line, it runs in the environment as set up by your Shell. 
# GUI OS X apps, however, have no knowledge about your shell - and the PATH environment can be changed in many different places.
# Export our profile with path by ourselves

function source_home_file {
  file="$HOME/$1"

  #echo $file

  if [[ -f "${file}" ]]; then
    paathes="$(cat "${file}" | grep "^export PATH=")"

    while read paath
    do
      eval "$paath"
    done <<< "$paathes"
  else
    return 1
  fi

  return 0
}

# Use specific exec due to Xcode has custom value of $PATH 
if [ -z "$(which $1)" ]; then
   source_home_file ".bash_profile" || source_home_file ".zshrc" || true

   echo "User defined enviroment has been set for ${1}"
fi