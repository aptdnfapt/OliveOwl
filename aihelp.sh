#!/bin/bash

# aihelp - Terminal AI Chat Assistant

# --- Configuration ---
CONFIG_DIR="$HOME/.config/aihelp"
ENV_FILE="$CONFIG_DIR/.env"
HISTORY_DIR="$CONFIG_DIR/history"
CONFIG_FILE="$CONFIG_DIR/config"

# --- Dependency Checks ---
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: Required command '$1' not found. Please install it." >&2
        exit 1
    fi
}

check_clipboard_tool() {
    # Prioritize based on session type if available
    if [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
        if command -v xclip &> /dev/null; then
            CLIPBOARD_TOOL="xclip -selection clipboard"
        elif command -v wl-copy &> /dev/null; then # Fallback if xclip missing but wl-copy exists
             CLIPBOARD_TOOL="wl-copy"
        fi
    elif [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
         if command -v wl-copy &> /dev/null; then
            CLIPBOARD_TOOL="wl-copy"
         elif command -v xclip &> /dev/null; then # Fallback if wl-copy missing but xclip exists
             CLIPBOARD_TOOL="xclip -selection clipboard"
         fi
    fi

    # If not determined by session type, use original detection logic
    if [ -z "$CLIPBOARD_TOOL" ]; then
        if command -v wl-copy &> /dev/null; then
            CLIPBOARD_TOOL="wl-copy"
        elif command -v xclip &> /dev/null; then
            CLIPBOARD_TOOL="xclip -selection clipboard"
        fi
    fi

    # Final check if a tool was found
    if [ -z "$CLIPBOARD_TOOL" ]; then
        echo "Error: No clipboard tool found (need 'wl-copy' for Wayland or 'xclip' for X11)." >&2
        exit 1
    else
         echo "Using clipboard tool: $CLIPBOARD_TOOL (Session type: ${XDG_SESSION_TYPE:-unset})"
    fi
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
        echo "# Add your API keys here" > "$ENV_FILE"
        echo "GEMINI_API_KEY=" >> "$ENV_FILE"
        echo "OPENROUTER_API_KEY=" >> "$ENV_FILE"
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
        echo "API_PROVIDER=" > "$CONFIG_FILE" # Will be 'gemini' or 'openrouter'
        echo "MODEL=" >> "$CONFIG_FILE"
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
            # Expanded hardcoded list for Gemini
            model_list=$(cat << MODELS
gemini-1.5-pro-latest
gemini-1.5-flash-latest
gemini-1.0-pro
gemini-1.0-pro-vision
gemini-2.0-flash
gemini-2.0-flash-lite
gemini-2.0-flash-thinking-exp-01-21
gemini-2.0-flash-thinking-exp-1219
gemini-2.0-pro-exp-02-05
gemini-2.5-pro-exp-03-25
gemma-3-27b-it
MODELS
)
            ;;
        "OpenRouter")
             # Check for OpenRouter Key
            if [ -z "$OPENROUTER_API_KEY" ]; then
                echo "Error: OPENROUTER_API_KEY not set in $ENV_FILE." >&2
                exit 1
            fi
            model_list=$(fetch_openrouter_models)
            if [ $? -ne 0 ] || [ -z "$model_list" ]; then
                 echo "Could not get OpenRouter models. Exiting." >&2
                 exit 1
            fi
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
    echo "API_PROVIDER=\"$API_PROVIDER\"" > "$CONFIG_FILE"
    echo "MODEL=\"$MODEL\"" >> "$CONFIG_FILE"

    echo "Configuration saved to $CONFIG_FILE:"
    echo "  Provider: $API_PROVIDER"
    echo "  Model: $MODEL"
    echo "Setup complete. You can now run 'aihelp.sh'."
}

# --- System Prompt ---
# Instructs the AI on formatting and behavior - Updated for stricter command formatting
SYSTEM_PROMPT=$(cat << 'EOF'
You are a helpful AI assistant running in a Linux terminal. Provide concise answers. Format your responses using Markdown.
CRITICAL INSTRUCTION FOR COMMANDS:
If you provide an executable shell command that the user might want to copy and run:
1. Prefix the command *only* with '>> ' (two greater-than signs followed by a single space).
2. Place EACH such command on its OWN LINE.
3. Do NOT wrap the '>> command' line in backticks (`), quotes (", '), or list markers (*, -).
Example of CORRECT formatting for a copyable command:
>> ls -la /tmp

Example of INCORRECT formatting:
* `>> pwd`
* `>> cd ..`
* ">> echo hello"
Only use the '>> ' prefix for commands intended to be easily copied. For explanatory code snippets, use standard Markdown code blocks.
EOF
)

# --- History Management ---
CHAT_HISTORY=() # In-memory array of JSON objects for the current session
CURRENT_HISTORY_FILE=""

# Function to create a JSON object for a message (handles Gemini/OpenRouter differences)
# Usage: create_message_json "user" "Hello there"
create_message_json() {
    local role="$1"
    local content="$2"
    local json_content

    # Escape special characters for JSON
    json_content=$(echo "$content" | jq -Rsa .) # Encodes string safely

    if [[ "$API_PROVIDER" == "Gemini" ]]; then
        # Gemini uses "user" and "model" roles, and a "parts" array
        local gemini_role="$role"
        if [[ "$role" == "assistant" ]]; then # Map OpenRouter's role if needed
            gemini_role="model"
        fi
         # Simple text part for now
        echo "{\"role\": \"$gemini_role\", \"parts\": [{\"text\": $json_content}]}" | jq -c .
    else # OpenRouter uses "user" and "assistant"
        local openrouter_role="$role"
        if [[ "$role" == "model" ]]; then # Map Gemini's role if needed
             openrouter_role="assistant"
        fi
        echo "{\"role\": \"$openrouter_role\", \"content\": $json_content}" | jq -c .
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
    # Read the JSON array from the file into the bash array CHAT_HISTORY
    # Each element of CHAT_HISTORY will be a compact JSON object string
    mapfile -t CHAT_HISTORY < <(jq -c '.[]' "$file_path")
    CURRENT_HISTORY_FILE="$file_path"
    echo "Loaded history from: $CURRENT_HISTORY_FILE"
}

# Function to display the current CHAT_HISTORY
display_history() {
    echo "--- Chat History ---"
    for message_json in "${CHAT_HISTORY[@]}"; do
        local role content
        # Use jq to extract role and content, handling both formats
        role=$(echo "$message_json" | jq -r '.role')
        content=$(echo "$message_json" | jq -r 'if .parts then .parts[0].text else .content end')

        if [[ "$role" == "user" ]]; then
            echo -e "\n\e[34mYou:\e[0m $content" # Blue for user
        elif [[ "$role" == "model" || "$role" == "assistant" ]]; then
             echo -e "\n\e[32mAI ($MODEL):\e[0m" # Green for AI
             # Use bat for markdown rendering of AI response
             echo "$content" | bat --language md --paging=never --style=plain --color=always
        fi
    done
     echo "--------------------"
}

# Function to save the current CHAT_HISTORY array to CURRENT_HISTORY_FILE
save_history() {
    if [ -z "$CURRENT_HISTORY_FILE" ]; then
        echo "Error: No history file set for saving." >&2
        return 1
    fi
    # Convert the bash array of JSON strings into a single JSON array string
    printf "%s\n" "${CHAT_HISTORY[@]}" | jq -s '.' > "$CURRENT_HISTORY_FILE"
    # echo "History saved to: $CURRENT_HISTORY_FILE" # Optional: for debugging
}

# Function to start a new chat session, optionally prompting for a name
start_new_session() {
    CHAT_HISTORY=() # Clear in-memory history

    local session_name filename timestamp sanitized_name

    # Prompt for session name
    read -e -p "Enter name for new chat session (leave blank for timestamp): " session_name

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
    echo "[]" > "$CURRENT_HISTORY_FILE" # Create empty JSON array file
    echo "Session file: $CURRENT_HISTORY_FILE"
}

# --- API Call Implementation ---
# Takes user input, sends history + input to API, returns AI response text
call_api() {
    local user_input="$1"
    local api_url api_key payload response response_text error_message

    # 1. Prepare payload (combine history and new user message)
    # The CHAT_HISTORY array already contains JSON strings in the correct format per provider
    # We just need to add the latest user message (which was already added before calling this function)
    # and format the whole thing as a JSON array string.
    local history_json_array=$(printf "%s\n" "${CHAT_HISTORY[@]}" | jq -s '.')

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
        # Add system prompt as the first message if not already there (or handle as needed)
        # Our current history management adds user/assistant roles. Let's prepend the system prompt.
        local system_message_json=$(create_message_json "system" "$SYSTEM_PROMPT")
        local messages_json_array=$(printf "%s\n%s\n" "$system_message_json" "${CHAT_HISTORY[@]}" | jq -s '.')


        payload=$(jq -n --arg model "$MODEL" --argjson messages "$messages_json_array" \
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
    local commands_with_prefix cleaned_commands selected_command command_to_copy

    # Extract lines containing ">> "
    commands_with_prefix=$(echo -e "$ai_response" | grep '>> ')

    if [ -n "$commands_with_prefix" ]; then
        # Extract text *after* ">> ", then clean it
        # 1. Use sed to keep only the part after ">> " on each matching line
        # 2. Use another sed to remove leading/trailing whitespace and backticks from the result
        extracted_commands=$(echo -e "$commands_with_prefix" | sed -n 's/.*>> //p')
        cleaned_commands=$(echo -e "$extracted_commands" | sed -E 's/^[[:space:]`]+//; s/[[:space:]`]+$//')


        if [ -z "$cleaned_commands" ]; then
             # echo "Debug: No commands left after cleaning." >&2
             return # Nothing left to copy
        fi

        # Use nl to number the *cleaned* commands, then fzf for selection
        selected_command=$(echo -e "$cleaned_commands" | nl -w1 -s') ' | fzf --prompt="Select command to copy (Esc to cancel): " --height=10 --layout=reverse --no-sort --ansi)

        if [ -n "$selected_command" ]; then
            # Extract the actual command part (after the number and parenthesis)
            command_to_copy=$(echo "$selected_command" | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]*//')
            # Copy to clipboard
            echo -n "$command_to_copy" | $CLIPBOARD_TOOL
            echo "Command copied to clipboard!"
        fi
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
    echo "Type '/exit' to quit, '/history' to load previous chat, '/new' for new chat."

    # Always start a new session on script launch
    start_new_session

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
                start_new_session
                continue # Skip API call for this turn
                ;;
            "/history")
                # List ALL .json files, sorted by time (most recent first)
                local history_files=$(ls -t "$HISTORY_DIR"/*.json 2>/dev/null)
                if [ -z "$history_files" ]; then
                    echo "No history files found."
                    continue
                fi
                # Use basename to show only filenames in fzf, then reconstruct full path
                local chosen_filename=$(echo "$history_files" | xargs -n 1 basename | fzf --prompt="Select chat history to load: " --height=10 --layout=reverse)
                if [ -n "$chosen_filename" ]; then
                    # Reconstruct the full path
                    local chosen_file_path="$HISTORY_DIR/$chosen_filename"
                    load_history "$chosen_file_path"
                    display_history
                fi
                continue # Skip API call for this turn
                ;;
             "/config")
                 echo "Switching to config..."
                 configure_settings # Re-run config
                 # Re-source config in case it changed
                 # Check if CONFIG_FILE exists before sourcing
                 if [ -f "$CONFIG_FILE" ]; then
                     source "$CONFIG_FILE"
                 fi
                 echo "Config updated. Provider: $API_PROVIDER, Model: $MODEL"
                 # Decide if we should start a new session or continue
                 start_new_session # Start fresh after config change
                 continue
                 ;;

            "") # Handle empty input
                continue
                ;;
        esac

        # Add user message to history
        CHAT_HISTORY+=("$(create_message_json "user" "$user_input")")

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
        CHAT_HISTORY+=("$(create_message_json "$response_role" "$ai_response")")

        # Save history after successful call
        save_history

        # Display AI response using bat
        echo -e "\n\e[32mAI ($MODEL):\e[0m" # Green for AI
        echo "$ai_response" | bat --language md --paging=never --style=plain --color=always

        # Handle command copying
        handle_command_copying "$ai_response"

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
