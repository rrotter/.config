## prompt configuration ##
setopt TRANSIENT_RPROMPT
### IMPORTANT - DO NOT REMOVE ###
# Ensure RPROMPT can be rendered on the first line of a new shell (zsh bug?)
RPROMPT=
# When unset right indent defaults to 1, not 0 (zsh "feature"?)
ZLE_RPROMPT_INDENT=

## printed prompt ##
# PS1 is expected to never change after this file is sourced
# All dynamic content comes from prompt expansion:
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
# hostname, only if we're on SSH
PS1=${SSH_CLIENT+'%F{168}%m%f '}
# one segment path
PS1+='%(3~.%1~.%(3/.%2~.%1~)) '
# number of stopped jobs
PS1+='%(1j.%F{blue}[%j]%f .)'
# color the prompt char to show status
# 130 (^C) yellow, 141 (SIGPIPE), 146 (^Z) blue, else: red
PS1+='%(?..%(130?.%F{yellow}.%(141?.%F{cyan}.%(146?.%F{blue}.%F{red}))))%#%f '

## terminal integration ##
# OSC 133 marks at start and end of prompt
PS1=$'%{\e]133;A\a%}'${PS1}$'%{\e]133;B;\a%}'
PS2=$'%{\e]133;A;k=s\a%}'${PS2}$'%{\e]133;B;\a%}'

__terminal_integration_preexec() {
  print -n '\e]133;C\a'
  # set title
  print -rn $'\e]2;'"${(V)1}"$'\a'
}
__terminal_integration_precmd() {
  print -n '\e]133;D\a'
  # report cwd
  print -n '\e]7;kitty-shell-cwd://'"$HOST""$PWD"'\a'
  # set title
  print -rn $'\e]2;'"${(%):-%(4~|…/%3~|%~)}"$'\a'
}
__terminal_integration_chpwd() {
  # report cwd
  print -n '\e]7;kitty-shell-cwd://'"$HOST""$PWD"'\a'
}

# zsh hooks
typeset -aU chpwd_functions=( __async_prompt_chpwd )
typeset -aU precmd_functions=( __async_prompt_reap __async_prompt_precmd __terminal_integration_precmd )
typeset -aU preexec_functions=( __async_prompt_reap __async_prompt_prexec __terminal_integration_preexec )

autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-pre-redraw __async_prompt_zle_segment_trigger

# track outstanding fds
typeset -gaU __async_prompt_fds

__async_prompt_zle_segment_trigger () {
  local cmd=${${(zA)BUFFER}[1]}
  if [[ $cmd = (k|kubectl|k9s|helm) ]]; then
    if [[ ! -v __KUBEPROMPT ]]; then
      local -i fd
      exec {fd} < <(echo "%F{blue}⎈%f$(kubectl config current-context)")
      __async_prompt_fds+=($fd)
      zle -F $fd __async_prompt_set_kube_segment
    fi
  else
    if [[ -v __KUBEPROMPT ]]; then
      unset __KUBEPROMPT
      __async_prompt_draw_rprompt
    fi
  fi
}

# at new prompt, set git segment, clear other segments
__async_prompt_precmd () {
  RPROMPT=$__GITPROMPT
  unset __KUBEPROMPT
  local -i fd
  exec {fd} < <(__async_prompt.git-status)
  __async_prompt_fds+=($fd)
  zle -F $fd __async_prompt_set_git_segment
}

# on sending cmd, clear all segments except git
__async_prompt_prexec () {
  RPROMPT=$__GITPROMPT
  unset __KUBEPROMPT
}

# reap outstanding fds
__async_prompt_reap () {
  [[ -v __async_prompt_fds ]] || return
  local fd
  for fd in $__async_prompt_fds; do
    zle -F $fd
    exec {fd}<&-
  done
  __async_prompt_fds=()
}

# on chpwd, clear git segment
__async_prompt_chpwd () {
  RPROMPT=
  unset __GITPROMPT
}

__async_prompt_set_git_segment () {
  __GITPROMPT="$(<&$1)"
  __async_prompt_draw_rprompt $1
}

__async_prompt_set_kube_segment () {
  __KUBEPROMPT="$(<&$1)"
  __async_prompt_draw_rprompt $1
}

__async_prompt_draw_rprompt () {
  local rprompt=( $__KUBEPROMPT $__GITPROMPT )
  local new_RPROMPT=${(j. .)rprompt}
  if [[ $RPROMPT != $new_RPROMPT ]]; then
    RPROMPT=$new_RPROMPT
    zle reset-prompt
  fi
  if [[ -n $1 ]]; then
    zle -F $1
    exec {1}<&-
    __async_prompt_fds=(${__async_prompt_fds:#$1})
  fi
}

__async_prompt.git-status () {
  emulate -L zsh

  local -i fd
  local line toks oid head upstream
  local ahead behind stashed staged unstaged untracked unmerged

  exec {fd} < <(git --no-optional-locks status --porcelain=v2 --branch --show-stash --no-renames 2>&1)
  {
    while read -u "$fd" line; do
      toks=("${(@s: :)line}")

      case $toks[1] in
      fatal*) return ;;
      \#) # header lines prefixed w/ '#'
        case $toks[2] in
        branch.oid) oid=$toks[3] ;;
        branch.head) branch=$toks[3] ;;
        branch.upstream) upstream=$toks[3] ;;
        branch.ab)
          ahead=$(($toks[3]))
          behind=$(($toks[4]*-1))
          [[ $ahead  -gt 0 ]] || ahead=
          [[ $behind -gt 0 ]] || behind=
        ;;
        stash) stashed=$toks[3] ;;
        *) ;; # unexpected hashed line
        esac
      ;;
      1|2) # changed files
        [[ $toks[2] =~ [^.]. ]] && staged=$(( $staged + 1 ))
        [[ $toks[2] =~ .[^.] ]] && unstaged=$(( $unstaged + 1 ))
      ;;
      \?) untracked=$(( $untracked + 1 )) ;;
      u) unmerged=$(( $unmerged + 1 )) ;;
      *) ;; # unexpected 1st char
      esac
    done
  } always {
    exec {fd}>&-
  }

  local gstat

  [[ -n $unmerged  ]] && gstat+=%F{red}✖
  [[ -n $staged    ]] && gstat+=%F{blue}●%f
  [[ -n $unstaged  ]] && gstat+=%F{red}●%f
  [[ -n $untracked ]] && gstat+=%F{246}●%f
  [[ -n $ahead     ]] && gstat+=↑$ahead
  [[ -n $behind    ]] && gstat+=↓$behind

  print ${gstat}%F{208}λ%f$branch
}
