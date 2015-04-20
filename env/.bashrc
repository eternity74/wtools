WTOOLS_ROOT=$(cd `dirname "${BASH_SOURCE[0]}"` && git rev-parse --show-toplevel)
source $WTOOLS_ROOT/bin/wfunc.sh
source $WTOOLS_ROOT/env/.git-prompt.sh
export GIT_PS1_SHOWCOLORHINTS=true
export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 "(\[\033[0;32m\]%s\[\033[0m\])")$ '
if [[ -n "$SSH_CONNECTION" ]]; then
  export ADB_SERVER_HOST=$(echo $SSH_CONNECTION | awk '{print $1}')
fi
