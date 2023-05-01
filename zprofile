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

##
# Your previous /Users/jgowdy/.zprofile file was backed up as /Users/jgowdy/.zprofile.macports-saved_2022-02-03_at_18:37:59
##

# MacPorts Installer addition on 2022-02-03_at_18:37:59: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.


# MacPorts Installer addition on 2022-02-03_at_18:37:59: adding an appropriate MANPATH variable for use with MacPorts.
export MANPATH="/opt/local/share/man:$MANPATH"
# Finished adapting your MANPATH environment variable for use with MacPorts.

export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
