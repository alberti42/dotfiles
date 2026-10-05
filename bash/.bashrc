# ~/.bashrc, for systems where the login shell cannot be changed to zsh (chsh).

# Start zsh for interactive shells, unless $SHELL is already zsh: set below before
# `exec`, or by the system where zsh is the login shell. So `bash` typed from zsh
# stays in bash. Non-interactive shells (scp, rsync, `ssh host cmd`) stay in bash.
if [[ $- == *i* && $SHELL != *zsh ]] && command -v zsh >/dev/null; then
  export SHELL=$(command -v zsh)
  exec zsh -l
fi
