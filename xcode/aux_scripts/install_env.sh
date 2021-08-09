# When you run Git from the command line, it runs in the environment as set up by your Shell. 
# GUI OS X apps, however, have no knowledge about your shell - and the PATH environment can be changed in many different places.
# Export our profile with path by ourselves

function source_home_file {
  file="$HOME/$1"
  [[ -f "${file}" ]] && source "${file}"
}

# Use specific exec due to Xcode has custom value of $PATH 
if [ -z "$(which pmd)" ]; then	
   source_home_file ".bash_profile" || source_home_file ".zshrc" || true
fi