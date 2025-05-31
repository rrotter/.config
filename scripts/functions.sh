# utility functions for initializing config repos 
#
# primarily developed with dash, but should be compatible with zsh and bash
#
# usage: source ~/.config/scripts/functions.sh
# (assumes this repo is checked out at ~/.config)
# set VERBOSE to an int greater than 0 to get verbose output

# set VERBOSE to 0 if it's not set, and 1 if it's not an int
export VERBOSE=${VERBOSE:-0}
[ "${VERBOSE#*[!0-9]}" != "$VERBOSE" ] && VERBOSE=1

##
# assert_not_present
#
# usages: assert_not_present file
#
# assert $file should not exist
#
##
assert_not_present () {
  if [ $# -ne 1 ]; then
    echo "assert_not_present: wrong number of args, found $#, expected 1!"
    return 1
  fi
  local file="$1"

  if [ -e "$file" ]; then
    echo "file should not exist, consider deleting: $file" >&2
    return 1
  else
    [ "$VERBOSE" -gt 1 ] && echo "file '$file' not present OK"
    return 0
  fi
}

##
# mk_file
#
# usage: mk_file file
#
# touch file only if it doens't exist, and assert that it is a regular file.
# $file must be an absolute path.
#
##
mk_file () {
  if [ $# -ne 1 ]; then
    echo "mk_file: wrong number of args, found $#, expected 1!"
    return 1
  fi
  local file="$1"
  if [ "${file#/}" = "$file" ]; then
    echo "mk_file: file '$file' looks like a relative path, absolute path required!" >&2
    return 1
  fi

  if [ -h "$file" ]; then
    echo "$file is expected to be a regular file, not a symlink" >&2
    return 1
  fi
  if [ -d "$file" ]; then
    echo "$file is expected to be a regular file, not a directory" >&2
    return 1
  fi
  if [ -x "$file" ]; then
    echo "$file is expected to be a regular file, not an executable" >&2
    return 1
  fi
  if [ -f "$file" ]; then
    [ "$VERBOSE" -gt 0 ] && echo "mk_file: $file OK"
    return 0
  else
    touch $file || return 1
    [ -f "$file" ] && echo "created empty file: $file"
  fi
}

##
# mk_link
#
# usage: mk_link source target
#
# Like ls -s, except: source be a file or directory that exists, and target
# must be an absolute path. Source may be absolute, or relative to dir
# containing $target.
#
##
mk_link () {
  if [ $# -ne 2 ]; then
    echo "mk_link: wrong number of args, found $#, expected 2" >&2
    return 1
  fi
  local source="$1"
  local target="$2"
  local dir=$(dirname "$target")
  local source_rp target_rp

  if [ "${target#/}" = "$target" ]; then
    echo "mk_link: target '$target' looks like a relative path, absolute path required!" >&2
    return 1
  fi
  cd "$dir" || return 1

  if [ ! -e "$source" ]; then
    echo "Source file '$source' not found!" >&2
    return 1
  fi
  if [ ! -e "$target" ]; then
    ln -vs "$source" "$target"
  fi
  source_rp=$(realpath "$source")
  target_rp=$(realpath "$target")
  if [ "$source_rp" = "$target_rp" ]; then
    [ "$VERBOSE" -gt 0 ] && echo "mk_link: $target OK"
    return 0
  else
    echo "Missing or invalid link: $target " >&2
    return 1
  fi
}
