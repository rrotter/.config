#!/bin/sh

# check/configure home dir

. ~/.config/scripts/functions.sh

# directories for links, history files, etc
mkdir -p -m 700 ~/.local/state/
mkdir -p -m 700 ~/.ssh/config.d/

# link files
mk_link .config/bash/bashrc ~/.bash_profile
mk_link .config/bash/bashrc ~/.bashrc
mk_link .config/curlrc ~/.curlrc
mk_link ../.config/ssh/config ~/.ssh/config
mk_link .config/zsh/zshenv ~/.zshenv
mk_link .config/zsh/zshrc ~/.zshrc

# create files
mk_file ~/.hushlogin

# check for files we probably don't want
assert_not_present ~/.bash_history
assert_not_present ~/.gitconfig
assert_not_present ~/.viminfo
assert_not_present ~/.vimrc
assert_not_present ~/.zhistory
assert_not_present ~/.zsh_history

# vim
if [ -x /usr/bin/vim ]; then
  if /usr/bin/vim --version | fgrep 'vimrc file' | fgrep -q XDG_CONFIG_HOME; then
    # vim >= 9.1 can use .config/vim/vimrc
    assert_not_present ~/.vim
  else
    # vim < 9.1 needs symlink
    mk_link .config/vim ~/.vim
  fi
else
  echo "WARNING: can't find /usr/bin/vim, skipping vim setup"
fi
