# For debugging zsh slowness
#set -x

source $HOME/.zfunc

# Load Homebrew shellenv
if ! cached_source 'homebrew-shellenv' '/opt/homebrew/bin/brew shellenv' ; then
    if ! cached_source 'homebrew-shellenv' '/home/linuxbrew/.linuxbrew/bin/brew shellenv' ; then
        if ! cached_source 'homebrew-shellenv' '/usr/local/bin/brew shellenv' ; then
            echo "Homebrew not installed touch $HOME/.cache/homebrew-shellenv.zsh to cache empty results"
        fi
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

# If golang is manually installed in /usr/local/go, prepend it to PATH
if [ -d "/usr/local/go/bin" ] ; then
    PATH="/usr/local/go/bin:$PATH"
fi
