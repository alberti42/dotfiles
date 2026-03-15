# https://github.com/zsh-users/zsh-completions

function __my_completions_atinit_hook() {
  
  # ------------------------------------------------------------------------------
  # Zsh Completion System: Understanding the `zstyle` Completion Syntax
  # ------------------------------------------------------------------------------
  # 
  # The `zstyle` command is used to configure various aspects of Zsh completion 
  # behavior. The completion system follows a structured pattern in the form:
  # 
  #     zstyle ':completion:<function>:<completer>:<command>:<argument>:<tag>' <style> <value>
  # 
  # Each field refines the scope of where the completion rule applies:
  # 
  # - `:completion`  → Prefix indicating the setting applies to completions.
  # - `<function>`   → The Zsh completion function being executed. Typically `*` 
  #                    to apply to all functions.
  # - `<completer>`  → Specifies the type of completion behavior being modified 
  #                    (e.g., `_complete`, `_ignored`, `_correct`).
  # - `<command>`    → The specific command for which the rule applies (e.g., `git`, `ls`, `vim`), 
  #                    or `*` to apply to all commands.
  # - `<argument>`   → Restricts the rule to a specific argument or option 
  #                    (e.g., `-o`, `-f`, `--help`). Use `*` to apply to all.
  # - `<tag>`        → Defines what kind of items the completion applies to, 
  #                    such as `files`, `options`, `commands`, `indexes`, etc.
  #
  # ------------------------------------------------------------------------------
  # The `<function>` Field in `zstyle` Completion Patterns
  # ------------------------------------------------------------------------------
  #
  # The `<function>` field in `zstyle` defines which completion function a rule 
  # applies to. A completion function is responsible for generating and managing 
  # completion suggestions in Zsh.
  #
  # Common completion functions include:
  #
  # - `_complete`   → The standard completion function (for files, commands, etc.).
  # - `_ignored`    → Includes ignored files and commands in completions.
  # - `_correct`    → Attempts spelling correction for mistyped commands.
  # - `_expand`     → Expands aliases, globbing, and variables during completion.
  # - `-default-`   → A fallback function, used when no specific rule matches.
  #
  # ------------------------------------------------------------------------------
  # Using `<function>` in `zstyle`
  # ------------------------------------------------------------------------------
  #
  # By specifying the `<function>` field in a `zstyle` rule, we can apply different 
  # behaviors depending on which function is handling completion.
  #
  # Examples:
  #
  # 1️⃣ Apply menu selection to all completion functions:
  #    zstyle ':completion:*' menu select
  #
  # 2️⃣ Modify behavior only for `_complete` (default completion function):
  #    zstyle ':completion:*:_complete:*' tag-order files directories
  #
  # 3️⃣ Apply settings only to `fzf-tab`, leaving standard completion unchanged:
  #    zstyle ':fzf-tab:complete:*' fzf-preview 'tree -C "$realpath"'
  #
  # ------------------------------------------------------------------------------
  # Why This Matters:
  # ------------------------------------------------------------------------------
  #
  # - It allows fine-tuning of completion settings for specific plugins like `fzf-tab`.
  # - It prevents certain settings from affecting default Zsh completion (`_complete`).
  # - It ensures different completion methods (e.g., fuzzy matching vs. standard) 
  #   get customized independently.
  #
  # Understanding the `<function>` field helps create a more controlled, efficient, 
  # and plugin-friendly completion system in Zsh.
  #
  # ------------------------------------------------------------------------------

  # ------------------------------------------------------------------------------
  # Special Fields and Wildcards:
  # ------------------------------------------------------------------------------
  #
  # - `*`           → Wildcard that matches everything in that field.
  # - `-default-`   → Used when no specific rule exists, acting as a fallback.
  # - `-subscript-` → Matches completion inside array subscripts (e.g., `my_array[<TAB>]`).
  # - `-command-`   → Used for command name completion (e.g., `git <TAB>`).
  #
  # ------------------------------------------------------------------------------
  # Practical Use Cases:
  # ------------------------------------------------------------------------------
  #
  # - Modify menu selection behavior for completions.
  # - Control sorting order for completion candidates (e.g., prioritize directories over files).
  # - Enable or disable previews for `fzf-tab` only in relevant contexts.
  # - Define special rules for specific commands, arguments, or tags.
  #
  # By fine-tuning `zstyle` settings, we can create a highly efficient and 
  # context-aware completion experience in Zsh.
  #
  # ------------------------------------------------------------------------------
  # Example: To apply a rule only when completing `git checkout`, we would use:
  #
  #   zstyle ':completion:*:*:git-checkout:*' sort false
  #
  # This disables sorting when listing branches for `git checkout <TAB>`.
  #
  # ------------------------------------------------------------------------------

  # The zsh/complist module provides the menuselect UI, scrolling lists (where list-prompt applies),
  # and the menu-select/reverse-menu-select widgets. It often gets loaded automatically the first
  # time completion needs it (e.g. when you use menu select or certain listing behaviors).
  zmodload -i zsh/complist

  # Controls whether the _expand completer will first try to expand all substitutions in the string (such as ‘$(...)’ and ‘${...}’). 
  zstyle ':completion:*' substitute false

  # Use caching for any completion that support _store_cache, _retrieve_cache, and _cache_invalid functions
  : ${ZSH_CACHE_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh}  # := form (it only assigns if the parameter is unset or null)
  zstyle ':completion:*' use-cache yes
  zstyle ':completion:*' cache-path $ZSH_CACHE_DIR

  # Tells zsh’s completion system to include the "special" directory entries . and .. when completing directory names
  zstyle ':completion:*' special-dirs true

  unsetopt MENU_COMPLETE   # if unset, do not autoselect the first completion entry; if set, the first completion is inserted immediately, and each additional press of Tab cycles to the next match.
  unsetopt FLOW_CONTROL    # disable output flow control via start/stop characters (usually assigned to ^S/^Q)
  setopt AUTO_MENU         # shows completion menu on successive tab press
  setopt COMPLETE_IN_WORD  # allows completing in the middle of a word/path; the cursor stays there and completion is done from both ends
  setopt ALWAYS_TO_END     # if a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word
  setopt CASE_GLOB         # if set, make globbing (filename generation) sensitive to case; unset makes globbing insensitive to case 
  WORDCHARS=''             # Characters to be considered part of a word; by default: *?_-.[]~=/&;!#$%^(){}<>
  
  # Choose menu select UI - it is superseded by fzf-tab
  zstyle ':completion:*:*:*:*:*' menu select
  
  # Shows how many matches in menu select (list prompt UI)
  # In this mode, list gets printed; we page through screenfuls
  zstyle ':completion:*:default' list-prompt '%S%M matches%s'
  
  # select-prompt is shown during menu selection (the menu select UI).
  zstyle ':completion:*' select-prompt "%SScrolling active: current selection at %p%s"
  
  # Tells compsys to group matches into separate groups like “files”, “directories”, “users”, “options”, “commands”, etc.
  zstyle ':completion:*:*' group yes
  
  # Configure how the groups/tags are displayed
  zstyle ':completion:*:descriptions' format '%B%U%F{252}[%d]%f%u%b'

  # Tells compsys to add a description for option matches (where available). Example: for --help it might show “display help”.
  zstyle ':completion:*:options' description yes

  # It automatically invents a description for command-line options that don’t already have one, but only if:
  # - the option takes exactly one argument, and
  # - the completion function knows what that argument is
  # For example, if %d is `file`, it displays `--output   takes file`
  zstyle ':completion:*:options' auto-description 'takes %d'

  # Avoid sorting for the group/tag that contains command-line options (e.g. --help, -v, etc.)
  zstyle ':completion:*:options' sort false

  # Use the tag name as the group name. Practical effect:
  # commands, functions, aliases, builtins, reserved-words, etc → separate sections
  # prevents tags from being lumped into -default- or merged into one group
  zstyle ':completion:*' group-name ''
  
  # Many completion functions can generate matches in a simple and a verbose form
  zstyle ':completion:*' verbose yes

  # Case insensitive path-completion
  zstyle ":completion:*" matcher-list "" "m:{a-zA-Z}={A-Za-z}" "r:|[._-]=* r:|=*" "l:|=* r:|=*"

  # Don't complete unavailable functions (e.g.: when typing `unfunction <tab>`)
  zstyle ':completion:*:functions' ignored-patterns '(_*|→*|+*|-*|@*|.*|:*|pre(cmd|exec))'

  # This sets the completer chain: when pressing Tab, zsh will try these completers in order:
  # _complete _match _approximate
  zstyle ':completion:*' completer _complete _match _approximate

  # This affects the _match completer. `original` only means: when _match runs, only complete
  # against the original word you typed, rather than generating alternate transformed variants
  # and offering them as separate "correction" candidates.
  zstyle ':completion:*:match:*' original only

  # Increase max-errors based on length.
  zstyle -e ':completion:*:approximate:*' max-errors '(( ${#PREFIX} + ${#SUFFIX} < 6 )) && reply=(1 numeric) || reply=(2 numeric)'

  # Disable approximate/correct in subscripts
  zstyle ':completion:*:approximate:-subscript-:*' max-errors 0
  zstyle ':completion:*:correct:-subscript-:*' max-errors 0
  
  # Prioritize numeric indexes when completing array subscripts (e.g., my_array[<TAB>]).
  # If the array is associative, complete keys only if no numeric indexes apply.
  zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

  # Directories
  zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
  zstyle ':completion:*:*:cd:*:directory-stack' menu select
  zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
  zstyle ':completion:*' squeeze-slashes true

  # History
  zstyle ':completion:*:history-words' stop yes
  zstyle ':completion:*:history-words' remove-all-dups yes
  zstyle ':completion:*:history-words' list false
  zstyle ':completion:*:history-words' menu select

  # Environment Variables
  zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

  # Populate hostname completion. But allow ignoring custom entries from static
  # */etc/hosts* which might be uninteresting.
  zstyle -e ':completion:*:hosts' hosts 'reply=(
    ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
    ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2> /dev/null))"}%%(\#${_etc_host_ignores:+|${(j:|:)~_etc_host_ignores}})*}
    ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
  )'

  # Don't complete uninteresting users...
  zstyle ':completion:*:*:*:users' ignored-patterns \
         adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
         dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
         hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
         mailman mailnull mldonkey mysql nagios \
         named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
         operator pcap postfix postgres privoxy pulse pvm quagga radvd \
         rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

  # Ignore multiple entries.
  zstyle ':completion:*:*:(rm|kill|diff):*:*' ignore-line other
  zstyle ':completion:*:*:rm:*:*' file-patterns '*:all-files'
  
  # Kill
  zstyle ':completion:*:*:*:*:processes' command "
    if [[ $OSTYPE = darwin* ]]; then
      ps -U "$USER" -o pid,user,comm
    else
      ps -u $USER -o pid,user,comm -w -w
    fi
  "  

  # Nice menu behavior like kill
  zstyle ':completion:*:*:kill:*' menu select
  zstyle ':completion:*:*:kill:*' force-list always
  zstyle ':completion:*:*:kill:*' insert-ids single

  # Colorize process names
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
  
  # Killall (completes process *names*, not PIDs)
  
  # Provide candidate process names for killall completion.
  # - macOS: `ps -axo comm` works well.
  # - Linux: `ps -u $USER -o comm` is fine; we uniq/sort to avoid duplicates.
  zstyle ':completion:*:*:killall:*:processes-names' command '
    if [[ $OSTYPE = darwin* ]]; then
      ps -axo comm= 2>/dev/null
    else
      if [[ $EUID = 0 || ${_comp_priv_prefix[1]-} = sudo ]]; then
        ps -eo comm= 2>/dev/null
      else
        ps -u "$USER" -o comm= 2>/dev/null
      fi
    fi |
      sed -E "s/[[:space:]]*<defunct>$//" |
      sed "s|.*/||" |
      LC_ALL=C sort -u
  '

  # Nice menu behavior like kill
  zstyle ':completion:*:*:killall:*' menu select
  zstyle ':completion:*:*:killall:*' force-list always

  # Colorize process names (simple “word” coloring)
  zstyle ':completion:*:*:killall:*:processes-names' list-colors '=(#b)([^ ]##)=01;36'

  # Enable completion on manual page
  zstyle ':completion:*:manuals'    separate-sections true
  zstyle ':completion:*:manuals.*'  insert-sections   true
  # zstyle ':completion:*:manuals.(^1*)' insert-sections true
  # zstyle ':completion:*:man:*'      menu select

  # SSH/SCP/RSYNC
  zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
  zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
  zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
  zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
  zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
  zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

  # partial completion suggestions
  zstyle ':completion:*' list-suffixes
  zstyle ':completion:*' expand prefix suffix
}

zinit ice wait'0b' depth=1 light-mode lucid blockf \
  atinit'_safe_one_off_load __my_completions_atinit_hook' \
  atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

## vim: set expandtab tabstop=2 shiftwidth=2 softtabstop=2 :