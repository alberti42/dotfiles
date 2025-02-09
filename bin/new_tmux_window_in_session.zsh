function main() {

  local new_window_id window_name session_name curr_dir

  # Parse arguments
  while [[ $# -gt 0 ]]; do
      case $1 in
          -s|--session)
              session_name="$2"
              shift 2
              ;;
          -n|--session)
              window_name="$2"
              shift 2
              ;;
          -c|--directory)
              curr_dir="$2"
              shift 2
              ;;
          *)
              echo "Unknown option: $1" 1>&2
              return 1
              ;;
      esac
  done

  # Validate input parameters
  if [[ -z $session_name ]]; then
      echo "Error: Session name is required. Use -s or --session to specify it." 1>&2
      return 1
  fi

  if [[ -z $curr_dir ]]; then
      echo "Error: Directory is required. Use -c or --directory to specify it." 1>&2
      return 1
  fi

  # Check if a tmux session named '$session_name' is running
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
      # Create the '$session_name' session without attaching to it
      if [[ -z $window_name ]]; then
        tmux new-session -d -s "$session_name" -F "#{window_id}" -c "$curr_dir"
      else
        tmux new-session -d -s "$session_name" -F "#{window_id}" -c "$curr_dir" -n "$window_name"
      fi
      # Retrieve the window ID of the first window in the '$session_name' session
      new_window_id=$(tmux list-windows -t "$session_name" -F "#{window_id}" | head -n 1)
      # Automatically attach to the new session
      tmux switch-client -t "$session_name"
  else
      # Create a new window in the '$session_name' session and store its ID
      if [[ -z $window_name ]]; then
        new_window_id=$(tmux new-window -P -t "$session_name" -F "#{window_id}" -c "$curr_dir")
      else
        new_window_id=$(tmux new-window -P -t "$session_name" -F "#{window_id}" -c "$curr_dir" -n "$window_name")
      fi
  fi
  
  # Check if the window creation was successful and display the window ID
  if [[ -n $new_window_id ]]; then
      # Activate the new window globally for all tmux clients
      tmux select-window -t "$new_window_id"
      # Ensure the session is activated
      tmux switch-client -t "$session_name"
      return 0
  else
      echo "Failed to create a new tmux window in '$session_name' session." 1>&2
      return 1
  fi
}

# Execute the main function with all script arguments
main "$@"
