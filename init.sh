#!/bin/sh

set -e

LINK_COMMAND=
FAIL=

# detect OS and calculate LINK_COMMAND
# set COREUTILS_LN to short circuit this
if [ -n "$COREUTILS_LN" ]; then
  LINK_COMMAND="$COREUTILS_LN -v -sr"
else
  case $(uname -s) in
  Linux)
    LINK_COMMAND="ln -v -sr"
    ;;
  NetBSD|FreeBSD)
    LINK_COMMAND="install -v -lsr"
    ;;
  Darwin)
    if [ $(uname -r | cut -d. -f1) -ge 24 ]; then
      LINK_COMMAND="install -v -lsr"
    fi
    ;;
  esac
fi

if [ -n "$LINK_COMMAND" ]; then
  echo "LINK_COMMAND: '$LINK_COMMAND'"
else
  echo 'Supported OSes are: Linux, FreeBSD (since 9.3), NetBSD, and macOS (since 15).'
  echo 'It appears you are on an unsupported OS. To continue, install a coreutils compatible'
  echo 'implementation of `ln` and tell me where to find it with: `export COREUTILS_LN=/path/to/ln`.'
  exit 1
fi

relative_symlink () {
  local source="$1"
  local target="$2"

  if [ ! -e "$source" ]; then
    echo "Source file '$source' not found, aborting!" >&2
    return 1
  fi

  if [ -e "$target" ]; then
    if [ ! -h "$target" ]; then
      echo "$target: already exists, but is not a symlink, aborting!" >&2
      return 1
    elif [ "$(realpath "$source")" != "$(realpath "$target")" ]; then
      echo "$target: already exists, but is not a link to $source, aborting!"
      return 1
    fi
    # link already exists
    echo "$target: OK"
    return
  fi

  $LINK_COMMAND "$source" "$target"
}

assert_not_present () {
  while [ $# -gt 0 ]; do
    if [ -e "$1" ]; then
      echo "$1: present, but should NOT exist, consider deleting" >&2
      FAIL=1
    fi
    shift
  done
}

# create XDG_STATE_HOME
echo "mkdir -v -p -m 700 ~/.local/ ~/.local/state/"
mkdir -v -p -m 700 ~/.local/ ~/.local/state/

# create ssh config dir
echo "mkdir -v -p -m 700 ~/.ssh/ ~/.ssh/config.d/"
mkdir -v -p -m 700 ~/.ssh/ ~/.ssh/config.d/

# create .hushlogin
if [ ! -e ~/.hushlogin ]; then
  echo "touch ~/.hushlogin"
  touch ~/.hushlogin
fi

# create symlinks
relative_symlink ~/.config/bash/bashrc ~/.bash_profile
relative_symlink ~/.config/bash/bashrc ~/.bashrc
relative_symlink ~/.config/curlrc ~/.curlrc # fixed in curl 8.10.0
relative_symlink ~/.config/ssh/config ~/.ssh/config
relative_symlink ~/.config/zsh/zshenv ~/.zshenv
relative_symlink ~/.config/zsh/zshrc ~/.zshrc

# source ~/.private/init.sh
# (optional step, skipped if this file does not exist)
if [ -e ~/.private/init.sh ]; then
  echo "source ~/.private/init.sh"
  . ~/.private/init.sh
else
  echo "~/.private/init.sh not found, did you checkout ~/.private?"
fi

# check for unwanted files
assert_not_present ~/.bash_history ~/.bash_sessions
assert_not_present ~/.gitconfig
assert_not_present ~/.lesshst
assert_not_present ~/.python_history
assert_not_present ~/.viminfo ~/.vimrc
assert_not_present ~/.zhistory ~/.zsh_history

if [ -n "$FAIL" ]; then
  echo "Completed with errors. Fix issues and run again to check." >&2
  exit 1
fi
