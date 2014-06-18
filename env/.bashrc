export WTOOLS_ROOT=$(cd `dirname "${BASH_SOURCE[0]}"` && git rev-parse --show-toplevel)
export WTOOLS_CACHE="$WTOOLS_ROOT/.cache"
source $WTOOLS_ROOT/env/.git-prompt.sh
export GIT_PS1_SHOWCOLORHINTS=true
export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 "(\[\033[0;32m\]%s\[\033[0m\])")$ '
if [[ -n "$SSH_CONNECTION" ]]; then
  export ADB_SERVER_HOST=$(echo $SSH_CONNECTION | awk '{print $1}')
fi

function print_working_project
{
  if [[ -n $TARGET_PRODUCT ]]; then
    echo $TARGET_PRODUCT
  else
    echo $PWD | (grep -o -E "$(readlink -f ~)/src/[^ /]+" || basename ${PWD}) | xargs basename
  fi
}

if [[ -n "$STY" ]]; then
  echo "You're on screen!!"
  PROMPT_COMMAND='echo -ne "\033k\033\0134\033k[`print_working_project`]\033\0134"'
  # Prevent PROMPT_COMMAND from being overwritten by android's choosecombo
  STAY_OFF_MY_LAWN=1
fi
if [[ -n "$TMUX" ]]; then
  export TMUX_UNIQUE=`tmux display-message -p "#S#{window_id}#D"`
fi
alias adb='~/wtools/bin/adb'
alias tmux='tmux -2'
