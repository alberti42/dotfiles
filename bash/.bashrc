# ~/.bashrc, for systems where the login shell cannot be changed to zsh (chsh).

# Start zsh for interactive top-level shells. Non-interactive shells (scp, rsync,
# `ssh host cmd`) and `bash` typed from another shell (SHLVL > 1) stay in bash.
if [[ $- == *i* && -z ${ZSH_VERSION-} && ${SHLVL:-1} -le 1 ]] && command -v zsh >/dev/null; then
  export SHELL=$(command -v zsh)
  exec zsh -l
fi
