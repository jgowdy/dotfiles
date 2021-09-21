# Load Homebrew shellenv
if ! source .cache/homebrew.zsh ; then
    if [ -d "/opt/homebrew/bin" ] ; then
        echo "Homebrew installed, creating shellenv cache file"
	/opt/homebrew/bin/brew shellenv > .cache/homebrew.zsh
        source .cache/homebrew.zsh
    elif [ -d "/home/linuxbrew/.linuxbrew/bin" ] ; then
	echo "Linuxbrew installed, creating shellenv cache file"
	/home/linuxbrew/.linuxbrew/bin/brew shellenv > .cache/homebrew.zsh
        source .cache/homebrew.zsh
    else
        echo "Homebrew not installed, caching empty results"
        echo "" > .cache/homebrew.zsh
    fi
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
