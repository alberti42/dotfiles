# https://github.com/junegunn/fzf

# junegunn/fzf - A command-line fuzzy finder
() {
  # Define the base URL for supporting files to keep the `dl` ice clean
  local fzf_base_url="https://raw.githubusercontent.com/junegunn/fzf/master"

  zinit ice from"gh-r" \
    dl"
      ${fzf_base_url}/bin/fzf-tmux;
      ${fzf_base_url}/bin/fzf-preview.sh;
      ${fzf_base_url}/man/man1/fzf.1;
      ${fzf_base_url}/man/man1/fzf-tmux.1;
    " \
    atclone"source '${${(%):-%x}:a:h}/__fzf_atclone_hook.zsh'" \
    atinit"
      # Set custom styles
      __zcompile_if_needed_and_source '${${(%):-%x}:a:h}/__fzf_atinit_hook.zsh'
      # Source completions and key-bindings
      __zcompile_if_needed_and_source init.zsh
    " \
    atpull"%atclone" \
    lbin"fzf -> fzf; fzf-tmux -> fzf-tmux; fzf-preview.sh -> fzf-preview;" \
    null lucid wait
  zinit light junegunn/fzf
}
