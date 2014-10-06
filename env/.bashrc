
source ~/.git-prompt.sh
export GIT_PS1_SHOWCOLORHINTS=true
export PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 "(\[\033[0;32m\]%s\[\033[0m\])")$ '
source wfunc.sh
