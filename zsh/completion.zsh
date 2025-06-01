## compinit ##
zstyle ':completion::complete:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache
[[ -d $XDG_CACHE_HOME/zsh ]] || mkdir -p -m 700 $XDG_CACHE_HOME/zsh
autoload -Uz compinit && compinit -d $XDG_CACHE_HOME/zsh/zcompdump

## settings ##
zstyle ':completion:*' special-dirs '..'
zstyle ':completion:*' ignore-parents pwd
# complete dirs in cd and pushd w/ $cdpath only if there is no other match
zstyle ':completion:*:complete:(cd|pushd):*' tag-order 'local-directories named-directories'
# don't complete macos builtin daemon users
zstyle ':completion:*:*:*:users' ignored-patterns '_*'
# use LS_COLORS for file completion
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# git filename completion: partially case sensitive
zstyle ':completion::complete:git-*:argument-rest:*-files' matcher 'm:{[:lower:]}={[:upper:]}'
# add _expand_alias completer, to expand global aliases
zstyle ':completion:*' completer _complete _expand_alias _ignored
zstyle ':completion:*' regular false

## configure completions for specific commands ##
compdef _kubectl kubecolor
# import bash completions
autoload -Uz bashcompinit && bashcompinit
complete -C aws_completer aws
complete -C tk tk
complete -C tofu tofu
complete -C terraform terraform
# source completions that are missing from filesystem
if [[ $OSTYPE == linux* ]]; then
  [[ -v commands[gh]      ]] && [[ ! -v functions[_gh]      ]] && source <(gh      completion -s zsh)
  [[ -v commands[kubectl] ]] && [[ ! -v functions[_kubectl] ]] && source <(kubectl completion    zsh)
fi

## suppress bad completions ##
compdef -d diff glow # unhelpful completions

() {
  # commands (and other things in the "command position") that we never want suggested
  local IGNORE=(
    'aliases|aws_completer|(brew|git|kubectl|podman)-*|kubecolor|bundler|less(echo|key)|sha(1|224)(|sum)|(|v)dir|(python|pip)3.*|which-command'
    'comp(add|arguments|call|ctl|describe|files|groups|quote|set|tags|try|values|audit|def|dump|gen|init|install|lete|*funcs)|hist*s|zsh_sched*'
  )

  # don't print errors when I fat-finger `mkdir` as `mdir`
  [[ -v commands[mdir] ]] || _mtools () { _default }

  case $OSTYPE in
    darwin*)
      IGNORE+=(
        # unwanted binaries from apple
        '*[[:alpha:]]5.<->(|.pl)|(md|sha)<->sum|ht(digest|passwd|txt2dbm)|ab|checkgid|logresolve|rotatelogs'
        'k(admin*|cc|dcsetup|destroy|getcred|init|list*|passwd|rb*|tutil|switch|cditto|ext*|mutil)'
        'apple*camerad|hi(|d)util|mcx*|pwd_mkdb|pwpolicy|sdx|tclsh*|tk(con|mib|pp)|serverinfo|wish*'
        'DeRez|DirectoryS*|GetF*|ResM*|Rez|SetF*|SplitF*|cups*|lp*|ppd*|weakpass_edit'
        'j(ar*|ava*|cmd|con*|db|deps|hsdb|image|info|js|link|map|package|ps|runscript|shell|sta*)'
        'orbd|*pack200|rmi*|serialver|tnameserv|(key|policy|server)tool'
        # unwanted binaries from brew
        '*.lima|luajit-2.*|idle3*|pydoc*|python3-*|wheel3*|2to3*|git2'
      )
      # unhash non-executable junk that apple left in /usr/sbin
      unset 'commands[authserver]' 'commands[envvars]' 'commands[envvars-std]' 'commands[iRATBW.mlmodelc]'

      # disable _java: java isn't normally installed, _java breaks if it gets activated on binstubs
      _java () { _default }
    ;;
    linux*)
      IGNORE+=( 'fdfind|zsh5' )
    ;;
  esac

  zstyle ':completion::complete:-command-:*:*' ignored-patterns $IGNORE
}

# don't autocomplete subcommands for setting up autocomplete 🤦
zstyle ':completion::complete:(gh|glab|helm|k9s|kind|kubec(tl|olor)|limactl|op|trivy):*:*' ignored-patterns 'completion'
