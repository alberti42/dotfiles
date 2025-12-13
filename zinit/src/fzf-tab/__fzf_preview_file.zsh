function __fzf_preview_file() {
  local realpath=$1

  if [[ -d "$realpath" ]]; then
    tree -C -L 3 -- "$realpath"
  elif [[ -f "$realpath" ]]; then
    if grep -qI . "$realpath"; then
      bat -p --color=always -- "$realpath"
    else
      echo "Realpath: $realpath"
      local gprefix=""
      local -a stat_opts

      if [[ $OSTYPE = darwin* ]]; then
        command -v gstat &>/dev/null && gprefix=g
        if [[ -z $gprefix ]]; then
          stat_opts=(-f $'File: %N\nLocation: %d:%i\nMode: %Sp (%Mp%Lp)\nLinks: %l\nOwner: %Su/%Sg\nSize: %z (%b blocks)\nChanged: %Sc\nModified: %Sm\nAccessed: %Sa')
        fi
      fi

      if [[ -z ${stat_opts+x} || ${#stat_opts[@]} -eq 0 ]]; then
        stat_opts=(-c $'File: %N\nType: %F\nLocation: %d:%i\nMode: %A (%a)\nLinks: %h\nOwner: %U/%G\nSize: %s (%b blocks)\nChanged: %z\nModified: %y\nAccessed: %x')
      fi

      local stat_cmd="${gprefix}stat"
      "$stat_cmd" "${stat_opts[@]}" -- "$realpath"
    fi
  fi
}
