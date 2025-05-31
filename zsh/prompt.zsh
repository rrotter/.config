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
autoload -Uz add-zsh-hook

add-zsh-hook precmd __async_prompt
add-zsh-hook chpwd __clear_rprompt
add-zsh-hook preexec __async_reap
add-zsh-hook preexec __terminal_integration_preexec
add-zsh-hook precmd __terminal_integration_precmd

__async_prompt () {
  exec {__git_prompt_fd} < <(__async_prompt.git-status)
  zle -F $__git_prompt_fd __set_git_rprompt
}

__async_reap () {
  # Minimal cleanup. For the full belt-and-suspenders solution, see:
  # https://github.com/zsh-users/zsh-autosuggestions/blob/master/src/async.zsh
  if [[ -n $__git_prompt_fd ]]; then
    zle -F $__git_prompt_fd
    exec {__git_prompt_fd}<&-
  fi
}

__clear_rprompt () {
  RPROMPT=
}

# TODO: Add responsive kubectl prompt segment
# add this when we add additional prompt segments
# __clear_tainted_rprompt () {
#   [[ -n __rprompt_tainted ]] && RPROMPT=
# }

__set_git_rprompt () {
  RPROMPT="$(<&$1)"
  zle reset-prompt
  zle -F $1
  exec {1}<&-
  unset __git_prompt_fd
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
