# Safely run initialization helper functions exactly once, with guaranteed cleanup
# and controlled error handling/logging. It is especially relevant when functions
# defined during setup shouldn’t persist in the runtime environment.
function _safe_one_off_load() {
  emulate -LR zsh

  local func=$1
  shift  # Remove the function name from the arguments
  local retval

  # Save the original state of ERR_EXIT
  local original_err_exit=${options[ERR_EXIT]}

  set -e  # Enable ERR_EXIT for this function
  "$func" "$@"  # Call the function with remaining arguments
  retval=$?

  # Restore the original state of ERR_EXIT
  if [[ $original_err_exit == off ]]; then
    set +e
  fi

  unfunction "$func"

  if [[ $retval -ne 0 ]]; then
    +zi-log "{error}Function '$func' exited with error code: $retval{rst}"
  fi
  return $retval
}
