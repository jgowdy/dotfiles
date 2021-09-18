# If Homebrew is installed, let Homebrew set its variables
if [ -d "$HOME/.homebrew" ] ; then
    eval "$($HOME/.homebrew/bin/brew shellenv)"
fi

# Prepend private ~/bin to PATH
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# Prepend private ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# If golang is manually installed, prepend it to PATH
if [ -d "/usr/local/go/bin" ] ; then
    PATH="/usr/local/go/bin:$PATH"
fi
