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
# expand global aliases when _not_ in the command position
zstyle ':completion:*' completer _expand_trailing_alias _complete _ignored
_expand_trailing_alias () {
  [[ $LBUFFER = *[^\ ]*[\ ]*[^\ ] ]] || return 1 # don't expand first word
  local word=$IPREFIX$PREFIX$SUFFIX$ISUFFIX
  local tmp=$galiases[$word]
  [[ -n $tmp ]] || return 1
  local -a toks=(${(z)LBUFFER})
  [[ $toks[-2] = [\|] ]] && return 1 # don't expand after pipe
  [[ -n $tmp ]] && _wanted aliases expl alias compadd -UQ -- ${tmp%%[[:blank:]]##} || return 1
}

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
  # commands and parameters that we never want suggested
  local IGNORE=(
    '_*|which-command|aliases|hist*s|zsh_sched*|backward-*-*|(up|down)-line-or-beginning-search|zle-*|bashbug'
    'aws_completer|(brew|git|kubectl|podman)-*|kubecolor|bundler|less(echo|key)|sha(1|224)(|sum)|(python|pip)3.*|pod(2*|checker)'
    'comp(add|arguments|call|ctl|describe|files|groups|quote|set|tags|try|values|audit|def|dump|gen|init|install|lete|*funcs)'
  )

  # don't print errors when I fat-finger `mkdir` as `mdir`
  [[ -v commands[mdir] ]] || _mtools () { _default }

  case $OSTYPE in
    darwin*)
      IGNORE+=(
        # unwanted binaries from apple
        '*[[:alpha:]]5.<->(|.pl)|(md|sha)<->sum|ht(digest|passwd|txt2dbm)|ab|checkgid|logresolve|rotatelogs'
        'k(admin*|cc|dcsetup|destroy|getcred|init|list*|passwd|rb[5s]*|tutil|switch|cditto|ext[cflsu]*|mutil)|mkextunpack'
        'apple*camerad|hi(|d)util|mcx*|pwd_mkdb|pwpolicy|sdx|tclsh*|tk(con|mib|pp)|serverinfo|wish*'
        'DeRez|DirectoryS*|GetF*|ResM*|Rez|SetF*|SplitF*|cups*|lp*|ppd*|weakpass_edit|update_*'
        'j(ar*|ava*|cmd|con*|db|deps|hsdb|image|info|js|link|map|package|ps|runscript|shell|sta*)'
        'orbd|*pack200|rmi*|serialver|tnameserv|(key|policy|server)tool'
        # unwanted binaries from brew
        'luajit-2.*|idle3*|pydoc*|python3-*|wheel3*|2to3*|git2|zsh-5*'
      )
      # unhash non-executable junk apple left in /usr/sbin, and .DS_Store just in case we have any in $path
      unset 'commands[authserver]' 'commands[envvars]' 'commands[envvars-std]' 'commands[iRATBW.mlmodelc]' 'commands[.DS_Store]'

      # disable _java: java isn't normally installed, _java breaks if it gets activated on binstubs
      _java () { _default }
    ;;
    linux*)
      IGNORE+=( '(|v)dir|fdfind|zsh5' )
    ;;
  esac

  zstyle ':completion::complete:-command-:*:*' ignored-patterns $IGNORE
}

# don't autocomplete subcommands for setting up autocomplete 🤦
zstyle ':completion::complete:(gh|glab|helm|k9s|kind|kubec(tl|olor)|op|trivy):*:*' ignored-patterns 'completion'
