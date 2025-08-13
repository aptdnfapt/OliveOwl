# OliveOwl - Complete Feature List

## Core Features
- Terminal-based AI chat assistant supporting multiple AI providers
- Interactive chat loop with persistent history
- Markdown rendering using `bat`
- Code block detection and copying with `gum choose`
- Dynamic model selection with automatic fetching
- Configuration management with `.env` file
- Loading spinner animation during API calls
- Retry mechanism for failed API calls
- Session naming and history management

## AI Provider Support
- **Google Gemini** - Full API integration with automatic model fetching
- **OpenRouter** - Full API integration with automatic model fetching
- **OpenAI** - Full API integration with automatic model fetching
- **Cerebras** - Full API integration with automatic model fetching
- **Ollama** - Local model support with automatic model fetching

## User Interface & Experience
- Colorful ASCII art welcome screen
- Colored prompts (You: in blue, AI: in purple)
- `/exit`, `/quit`, `/q` commands to quit the chat
- `/history`, `/h` commands to load previous chats with fzf interface
- `/config`, `/c` commands for complete configuration (API + editor + other settings)
- `/view`, `/v` commands to open chat history in configured editor
- `/new`, `/n` commands to start a new chat session
- `/prompt-history`, `/ph`, `/p` commands to select from previous prompts
- `/help`, `/?` commands to show help information

## History Management
- JSON-based chat history storage
- Automatic session naming based on conversation context
- Enhanced history file format with better organization
- fzf-based history selection with live preview
- Unique session names with timestamp identifiers
- Full-screen fzf interface with bat preview for history files

## Code Copying
- Automatic detection of Markdown code blocks
- Multi-block copying with looped selection
- Copy all code blocks from a response one by one
- Support for both Wayland (`wl-copy`) and X11 (`xclip`)

## Performance & Monitoring
- Token speed measurement (words per second)
- Client-side timing for response performance
- Loading spinner during API requests

## Configuration & Setup
- Interactive configuration wizard
- API key management through `.env` file
- Editor configuration
- Automatic dependency checking
- Secure file permissions for config files

## Technical Features
- Multi-line input support with `gum write`
- Cross-platform clipboard support
- Error handling with user-friendly messages
- System prompt customization
- Flexible model selection (fetched or manual entry)
- Session continuity when changing models
- Prompt history management with /prompt-history command

## Future Enhancements
- Up arrow key support in input editor to recall previous prompts
- Streaming output for real-time response display
- Simplified retry mechanism using prompt history instead of dedicated retry loop