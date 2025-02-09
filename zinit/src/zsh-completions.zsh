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

  # Substitute environment variables
  zstyle ':completion:*' substitute true
  
  # Configures which completion functions are used in Zsh and in what order when pressing <Tab>
  zstyle ":completion:*" completer _expand _complete _ignored _approximate

  # Check if LS_COLORS is defined
  if (( ${+LS_COLORS} )); then
    zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"
    zstyle ":completion:*:default" list-colors ${(s.:.)LS_COLORS} "ma=38;2;255;255;255;1;48;2;210;0;255" # ma->"matched item"
  else 
    [[ ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) && $quiet != -q ]] && \
      +zi-log "{u-warn}Warning{b-warn}: zsh-completions cannot use LS_COLORS."
  fi
  zstyle ":completion:*" menu yes select # highlight case in interactive menu
  zstyle ":completion:*" matcher-list "" "m:{a-zA-Z}={A-Za-z}" "r:|[._-]=* r:|=*" "l:|=* r:|=*"
  zstyle ":completion:*" select-prompt "%SScrolling active: current selection at %p%s"
  zstyle ":completion:*:descriptions" format "--- %d ---"
  zstyle ":completion:*:processes" command "ps -au$USER"
  zstyle ":completion:complete:*:options" sort false
  zstyle ":completion:*:*:*:*:processes" command "ps -u $USER -o pid,user,comm,cmd -w -w"

  # Apply ls colors
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  zstyle ':completion:*:default' list-prompt '%S%M matches%s'

  # pretty cd [tab] stuffs
  zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95=38;5;12'

  # Use caching to make completion for commands such as dpkg and apt usable.
  zstyle ':completion:complete:*' use-cache on
  zstyle ':completion:complete:*' cache-path "$HOME/.zcompcache"

  # case insensitive path-completion
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  unsetopt CASE_GLOB

  # Group matches and describe.
  # zstyle ':completion:*:*:*:*:*' menu select
  # zstyle ':completion:*:matches' group 'yes'
  # zstyle ':completion:*:options' description 'yes'
  # zstyle ':completion:*:options' auto-description '%d'
  # zstyle ':completion:*' group-name ''
  # zstyle ':completion:*' verbose yes

  # Fuzzy match mistyped completions.
  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*:match:*' original only
  zstyle ':completion:*:approximate:*' max-errors 1 numeric

  # Increase the number of errors based on the length of the typed word. But make
  # sure to cap (at 7) the max-errors to avoid hanging.
  zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

  # Don't complete unavailable commands.
  zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

  # Prioritize numeric indexes when completing array subscripts (e.g., my_array[<TAB>]).
  # If the array is associative, complete keys only if no numeric indexes apply.
  zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

  # Directories
  zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
  zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
  zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
  zstyle ':completion:*' squeeze-slashes true

  # History
  zstyle ':completion:*:history-words' stop yes
  zstyle ':completion:*:history-words' remove-all-dups yes
  zstyle ':completion:*:history-words' list false
  zstyle ':completion:*:history-words' menu yes

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
  zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
  zstyle ':completion:*:*:kill:*' menu yes select
  zstyle ':completion:*:*:kill:*' force-list always
  zstyle ':completion:*:*:kill:*' insert-ids single

  # Enable completion on manual page
  zstyle ':completion:*:manuals'    separate-sections true
  zstyle ':completion:*:manuals.*'  insert-sections   true
  # zstyle ':completion:*:manuals.(^1*)' insert-sections true
  zstyle ':completion:*:man:*'      menu yes select

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

zinit ice wait depth=1 light-mode lucid blockf \
  atinit'_safe_one_off_load __my_completions_atinit_hook' \
  atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions
