#!/bin/bash

# aihelp - Terminal AI Chat Assistant

# --- Configuration ---
CONFIG_DIR="$HOME/.config/aihelp"
ENV_FILE="$CONFIG_DIR/.env"
HISTORY_DIR="$CONFIG_DIR/history"
CONFIG_FILE="$CONFIG_DIR/config"

# --- Dependency Checks ---
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    echo "Error: Required command '$1' not found. Please install it." >&2
    exit 1
  fi
}

check_clipboard_tool() {
  # Try wl-copy first: check if command exists AND if it runs without error (e.g., connects to Wayland)
  if command -v wl-copy &>/dev/null && printf '' | wl-copy &>/dev/null; then
    CLIPBOARD_TOOL="wl-copy"
    echo "Using clipboard tool: wl-copy" # Optional: for debugging
  # If wl-copy fails or isn't present, try xclip
  elif command -v xclip &>/dev/null; then
    CLIPBOARD_TOOL="xclip -selection clipboard"
    echo "Using clipboard tool: xclip" # Optional: for debugging
  else
    # Error: Neither working wl-copy nor xclip found
    echo "Error: No functional clipboard tool found (need working 'wl-copy' for Wayland or 'xclip' for X11)." >&2
    exit 1
  fi
  # The debug echo is now inside the if/elif blocks
}

check_dependency "curl"
check_dependency "jq"
check_dependency "fzf"
check_dependency "bat"
check_clipboard_tool # Sets $CLIPBOARD_TOOL

# --- Initial Setup ---
setup_config() {
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$HISTORY_DIR"

  if [ ! -f "$ENV_FILE" ]; then
    echo "Creating initial config file: $ENV_FILE"
    echo "# Add your API keys here" >"$ENV_FILE"
    echo "GEMINI_API_KEY=" >>"$ENV_FILE"
    echo "OPENROUTER_API_KEY=" >>"$ENV_FILE"
    chmod 600 "$ENV_FILE" # Secure the file
    echo "Please edit $ENV_FILE and add your API keys."
    # Optionally exit here or prompt user
  fi

  # Load environment variables
  set -a # Automatically export all variables
  # Check if ENV_FILE exists before sourcing
  if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
  else
    echo "Warning: Environment file $ENV_FILE not found." >&2
  fi
  set +a

  # Check if keys are set (basic check)
  if [ -z "$GEMINI_API_KEY" ] && [ -z "$OPENROUTER_API_KEY" ]; then
    echo "Warning: No API keys found in $ENV_FILE. Please add at least one." >&2
    # Decide if we should exit or continue (maybe allow local-only mode later?)
  fi

  # Load or create config file
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default settings file: $CONFIG_FILE"
    echo "API_PROVIDER=" >"$CONFIG_FILE" # Will be 'gemini' or 'openrouter'
    echo "MODEL=" >>"$CONFIG_FILE"
  fi

  # Load config settings
  # Check if CONFIG_FILE exists before sourcing
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    echo "Warning: Config file $CONFIG_FILE not found." >&2
  fi

  # NOTE: Configuration completeness check moved to main()
}

# --- Configuration Function ---
fetch_openrouter_models() {
  local models_json
  echo "Fetching models from OpenRouter..." >&2
  models_json=$(curl -s https://openrouter.ai/api/v1/models)
  if [ $? -ne 0 ] || [ -z "$models_json" ]; then
    echo "Error: Failed to fetch models from OpenRouter." >&2
    return 1
  fi
  # Extract model IDs, filter out duplicates, sort
  echo "$models_json" | jq -r '.data[].id' | sort -u
}

configure_settings() {
  echo "--- AI Help Configuration ---"

  # 1. Select API Provider
  local providers="Gemini\nOpenRouter"
  API_PROVIDER=$(echo -e "$providers" | fzf --prompt="Select API Provider: " --height=4 --layout=reverse) # Use fixed height

  if [ -z "$API_PROVIDER" ]; then
    echo "Configuration cancelled."
    exit 1
  fi

  # 2. Select Model
  local model_list
  case "$API_PROVIDER" in
  "Gemini")
    # Check for Gemini Key
    if [ -z "$GEMINI_API_KEY" ]; then
      echo "Error: GEMINI_API_KEY not set in $ENV_FILE." >&2
      exit 1
    fi
    # Updated hardcoded list for Gemini
    model_list="gemini-2.5-pro-exp-03-25\ngemini-2.0-flash\ngemini-2.0-pro-exp-02-05\ngemini-2.0-flash-lite\ngemini-2.0-flash-thinking-exp-01-21\ngemini-1.5-flash\ngemini-1.5-pro\ngemini-1.0-pro-vision\ngemini-1.0-pro\ngemma-3-27b-it\ngemini-2.0-flash-thinking-exp-1219"
    ;;
  "OpenRouter")
    # Check for OpenRouter Key
    if [ -z "$OPENROUTER_API_KEY" ]; then
      echo "Error: OPENROUTER_API_KEY not set in $ENV_FILE." >&2
      exit 1
    fi
    # Updated hardcoded list for OpenRouter
    model_list="meta-llama/llama-4-maverick:free\nmeta-llama/llama-4-scout:free\ndeepseek/deepseek-chat-v3-0324:free\nmeta-llama/llama-3.2-1b-instruct:free\nqwen/qwen2.5-vl-32b-instruct:free\nopen-r1/olympiccoder-32b:free\nqwen/qwq-32b:free\ndeepseek/deepseek-chat-v3-0324:free\ngoogle/gemini-2.0-pro-exp-02-05:free\ndeepseek/deepseek-v3:free\ndeepseek/deepseek-r1:free\ndeepseek/deepseek-r1-distill-llama-70b\ndeepseek/deepseek-r1-distill-qwen-32b\ndeepseek/deepseek-r1-distill-qwen-14b\ndeepseek/deepseek-r1-distill-llama-8b\ndeepseek/deepseek-r1-distill-qwen-1.5b\ndeepseek/deepseek-r1-zero:free\nmistralai/mixtral-8x7b-instruct\nmeta-llama/llama-3-8b-instruct"
    # Note: Removed dynamic fetching via fetch_openrouter_models
    ;;
  *)
    echo "Invalid provider selected."
    exit 1
    ;;
  esac

  MODEL=$(echo -e "$model_list" | fzf --prompt="Select Model for $API_PROVIDER: " --height=15 --layout=reverse) # Use fixed height

  if [ -z "$MODEL" ]; then
    echo "Configuration cancelled."
    exit 1
  fi

  # 3. Save Configuration
  echo "Saving configuration..."
  echo "API_PROVIDER=\"$API_PROVIDER\"" >"$CONFIG_FILE"
  echo "MODEL=\"$MODEL\"" >>"$CONFIG_FILE"

  echo "Configuration saved to $CONFIG_FILE:"
  echo "  Provider: $API_PROVIDER"
  echo "  Model: $MODEL"
  echo "Setup complete. You can now run '$0'." # Use $0 for the current script name
}

# --- System Prompt ---
# Instructs the AI on formatting and behavior
SYSTEM_PROMPT="""DONOT START REPLYING WITHOUT READING THIS WHOLE SYSTEM_PROMPT . You are a helpful AI assistant. Provide concise and clear answers. Use standard Markdown for formatting (lists, bold, italics, etc.).
also give out code / game code / user said markdown block / a scrpt / a code block / html / any programing code / commands / shell commands or any thing that user might need to copy and paste some where else in a code block in a way that is intact to copy and paste in a file or shell  so that it can be used  this is a must and shouldnt be niglagted.
it contains ollama commands , docker commands , python or any other programing code , bash zsh fish etc shell script and commands , minecraft etc game commands , git commands , anything that can be pasted in shell and count as valid commands
"""

# --- History Management ---
CHAT_HISTORY=() # In-memory array of JSON objects for the current session
CURRENT_HISTORY_FILE=""

# Function to create the API-specific JSON object string for a message
# Usage: create_api_message_json "role" "content"
# Returns a compact JSON string suitable for the configured API provider
create_api_message_json() {
  local role="$1"
  local content="$2"
  # Content is passed directly, assuming it doesn't need pre-escaping for jq --arg
  # json_content=$(echo "$content" | jq -Rsa .) # REMOVED

  if [[ "$API_PROVIDER" == "Gemini" ]]; then
    # Gemini uses "user" and "model" roles, and a "parts" array
    local gemini_role="$role"
    # Map OpenRouter's 'assistant' role if needed (though we primarily use 'model' for Gemini AI responses)
    if [[ "$role" == "assistant" ]]; then
      gemini_role="model"
    fi
    # Simple text part for now - Pass content directly to --arg text_content
    # jq needs the value for "text" to be a valid JSON string. Let jq handle the encoding.
    jq -n --arg role "$gemini_role" --arg text_content "$content" \
      '{role: $role, parts: [{"text": $text_content}]}' | jq -c .
  else # OpenRouter uses "user" and "assistant"
    local openrouter_role="$role"
    # Map Gemini's 'model' role if needed (though we primarily use 'assistant' for OpenRouter AI responses)
    if [[ "$role" == "model" ]]; then
      openrouter_role="assistant"
    fi
    # Pass content directly to --arg content
    jq -n --arg role "$openrouter_role" --arg content "$content" \
      '{role: $role, content: $content}' | jq -c .
  fi
}

# Function to load history from a file into the CHAT_HISTORY array
# Usage: load_history "path/to/history.json"
load_history() {
  local file_path="$1"
  if [ ! -f "$file_path" ]; then
    echo "History file not found: $file_path" >&2
    return 1
  fi
  # Read the JSON array from the file. Each element is an object string.
  # Store each object string as an element in the CHAT_HISTORY bash array.
  mapfile -t CHAT_HISTORY < <(jq -c '.[]' "$file_path")
  if [ $? -ne 0 ]; then
      echo "Error: Failed to parse history file: $file_path" >&2
      CHAT_HISTORY=() # Clear history on parse error
      return 1
  fi
  CURRENT_HISTORY_FILE="$file_path"
  echo "Loaded history from: $CURRENT_HISTORY_FILE"
}

# Function to display the current CHAT_HISTORY
display_history() {
  echo "--- Chat History ---"
  # Iterate through the CHAT_HISTORY array (each element is a JSON string object)
  for history_item_json in "${CHAT_HISTORY[@]}"; do
    # Parse the outer object to get message_json and model_used
    local message_json model_used role content display_model_name
    message_json=$(echo "$history_item_json" | jq -r '.message_json // empty')
    model_used=$(echo "$history_item_json" | jq -r '.model_used // empty') # Will be empty for user messages

    if [ -z "$message_json" ]; then
        echo "Warning: Skipping invalid history item." >&2
        continue
    fi

    # Parse the inner message_json to get role and content
    role=$(echo "$message_json" | jq -r '.role')
    # Extract the raw content string
    content_raw=$(echo "$message_json" | jq -r 'if .parts then .parts[0].text else .content end')

    # Attempt to remove potential surrounding quotes added during storage/retrieval
    content_trimmed="${content_raw#\"}" # Remove leading quote if present
    content_trimmed="${content_trimmed%\"}" # Remove trailing quote if present

    if [[ "$role" == "user" ]]; then
      # Use printf %b on the potentially trimmed content to interpret escapes
      echo -e "\n\e[34mYou:\e[0m" # Print prompt first
      printf '%b' "$content_trimmed" # Print content, interpreting escapes
      echo # Add a newline after user content
    elif [[ "$role" == "model" || "$role" == "assistant" ]]; then
      # Use the specific model_used if available, otherwise fall back to the current $MODEL
      display_model_name="${model_used:-$MODEL}"
      echo -e "\n\e[32mAI ($display_model_name):\e[0m" # Green for AI, showing specific model
      # Use printf '%b' on the potentially trimmed content before piping to bat
      printf '%b' "$content_trimmed" | bat --language md --paging=never --style=plain --color=always
    # Handle potential 'system' role if it ever gets stored/displayed (currently shouldn't)
    # elif [[ "$role" == "system" ]]; then
    #   echo -e "\n\e[35mSystem:\e[0m $content" # Magenta for system
    fi
  done
  echo "--------------------"
}

# Function to select and load a history file using fzf
# Returns 0 on success, 1 on failure/cancel
select_and_load_history() {
  # List ALL .json files, sorted by time (most recent first)
  local history_files
  history_files=$(ls -t "$HISTORY_DIR"/*.json 2>/dev/null)
  if [ -z "$history_files" ]; then
    echo "No history files found."
    return 1 # Indicate failure
  fi

  # Use basename to show only filenames in fzf, then reconstruct full path
  local chosen_filename
  chosen_filename=$(echo "$history_files" | xargs -n 1 basename | fzf --prompt="Select chat history to load: " --height=10 --layout=reverse)

  if [ -n "$chosen_filename" ]; then
    # Reconstruct the full path
    local chosen_file_path="$HISTORY_DIR/$chosen_filename"
    load_history "$chosen_file_path" # load_history already prints messages
    display_history
    return 0 # Indicate success
  else
    echo "History loading cancelled."
    return 1 # Indicate failure/cancel
  fi
}

# Function to save the current CHAT_HISTORY array to CURRENT_HISTORY_FILE
save_history() {
  if [ -z "$CURRENT_HISTORY_FILE" ]; then
    echo "Error: No history file set for saving." >&2
    return 1
  fi
  # Convert the bash array of JSON strings into a single JSON array string and save
  if printf "%s\n" "${CHAT_HISTORY[@]}" | jq -s '.' >"$CURRENT_HISTORY_FILE"; then
    # Optional: echo "History saved successfully to: $CURRENT_HISTORY_FILE" >&2
    : # No-op, command succeeded
  else
    echo "Error: Failed to save history to $CURRENT_HISTORY_FILE" >&2
    # Decide if we should return an error code? For now, just print error.
    return 1 # Indicate save failure
  fi
}

# Function to create the actual new session file
# Takes an optional session name as argument
create_new_session_file() {
  local session_name="$1" # Optional name passed from start_new_session
  local filename timestamp sanitized_name

  CHAT_HISTORY=() # Clear in-memory history for the new session

  timestamp=$(date +"%Y%m%d_%H%M%S")

  if [ -z "$session_name" ]; then
    filename="chat_${timestamp}.json"
    echo "Starting new timestamped chat session..."
  else
    # Sanitize the name: replace spaces with underscores, remove non-alphanumeric/-/_ characters
    sanitized_name=$(echo "$session_name" | sed -e 's/ /_/g' -e 's/[^a-zA-Z0-9_-]//g')
    if [ -z "$sanitized_name" ]; then # Handle case where sanitization removes everything
      filename="chat_${timestamp}.json"
      echo "Invalid name provided, using timestamp..."
    else
      # Append timestamp to user-provided name to avoid collisions easily
      filename="${sanitized_name}_${timestamp}.json"
      echo "Starting new named chat session..."
    fi
  fi

  CURRENT_HISTORY_FILE="$HISTORY_DIR/$filename"
  echo "[]" >"$CURRENT_HISTORY_FILE" # Create empty JSON array file
  echo "Session file: $CURRENT_HISTORY_FILE"
}

# Function to handle the initial session prompt (new, load history, or exit)
# Returns 0 if a session was started (new or loaded), 1 if history loading failed/cancelled
start_new_session() {
  local user_choice

  # Prompt for session name or command
  read -e -p "Enter name for new chat session (or /history, /exit): " user_choice

  case "$user_choice" in
  "/exit")
    echo "Exiting AI Help."
    exit 0
    ;;
  "/history")
    select_and_load_history # This function handles messages and returns status
    return $?               # Return status (0 for success, 1 for fail/cancel)
    ;;
  *)
    # Treat anything else (name or blank) as a request for a new session
    create_new_session_file "$user_choice"
    return 0 # Indicate success (new session created)
    ;;
  esac
}

# --- API Call Implementation ---
# Takes user input, sends history + input to API, returns AI response text
call_api() {
  local user_input="$1"
  local api_url api_key payload response response_text error_message

  # 1. Prepare payload (extract only the 'message_json' parts from CHAT_HISTORY)
  local extracted_messages=()
  for history_item_json in "${CHAT_HISTORY[@]}"; do
      # Extract the raw message_json string from the wrapper object string
      local msg_json=$(echo "$history_item_json" | jq -r '.message_json // empty')
      if [ -n "$msg_json" ]; then
          extracted_messages+=("$msg_json")
      fi
  done
  # Combine the extracted message JSON strings into a single JSON array string for the API
  local history_json_array=$(printf "%s\n" "${extracted_messages[@]}" | jq -s '.')

  # 2. Set API specifics based on provider
  if [[ "$API_PROVIDER" == "Gemini" ]]; then
    api_key="$GEMINI_API_KEY"
    # Note: Gemini API URL structure might vary slightly based on region or specific model version. Adjust if needed.
    # Using v1beta for generative models as it's common.
    api_url="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${api_key}"

    # Gemini payload structure: { "contents": [history array], "systemInstruction": { "parts": [{"text": "..."}] } }
    # Construct the payload JSON using jq for proper escaping
    payload=$(jq -n --argjson history "$history_json_array" --arg system_prompt "$SYSTEM_PROMPT" \
      '{contents: $history, systemInstruction: {parts: [{"text": $system_prompt}]}}')

    # 3. Make the curl request for Gemini
    response=$(curl -s -X POST "$api_url" \
      -H "Content-Type: application/json" \
      -d "$payload")

    # 4. Parse Gemini response and handle errors
    if [ $? -ne 0 ]; then
      echo "Error: curl command failed for Gemini." >&2
      return 1
    fi

    # Check for API errors in the response JSON
    error_message=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error_message" ]; then
      echo "Error: Gemini API Error: $error_message" >&2
      # You might want to see the full error: echo "$response" >&2
      return 1
    fi

    # Extract the text content. Gemini nests it under candidates -> content -> parts -> text
    # It might return multiple candidates, usually the first is sufficient.
    # It might also return multiple parts, concatenate them.
    response_text=$(echo "$response" | jq -r '.candidates[0].content.parts[]?.text // empty' | paste -sd '\n')

    if [ -z "$response_text" ]; then
      # Handle cases like safety blocks or empty responses
      local finish_reason=$(echo "$response" | jq -r '.candidates[0].finishReason // "UNKNOWN"')
      if [[ "$finish_reason" == "SAFETY" ]]; then
        echo "Warning: Gemini response blocked due to safety settings." >&2
        response_text="[Response blocked by safety settings]"
      elif [[ "$finish_reason" == "RECITATION" ]]; then
        echo "Warning: Gemini response blocked due to recitation policy." >&2
        response_text="[Response blocked by recitation policy]"
      else
        echo "Error: Could not extract text from Gemini response. Finish Reason: $finish_reason" >&2
        # echo "Full Gemini Response: $response" >&2 # for debugging
        return 1
      fi
    fi

  elif [[ "$API_PROVIDER" == "OpenRouter" ]]; then
    api_key="$OPENROUTER_API_KEY"
    api_url="https://openrouter.ai/api/v1/chat/completions"

    # OpenRouter payload structure: { "model": "...", "messages": [history array including system prompt] }
    # Create the system message JSON separately
    local system_message_json=$(create_api_message_json "system" "$SYSTEM_PROMPT")
    # Prepend the system message JSON string to the extracted history array string
    # Note: history_json_array already contains the user/assistant messages
    local messages_json_array_with_system=$(echo "$history_json_array" | jq --argjson sys_msg "$system_message_json" '[$sys_msg] + .')

    payload=$(jq -n --arg model "$MODEL" --argjson messages "$messages_json_array_with_system" \
      '{model: $model, messages: $messages}')
    # Add other parameters like temperature, max_tokens if desired:
    # '{model: $model, messages: $messages, temperature: 0.7, max_tokens: 1024}'

    # 3. Make the curl request for OpenRouter
    response=$(curl -s -X POST "$api_url" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $api_key" \
      -H "HTTP-Referer: http://localhost" \
      -H "X-Title: AIHelp CLI" \
      -d "$payload")

    # 4. Parse OpenRouter response and handle errors
    if [ $? -ne 0 ]; then
      echo "Error: curl command failed for OpenRouter." >&2
      return 1
    fi

    # Check for API errors
    error_message=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error_message" ]; then
      echo "Error: OpenRouter API Error: $error_message" >&2
      # echo "Full OpenRouter Response: $response" >&2 # for debugging
      return 1
    fi

    # Extract the text content. OpenRouter nests it under choices -> message -> content
    response_text=$(echo "$response" | jq -r '.choices[0].message.content // empty')

    if [ -z "$response_text" ]; then
      echo "Error: Could not extract text from OpenRouter response." >&2
      # echo "Full OpenRouter Response: $response" >&2 # for debugging
      return 1
    fi

  else
    echo "Error: Unknown API Provider '$API_PROVIDER'." >&2
    return 1
  fi

  # 5. Return the extracted text
  echo "$response_text"
  return 0 # Indicate success
}

# --- Command Copying ---
handle_command_copying() {
  local ai_response="$1"
  local line
  local -a copyable_items=()
  local in_block=0
  local current_block=""

  # Use process substitution to read line by line
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Check for closing delimiter first (only if already in a block)
    if [[ $in_block -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*\`\`\`[[:space:]]*$ ]]; then
      # Exiting a block
      in_block=0
      # Store the accumulated block content if non-empty
      if [ -n "$current_block" ]; then
        # Use printf '%s' to avoid adding an extra newline at the end
        copyable_items+=("$(printf '%s' "$current_block")")
      fi
      current_block="" # Reset for next potential block
    # Check for opening delimiter (only if not already in a block)
    # Allows optional language specifier (alphanumeric, _, -)
    elif [[ $in_block -eq 0 ]] && [[ "$line" =~ ^[[:space:]]*\`\`\`[a-zA-Z0-9_-]*[[:space:]]*$ ]]; then
      # Entering a block
      in_block=1
      current_block="" # Start accumulating (exclude delimiter line)
    # If inside a block, accumulate content
    elif [[ $in_block -eq 1 ]]; then
      # Append line to current block, handling the first line vs subsequent lines
      if [ -z "$current_block" ]; then
        current_block="$line"
      else
        # Append with a newline separator
        current_block=$(printf '%s\n%s' "$current_block" "$line")
      fi
    fi
  done < <(printf '%s\n' "$ai_response") # Feed the AI response line by line

  # Note: Unterminated blocks (if the AI response ends mid-block) are ignored.

  local count=${#copyable_items[@]}

  # If items were found, prompt the user
  if [[ $count -gt 0 ]]; then
    echo "--- Copyable Code Blocks ---" # Changed title slightly
    for i in "${!copyable_items[@]}"; do
      local item_text="${copyable_items[i]}"
      local first_line

      # Get first line for display, add ellipsis if multi-line
      first_line=$(echo "$item_text" | head -n 1)
      # Check if the block has more than one line
      if [[ $(echo "$item_text" | wc -l) -gt 1 ]]; then
        # Check if the first line is shorter than, say, 60 chars before adding ellipsis
        if [[ ${#first_line} -lt 60 ]]; then
          first_line="$first_line [...]"
        else
          # If the first line is long, show the first 60 chars + ellipsis
          first_line="${first_line:0:60} [...]"
        fi
      fi
      # Ensure index starts from 1 for display
      printf "%d) %s\n" $((i + 1)) "$first_line"
    done
    echo "--------------------------"

    local selection
    # Prompt user, allowing empty input for cancellation
    read -p "Enter number to copy (1-$count), or press Enter/0 to cancel: " selection

    # Validate input: Check if it's a valid number within the range
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$count" ]; then
      local index=$((selection - 1))
      local final_content="${copyable_items[index]}"

      # Copy the exact block content to clipboard
      # Use printf '%s' to avoid adding extra newline by echo
      printf '%s' "$final_content" | $CLIPBOARD_TOOL
      echo "Copied to clipboard!"
    # Check if input is empty or '0' for cancellation
    elif [ -z "$selection" ] || [[ "$selection" == "0" ]]; then
      echo "Copy cancelled."
    else
      echo "Invalid selection."
    fi
  # If no blocks are found, simply don't show the prompt.
  fi
}

# --- Main Chat Loop ---
main() {
  # Check if configuration is complete before starting chat
  if [ -z "$API_PROVIDER" ] || [ -z "$MODEL" ]; then
    echo "Configuration incomplete." >&2
    echo "Please run '$0 --config' first to select API provider and model." >&2
    exit 1
  fi

  echo "Welcome to AI Help! Provider: $API_PROVIDER, Model: $MODEL"
  echo "Type '/exit' to quit, '/history' to load previous chat, '/new' for new chat, '/config' to reconfigure."

  # Initial session setup
  local start_status
  start_new_session # Prompt user for initial action (new, history, exit)
  start_status=$?
  if [ $start_status -ne 0 ]; then
    # If /history was chosen but failed or was cancelled, start a default new session
    echo "Falling back to new timestamped session."
    create_new_session_file "" # Create default timestamped session
  fi
  # If start_new_session exited or loaded history successfully, we proceed

  # Main loop
  while true; do
    # Read user input with readline support
    read -e -p $'\n\e[34mYou:\e[0m ' user_input

    # Handle commands
    case "$user_input" in
    "/exit")
      echo "Exiting AI Help."
      break
      ;;
    "/new")
      # Prompt again for new session name, history load, or exit
      local new_status
      start_new_session
      new_status=$?
      if [ $new_status -ne 0 ]; then
        # If /history was chosen but failed or was cancelled, start a default new session
        echo "Falling back to new timestamped session."
        create_new_session_file "" # Create default timestamped session
      fi
      continue # Skip API call for this turn
      ;;
    "/history")
      # Just attempt to load history, don't change session if cancelled
      select_and_load_history
      continue # Skip API call for this turn
      ;;
    "/config")
      echo "Switching to config..."
      configure_settings # Re-run config
      # Re-source config in case it changed
      # Re-source config in case it changed
      # Check if CONFIG_FILE exists before sourcing
      if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
      fi
      echo "Config updated. Provider: $API_PROVIDER, Model: $MODEL"
      # After config, prompt for session action again
      local config_status
      start_new_session
      config_status=$?
      if [ $config_status -ne 0 ]; then
        # If /history was chosen but failed or was cancelled, start a default new session
        echo "Falling back to new timestamped session."
        create_new_session_file "" # Create default timestamped session
      fi
      continue
      ;;

    "") # Handle empty input
      continue
      ;;
    esac

    # Add user message to history (as a wrapper object string)
    local user_api_json=$(create_api_message_json "user" "$user_input")
    local user_history_item=$(jq -n --argjson msg "$user_api_json" --arg model "" \
                              '{message_json: $msg, model_used: $model}' | jq -c .)
    CHAT_HISTORY+=("$user_history_item")
    # Save history immediately after adding user message
    if ! save_history; then
        echo "Warning: Failed to save history after user input." >&2
    fi

    # Call the API
    local ai_response
    ai_response=$(call_api "$user_input")
    local api_call_status=$?

    if [ $api_call_status -ne 0 ] || [ -z "$ai_response" ]; then
      echo "Error: API call failed."
      # Remove the last user message from history on failure? Optional.
      if [ ${#CHAT_HISTORY[@]} -gt 0 ]; then # Check if history is not empty
        unset 'CHAT_HISTORY[-1]'
      fi
      continue
    fi

    # Add AI response to history
    # Use the correct role based on the API provider for the response
    local response_role="assistant" # Default for OpenRouter
    if [[ "$API_PROVIDER" == "Gemini" ]]; then
      response_role="model"
    fi
    # Add AI response to history (as a wrapper object string)
    local ai_api_json=$(create_api_message_json "$response_role" "$ai_response")
    local ai_history_item=$(jq -n --argjson msg "$ai_api_json" --arg model "$MODEL" \
                            '{message_json: $msg, model_used: $model}' | jq -c .)
    CHAT_HISTORY+=("$ai_history_item")

    # Save history after successful call
    # Save history *after* adding the AI response
    if ! save_history; then
      # Handle save error if needed, maybe just continue
      echo "Warning: Failed to save history after AI response." >&2
    fi

    # Interpret the raw AI response first
    local interpreted_response
    interpreted_response=$(printf '%b' "$ai_response")

    # Display interpreted AI response using bat
    echo -e "\n\e[32mAI ($MODEL):\e[0m" # Green for AI
    echo "$interpreted_response" | bat --language md --paging=never --style=plain --color=always

    # Handle command copying using the interpreted response
    handle_command_copying "$interpreted_response"

  done
}

# --- Argument Parsing ---
if [[ "$1" == "--config" ]]; then
  setup_config # Ensure .env is loaded first for API key checks
  configure_settings
  exit 0
fi

# --- Run Setup and Main ---
# Setup needs to run first to load config for main
setup_config
main

exit 0
