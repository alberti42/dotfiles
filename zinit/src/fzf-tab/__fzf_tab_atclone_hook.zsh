# Andrea Alberti, 2024

function __fzf_tab_atclone_hook() {
  [[ -n ${commands[gsed]} ]] && local PREFIX=${${(M)OSTYPE##darwin}:+g}
  
  : >! ./lib/zsh-ls-colors/ls-colors.zsh &&
  {
    for f in ./lib/*(.N); do
      IFS= read -r firstline < "$f" || continue
      [[ $firstline == '#!/hint/zsh' ]] && zcompile -Uz -- "$f"
    done
  } &&
  source fzf-tab.zsh &&
  {
    local log=${TMPDIR:-./}/build-fzf-tab-module.$$.log
    : >! "$log"   # reset log file

    # the script fzf-tab.zsh creates global fzf-tab.zsh without using "typeset -g"
    # we prevent the warning by temporarily disabling NO_WARN_CREATE_GLOBAL
    setopt NO_WARN_CREATE_GLOBAL
    build-fzf-tab-module >"$log" 2>&1
    local rc=$?
    setopt WARN_CREATE_GLOBAL

    if (( rc != 0 )); then
      +zi-log "{u-warn}zinit{b-warn}:{failure} build-fzf-tab-module failed {u-warn}(rc=$rc){rst}{failure}. Read log file below:{rst}"
      +zi-log "{faint}------------------------------------------------------------{rst}"
      cat -- "$log" >&2
      +zi-log "{faint}------------------------------------------------------------{rst}"
      return $rc
    fi
  } &&
  rm -rf "$FZF_TAB_HOME/modules/zsh" && # we remove oh-my-zsh repository; otherwise all ~1000 completions are installed
  : && # we unset the global variable
  unset FZF_TAB_HOME
}
_safe_one_off_load __fzf_tab_atclone_hook
