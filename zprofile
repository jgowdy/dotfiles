source $HOME/.zfunc

# Load Homebrew shellenv
if [ -e $HOME/.cache ] ; then
  if ! cached_source 'homebrew-shellenv' '/opt/homebrew/bin/brew shellenv' ; then
      if ! cached_source 'homebrew-shellenv' '/home/linuxbrew/.linuxbrew/bin/brew shellenv' ; then
          if ! cached_source 'homebrew-shellenv' '/usr/local/bin/brew shellenv' ; then
              echo "Homebrew not installed touch $HOME/.cache/homebrew-shellenv.zsh to cache empty results"
          fi
      fi
  fi
fi

# Prepend private ~/.local/bin to PATH
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# If golang is manually installed in /usr/local/go, prepend it to PATH
if [ -d "/usr/local/go/bin" ] ; then
    PATH="/usr/local/go/bin:$PATH"
fi

# ****************************************************************************************************
# Set telemetry opt-outs
# ****************************************************************************************************

export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1
export NPM_CONFIG_TELEMETRY=0
export DISABLE_NPM_USAGE_METRICS=1
export VSCODE_TELEMETRY_OPTOUT=true
export GOOGLE_ANALYTICS_DISABLED=true
export SENTRY_DISABLED=true
export AWS_TELEMETRY_OPT_OUT=true
export JEKYLL_NO_USAGE=true
export SKIP_TELEMETRY=true
export NO_UPDATE_NOTIFIER=true
export TELEMETRY_DISABLED=true
