# OliveOwl - Terminal AI Chat Assistant (Gemini , OpenRouter, OpenAI, Cerebras, Ollama)

```
  ,-.   ,-.  
 ( O ) (o.o)  
  `-’   |_)  oliveowl 
    “who?”
```

This project was inspired by the Warp AI Terminal and developed with significant assistance from Gemini 2.5. 
But turned out to be more of a terminal Alternative of web bassed bloated chat ui . 

### Check out a video demonstration of OliveOwl here:
* 1.0v (https://youtu.be/mkkkX1Grqs8)
* 2.0v (https://youtu.be/dUvcjOpBu6k)
A simple Bash script to interact with AI models (Google Gemini, OpenRouter, OpenAI, Cerebras, and Ollama) directly from your terminal. It features chat history, Markdown rendering via `bat`, easy command copying via `gum choose`, dynamic model selection, and a loading spinner.

## Features

*   Supports Google Gemini, OpenRouter, OpenAI, Cerebras, local Ollama models, and **custom OpenAI-compatible providers**.
*   Interactive chat loop in the terminal.
*   Saves chat history in JSON files (`~/.config/oliveowl/history/`).
*   **Automatic Session Naming:** If you start a chat without giving it a name, the AI will automatically name the session based on the context of the conversation. The name is suggested after your first prompt and then refined every five prompts. Manually named sessions keep their original name.
*   Uses `fzf` to display human-readable session names (instead of filenames) for easy history selection.
*   Uses `gum choose` for selecting code blocks to copy.
*   **Dynamically fetches and presents available models during configuration.**
*   **Includes a loading spinner animation while waiting for AI responses, with retry options on API call failure.**
*   **Allows using `/config` in the initial session prompt or during chat to reconfigure API settings.**
*   **Allows using `/view` during chat to open the current history in your configured editor.**
*   **Supports shorthand commands: `/h` for `/history`, `/c` for `/config`, `/q` for `/exit`, `/n` for `/new`, `/v` for `/view`, `/ph` or `/p` for `/prompt-history`, and `/?` for `/help`.**
*   **Customizable system prompt with `/config` -> `Edit Instructions` option to add personal instructions that are appended to the base system prompt.**
*   Renders AI responses as Markdown using `bat`.
*   **Enhanced History Preview:** The `/history` command now provides a full-screen `fzf` interface with a live preview of the JSON content of chat history files using `bat`.
*   Detects Markdown code blocks (\`\`\`...\`\`\`) in AI responses and allows copying their content using `gum choose`.
*   **Displays "token speed" (words per second) for each AI response, providing insight into response generation performance.**
*   Configuration stored in `~/.config/oliveowl/`.
*   Supports local Ollama instances, allowing you to use models running on your own machine.
*   **Custom OpenAI-Compatible Providers:** Add any OpenAI-compatible API endpoint with custom base URL and API key.

## Dependencies

You need the following command-line tools installed:

*   `bash` (usually default)
*   `curl` (for making API requests)
*   `jq` (for parsing JSON responses)
*   `fzf` (for fuzzy finding/selection menus)
*   `bat` (for syntax highlighting/Markdown rendering)
*   `gum` (for multi-line input editing and spinners)
*   A clipboard tool: `xclip` (for X11) or `wl-copy` (for Wayland)
*   **For Ollama users:** A running Ollama instance. See [Ollama's official website](https://ollama.com/) for installation instructions.

Install them using your system's package manager. For example, on Debian/Ubuntu:
```bash
# Ensure apt can use HTTPS repositories and install GPG key
sudo apt update && sudo apt install -y apt-transport-https curl gpg
# Add Charm repo GPG key
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/charm.gpg
# Add Charm repo to sources
echo "deb [signed-by=/etc/apt/trusted.gpg.d/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
# Install dependencies
sudo apt update && sudo apt install -y curl jq fzf bat gum xclip # or wl-clipboard for wl-copy
```
On Fedora:
```bash
# Add Charm repo GPG key
sudo rpm --import https://repo.charm.sh/yum/gpg.key
# Add Charm repo
sudo dnf config-manager --add-repo https://repo.charm.sh/yum/charm.repo
# Install dependencies
sudo dnf install -y curl jq fzf bat gum xclip # or wl-clipboard for wl-copy
```
For other Unix-like systems (Arch Linux, macOS with Homebrew, etc.), please refer to the documentation for each individual tool (`curl`, `jq`, `fzf`, `bat`, `gum`, `xclip`/`wl-clipboard`) for installation instructions using your preferred package manager or method.

**Important:** It's recommended to use the latest version of `gum` available from the official Charm repository (as shown above) or other official installation methods. Older versions might have bugs (e.g., issues with multi-line input handling). Ensure your package manager is configured to pull the latest version from the Charm source if applicable.

*Note: `bat` might be called `batcat` on some systems (like Debian/Ubuntu). If so, you might need to create a symlink `sudo ln -s /usr/bin/batcat /usr/local/bin/bat` or adjust the script.*

## Quick Start

Install and run OliveOwl with a single command:

```bash
# Download and install OliveOwl
curl -sL https://raw.githubusercontent.com/aptdnfapt/OliveOwl/main/oliveowl -o ~/.local/bin/oliveowl && chmod +x ~/.local/bin/oliveowl

# Make sure ~/.local/bin is in your PATH (if not already)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# Run OliveOwl
oliveowl
```

Alternatively, if you prefer `wget`:

```bash
# Download and install OliveOwl
wget https://raw.githubusercontent.com/aptdnfapt/OliveOwl/main/oliveowl -O ~/.local/bin/oliveowl && chmod +x ~/.local/bin/oliveowl

# Make sure ~/.local/bin is in your PATH (if not already)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# Run OliveOwl
oliveowl
```

That's it! OliveOwl is now installed and ready to use.

**Note:** After running OliveOwl for the first time, use the `/config` command to add your API providers and select a model before you can start chatting.

## Manual configuration details . ( no need to use this and can be done all this with /config )

1.  **Create Config Directory (if needed):** The script attempts to create `~/.config/oliveowl` on first run, but you can create it manually: `mkdir -p ~/.config/oliveowl`
2.  **Add API Keys:** You can add API keys in two ways:
    *   **Manual Method:** Create or edit the environment file `~/.config/oliveowl/.env`. Add your API keys:
        ```ini
        # ~/.config/oliveowl/.env
        GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
        OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY_HERE
        OPENAI_API_KEY=YOUR_OPENAI_API_KEY_HERE
        CEREBRAS_API_KEY=YOUR_CEREBRAS_API_KEY_HERE
        # Ollama base URL (optional, defaults to http://localhost:11434 if not set)
        # Example: OLLAMA_BASE_URL=http://my-ollama-server:11434
        OLLAMA_BASE_URL=
        # Custom OpenAI-compatible providers
        # Format: CUSTOM_PROVIDER_<PROVIDER_NAME>_URL=https://api.example.com/v1
        # Format: CUSTOM_PROVIDER_<PROVIDER_NAME>_KEY=your_api_key
        # Example:
        CUSTOM_PROVIDER_MYPROVIDER_URL=https://api.openai.com/v1
        CUSTOM_PROVIDER_MYPROVIDER_KEY=your_api_key
        ```
        Replace the placeholders with your actual keys. For Gemini, OpenRouter, OpenAI, and Cerebras, you only need the key for the provider(s) you intend to use. For Ollama, `OLLAMA_BASE_URL` is optional; if left blank or commented out, the script will default to `http://localhost:11434`. Set it if your Ollama instance runs on a different host or port. For custom providers, use the format shown above with your provider name (in uppercase), base URL, and API key. Make the file readable only by you: `chmod 600 ~/.config/oliveowl/.env`.
    *   **Interactive Method:** Use the configuration menu during setup or by typing `/config` in chat. Select "Add Provider" to interactively add API keys for any provider without manually editing files. For custom providers, select "Custom OpenAI-Compatible" and follow the prompts.
3.  **Run Initial Config:** Run the script with the `--config` flag to access the configuration menu with three options: "Change Model", "Add Provider", and "Change Editor".
    *   **Change Model:** Select your API provider (Gemini, OpenRouter, OpenAI, Cerebras, Ollama, or any custom provider) and model. For Gemini, OpenRouter, OpenAI, Cerebras, and custom providers, the script will attempt to dynamically fetch available models if the API key is configured. For Ollama, the script will attempt to fetch models from your local Ollama instance (using the `OLLAMA_BASE_URL` if set, or the default `http://localhost:11434`). Ensure your Ollama instance is running and accessible.
    *   **Add Provider:** Interactively add API keys for any provider without manually editing files. For custom OpenAI-compatible providers, select "Custom OpenAI-Compatible" and enter the provider name, base URL, and API key.
    *   **Change Editor:** Configure your preferred editor for viewing chat history.
    The script uses `fzf` for selection.
    ```bash
    ./oliveowl.sh --config
    # or if added to PATH:
    # oliveowl --config
    ```
    This saves your choices to `~/.config/oliveowl/config`.

4.  **Change System Prompt (Optional):**
    The AI's default behavior and instructions are defined by the `SYSTEM_PROMPT` variable within the `oliveowl` script itself. If you wish to customize the AI's persona or provide specific instructions for all interactions, you can directly edit the `SYSTEM_PROMPT` variable in the `oliveowl` file.
    
    Open the `oliveowl` script in your preferred text editor (vim,nano or vscode)
    Locate the `SYSTEM_PROMPT` variable (around line 294) and modify its content. Ensure you maintain the triple-quote `"""` syntax for multi-line prompts.

## Usage

Run the script:
```bash
./oliveowl.sh
# or if added to PATH:
# oliveowl
```

The script will prompt you to enter a name for a new chat session, or you can type `/history` or `/h` to load a previous chat, `/config` or `/c` to reconfigure, or `/exit`, `/quit`, or `/q` to quit.

**In-Chat Commands:**

*   `/exit` or `/q`: Quit the current chat session.
*   `/new` or `/n`: Start a new chat session (prompts for an optional name).
*   `/history` or `/h`: Use `fzf` to select and load a previous chat session, with a full-screen interface and a live preview of the JSON content using `bat`.
*   `/config` or `/c`: Access the configuration menu to change your API provider, model, add new providers, or change your editor.
*   `/view` or `/v`: Open the current chat history in your configured editor (e.g., `nvim`, `vi`, `nano`).
*   `/prompt-history`, `/ph`, or `/p`: Select from previous prompts to reuse.
*   `/help` or `/?`: Show help information.

**User Input:**

When prompted with `You:`, the script will open a minimal text editor using `gum write`.
*   Type your message directly in the editor. Multi-line input and pasting work naturally here.
*   Press `Ctrl+D` or `Esc` (depending on the editor mode) to finish and submit your input.
*   Press `Ctrl+C` to cancel input.

**Code Block Copying:**

If the AI includes Markdown code blocks (\`\`\`...\`\`\`) in its response, the script will detect them after the response is displayed. It will then launch `gum choose`, showing a numbered list of the detected blocks (displaying the first line of each). You can select multiple blocks one after another. After copying a block, it will be removed from the list, and the prompt will reappear, allowing you to copy another. This loop continues until you select the "Stop Copy loop" option or all blocks have been copied.

## Contribution

We welcome your feedback and contributions! If you have suggestions, bug reports, or would like to contribute code, please feel free to open an issue or pull request.
