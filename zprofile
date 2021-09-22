# For debugging zsh slowness
#set -x

# Accelerate loading shell environment / init variables
# $1 name of cache entry  e.g. "rbenv-init"
# $2 command to generate e.g. "rbenv init -"
function cached_source() {
    local cache_file="$HOME/.cache/$1.zsh"
    # Optimize for cache file existing at the cost of an error message if it doesn't
    if ! source $cache_file ; then
        echo "Building $cache_file cache file using $2"
        if ! eval "$2 > $cache_file" ; then
            echo "Failed to execute $2"
            rm $cache_file
            return -1
        fi
        if ! source $cache_file ; then
            echo "Failed to generate $cache_file using $2"
            return -1
        else
            echo "Successfully generated $cache_file using $2"
            return 0
        fi
    else
        # Optimal / success path - load existing cache
        return 0
    fi
}

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
