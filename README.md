# OliveOwl - Terminal AI Chat Assistant (Gemini , OpenRouter , Ollama)

```
  ,-.   ,-.  
 ( O ) (o.o)  
  `-’   |_)  oliveowl 
    “who?”
```

This project was inspired by the Warp AI Terminal and developed with significant assistance from Gemini 2.5.

Check out a video demonstration of OliveOwl here:
[https://youtu.be/mkkkX1Grqs8](https://youtu.be/mkkkX1Grqs8)

A simple Bash script to interact with AI models (Gemini or OpenRouter) directly from your terminal. It features chat history, Markdown rendering via `bat`, easy command copying via `gum choose`, dynamic model selection, and a loading spinner.

## Features

*   Supports Google Gemini, OpenRouter compatible APIs, and local Ollama models.
*   Interactive chat loop in the terminal.
*   Saves chat history in JSON files (`~/.config/oliveowl/history/`).
*   Allows naming chat sessions for easier history management.
*   Uses `fzf` for selecting API provider and history files.
*   Uses `gum choose` for selecting code blocks to copy.
*   **Dynamically fetches and presents available models during configuration.**
*   **Includes a loading spinner animation while waiting for AI responses, with retry options on API call failure.**
*   **Allows using `/config` in the initial session prompt or during chat to reconfigure API settings.**
*   **Allows using `/view` during chat to open the current history in your configured editor.**
*   Renders AI responses as Markdown using `bat`.
*   **Enhanced History Preview:** The `/history` command now provides a full-screen `fzf` interface with a live preview of the JSON content of chat history files using `bat`.
*   Detects Markdown code blocks (\`\`\`...\`\`\`) in AI responses and allows copying their content using `gum choose`.
*   **Displays "token speed" (words per second) for each AI response, providing insight into response generation performance.**
*   Configuration stored in `~/.config/oliveowl/`.
*   Supports local Ollama instances, allowing you to use models running on your own machine.

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

## Installation

1.  **Clone or Download:** Get the `oliveowl.sh` script into a directory (e.g., `~/oliveowl`).
2.  **Make Executable:**
    ```bash
    chmod +x oliveowl.sh
    ```
3.  **(Optional) Add to PATH:** For global access, move or link the script to a directory in your `$PATH`. A common place is `~/.local/bin`:
    ```bash
    mkdir -p ~/.local/bin
    mv oliveowl.sh ~/.local/bin/oliveowl
    ```
    Ensure `~/.local/bin` is in your `$PATH` (check your `~/.profile` or `~/.bashrc`). You might need to restart your terminal or run `source ~/.profile`. After this, you can run the tool by just typing `oliveowl`.

## Configuration

1.  **Create Config Directory (if needed):** The script attempts to create `~/.config/oliveowl` on first run, but you can create it manually: `mkdir -p ~/.config/oliveowl`
2.  **Add API Keys:** Create or edit the environment file `~/.config/oliveowl/.env`. Add your API keys:
    ```ini
    # ~/.config/oliveowl/.env
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
    OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY_HERE
    # Ollama base URL (optional, defaults to http://localhost:11434 if not set)
    # Example: OLLAMA_BASE_URL=http://my-ollama-server:11434
    OLLAMA_BASE_URL=
    ```
    Replace the placeholders with your actual keys. For Gemini and OpenRouter, you only need the key for the provider(s) you intend to use. For Ollama, `OLLAMA_BASE_URL` is optional; if left blank or commented out, the script will default to `http://localhost:11434`. Set it if your Ollama instance runs on a different host or port. Make the file readable only by you: `chmod 600 ~/.config/oliveowl/.env`.
3.  **Run Initial Config:** Run the script with the `--config` flag to select your API provider (Gemini, OpenRouter, or Ollama) and model.
    *   For Gemini and OpenRouter, the script will attempt to dynamically fetch available models.
    *   For Ollama, the script will attempt to fetch models from your local Ollama instance (using the `OLLAMA_BASE_URL` if set, or the default `http://localhost:11434`). Ensure your Ollama instance is running and accessible.
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

The script will prompt you to enter a name for a new chat session, or you can type `/history` to load a previous chat, `/config` to reconfigure, or `/exit` to quit.

**In-Chat Commands:**

*   `/exit`: Quit the current chat session.
*   `/new`: Start a new chat session (prompts for an optional name).
*   `/history`: Use `fzf` to select and load a previous chat session, with a full-screen interface and a live preview of the JSON content using `bat`.
*   `/config`: Re-run the API provider, model, and editor selection.
*   `/view`: Open the current chat history in your configured editor (e.g., `nvim`, `vi`, `nano`).

**User Input:**

When prompted with `You:`, the script will open a minimal text editor using `gum write`.
*   Type your message directly in the editor. Multi-line input and pasting work naturally here.
*   Press `Ctrl+D` or `Esc` (depending on the editor mode) to finish and submit your input.
*   Press `Ctrl+C` to cancel input.

**Code Block Copying:**

If the AI includes Markdown code blocks (\`\`\`...\`\`\`) in its response, the script will detect them after the response is displayed. It will then launch `gum choose`, showing a numbered list of the detected blocks (displaying the first line of each). You can select multiple blocks one after another. After copying a block, it will be removed from the list, and the prompt will reappear, allowing you to copy another. This loop continues until you select the "Stop Copy loop" option or all blocks have been copied.

## Contribution

We welcome your feedback and contributions! If you have suggestions, bug reports, or would like to contribute code, please feel free to open an issue or pull request.

**Note on OpenAI Compatibility:** We plan to add compatibility for OpenAI models in the future. However, the developer currently lacks an OpenAI API key, which prevents testing and full implementation. Your contributions or feedback regarding OpenAI integration would be highly appreciated!
