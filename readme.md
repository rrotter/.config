# .config - rrotter's public dotfiles #

WIP

```
curl -OL https://raw.githubusercontent.com/rrotter/.config/refs/heads/macos/macos/10_language_and_display.zsh
chmod +x 10_language_and_display.zsh
./10_language_and_display.zsh
```

---

zsh, git, ssh, homebrew, kubectl, and other configuration

This opinionated repo expects nearly all config to live in `~/.config`. That's why even scripts
are in this directory, rather than the usual `~/.local/bin`: I keep `~/.local` entirely
ephemeral. A handful of symlinks are created during setup for programs that are absolutely
resistant to using `XDG_CONFIG_HOME`.

I keep a few files containing personal settings in a separate private repo which I checkout to
to `~/.private`. This is where I keep things that are environment specific like email addresses
and server names. The rest of this repo is easily usable without these details.

## Installation ##

#### clone repo ####

```
# clone to ~/.config
cd ~
git clone https://github.com/rrotter/.config
# clone ~/.private as well
git clone <REDACTED>

# run the idempotent init script to finish setup
# run it again any time to make sure everything is still correct!
.config/init.sh
```

#### List of files in my `~/.private/` repo ####

```
~/.private/init.sh # setup script
~/.private/aws/config # configure aws profiles and regions
~/.private/git/config # user.name, user.email, user.signingkey, commit.gpgsign
~/.private/git/allowedSigners # list of ssh keys I trust to sign git commits
~/.private/git/mailmap # beautify email addresses in `git log`
~/.private/ssh_config.d/ # several additional ssh config files that get symlinked into ~/.ssh/config.d/ on a per-host basis
```

Generate these files yourself as needed with content specific to your environment. The only one
that is more-or-less required is `~/.private/git/config`.

#### finally ####
Log out and in again, or open a new terminal window so `.zshrc` gets sourced.

## Recommended reading ##
- [Configuring Zsh Without Dependencies](https://thevaluable.dev/zsh-install-configure-mouseless/)
- [!! !* !$, etc](https://web.archive.org/web/20120506194734/mail.linux.ie/pipermail/ilug/2006-May/087799.html)

## References ##
- [git-config](https://git-scm.com/docs/git-config)
- [ZSH Documentation](https://zsh.sourceforge.io/Doc/Release/zsh_toc.html) - [Options](https://zsh.sourceforge.io/Doc/Release/Options.html) - [Startup Files](https://zsh.sourceforge.io/Doc/Release/Files.html#Startup_002fShutdown-Files)
- [Speed Test: Check the Existence of a Command in Bash and Zsh](https://www.topbug.net/blog/2016/10/11/speed-test-check-the-existence-of-a-command-in-bash-and-zsh/)
