# AI Help - Terminal AI Chat Assistant

A simple Bash script to interact with AI models (Gemini or OpenRouter) directly from your terminal. It features chat history, Markdown rendering via `bat`, and easy command copying via `fzf`.

## Features

*   Supports Google Gemini and OpenRouter compatible APIs.
*   Interactive chat loop in the terminal.
*   Saves chat history in JSON files (`~/.config/aihelp/history/`).
*   Allows naming chat sessions for easier history management.
*   Uses `fzf` for selecting API provider, model, history files, and commands to copy.
*   Renders AI responses as Markdown using `bat`.
*   Detects Markdown code blocks (```...```) in AI responses and allows copying their content using `fzf`.
*   Configuration stored in `~/.config/aihelp/`.

## Dependencies

You need the following command-line tools installed:

*   `bash` (usually default)
*   `curl` (for making API requests)
*   `jq` (for parsing JSON responses)
*   `fzf` (for fuzzy finding/selection menus)
*   `bat` (for syntax highlighting/Markdown rendering)
*   `gum` (for multi-line input editing)
*   A clipboard tool: `xclip` (for X11) or `wl-copy` (for Wayland)

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
For other systems (like Arch, macOS with Homebrew, or manual install), see the [Gum installation guide](https://github.com/charmbracelet/gum#installation).

*Note: `bat` might be called `batcat` on some systems (like Debian/Ubuntu). If so, you might need to create a symlink `sudo ln -s /usr/bin/batcat /usr/local/bin/bat` or adjust the script.*

## Installation

1.  **Clone or Download:** Get the `aihelp.sh` script into a directory (e.g., `~/aihelp`).
2.  **Make Executable:**
    ```bash
    chmod +x aihelp.sh
    ```
3.  **(Optional) Add to PATH:** For global access, move or link the script to a directory in your `$PATH`. A common place is `~/.local/bin`:
    ```bash
    mkdir -p ~/.local/bin
    mv aihelp.sh ~/.local/bin/aihelp
    ```
    Ensure `~/.local/bin` is in your `$PATH` (check your `~/.profile` or `~/.bashrc`). You might need to restart your terminal or run `source ~/.profile`. After this, you can run the tool by just typing `aihelp`.

## Configuration

1.  **Create Config Directory (if needed):** The script attempts to create `~/.config/aihelp` on first run, but you can create it manually: `mkdir -p ~/.config/aihelp`
2.  **Add API Keys:** Create or edit the environment file `~/.config/aihelp/.env`. Add your API keys:
    ```ini
    # ~/.config/aihelp/.env
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
    OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY_HERE
    ```
    Replace the placeholders with your actual keys. You only need the key for the provider(s) you intend to use. Make the file readable only by you: `chmod 600 ~/.config/aihelp/.env`.
3.  **Run Initial Config:** Run the script with the `--config` flag to select your API provider and model using `fzf`:
    ```bash
    ./aihelp.sh --config
    # or if added to PATH:
    # aihelp --config
    ```
    This saves your choices to `~/.config/aihelp/config`.

## Usage

Run the script:
```bash
./aihelp.sh
# or if added to PATH:
# aihelp
```

The script will start a new chat session and prompt you for an optional name.

**In-Chat Commands:**

*   `/exit`: Quit the chat session.
*   `/new`: Start a new chat session (prompts for an optional name).
*   `/history`: Use `fzf` to select and load a previous chat session.
*   `/config`: Re-run the API provider and model selection.

**User Input:**

When prompted with `You:`, the script will open a minimal text editor using `gum write`.
*   Type your message directly in the editor. Multi-line input and pasting work naturally here.
*   Press `Ctrl+D` or `Esc` (depending on the editor mode) to finish and submit your input.
*   Press `Ctrl+C` to cancel input.

**Code Block Copying:**

If the AI includes Markdown code blocks (```...```) in its response, the script will detect them after the response is displayed. It will then launch `fzf`, showing a numbered list of the detected blocks (displaying the first line of each). Select the block you want to copy using `fzf`, and its full content will be copied to your clipboard. Press `Enter` or `0` in the prompt (or `Esc` in `fzf`) to cancel copying.
