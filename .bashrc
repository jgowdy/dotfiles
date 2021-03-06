#!/bin/bash

#NOTE: .bash_profile vs .bashrc: http://www.joshstaiger.org/archives/2005/07/bash_profile_vs.html

# Some apps reload ~/.bashrc eventhough it has already been run in a parent environment (incorrectly on mac IMHO!),
# This is a way to prevent it:
# Update: VSCode seems to import the var, but not the environment, so we allow it to load if one of the VSCODE_* vars are defined defined.
if [[ (-z ${BASHRC_LOADED}) || (-n ${VSCODE_CLI}) || (-n ${VSCODE_PID}) || (-n ${VSCODE_IPC_HOOK}) ]]
then
	export BASHRC_LOADED=1 

	# If not running interactively, don't do anything
	[ -z "$PS1" ] && return

	####
	# constants
	####
	FALSE=
	TRUE=0

	#####
	# detect host OS
	#####
	IS_WINDOWS=$FALSE
	IS_MAC=$FALSE

	if [ "$(uname)" == "Darwin" ]
	then
		echo running under Mac OS X platform
		IS_MAC=$TRUE
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
	then
		echo running under Linux platform
	elif [ -n "$COMSPEC" -a -x "$COMSPEC" ]
	then 
		echo $0: running under Windows
		IS_WINDOWS=$TRUE
	fi

	#####
	# aliases
	#####
	alias ls='ls -AlGFh'
	alias ll='ls -AlGFh'
	alias rm='rm -i'
	alias grep='grep --color=auto'
	alias gdiff='git diff --color --cached'
	alias sha256='shasum -a 256'
	alias top='top -o cpu'
	alias github='~/github.sh'
	alias json='python -m json.tool' # http://stackoverflow.com/a/1920585/51061
	alias lso="ls -alG | awk '{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\" %0o \",k);print}'" #http://agileadam.com/2011/02/755-style-permissions-with-ls/

	#####
	# windows (cygwin) vs mac specific stuff
	#####
	# NOTE: Using /usr/LOCAL/bin per http://unix.stackexchange.com/questions/8656/usr-bin-vs-usr-local-bin-on-linux (not managed by distro)

	if [ $IS_MAC ]
	then
		alias nuget='mono /usr/local/bin/nuget.exe'
		export EDITOR='code -w'
		alias shred='rm -P' # mac doesn't include gnu shred, but uses -P with rm
	fi

	#####
	# rvm NONONONOO RVM!!! Use rbenv!
	#####
	# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
	# /rvm 


	#####
	# Bash Customization:
	#####
	# Prevent some items from going into .bash_history: https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
	export HISTSIZE=50
	export HISTFILESIZE=50
	export HISTIGNORE="bitcoind walletpassphrase*:./bitcoind walletpassphrase*:btc walletpassphrase*"
	
	#####
	# ss dev:
	export JAVA_HOME=$(/System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java_home)
	export GIT_ROOT=~/git
	export GIT_APP_CORE=${GIT_ROOT}/app-core


	#####
	# PATH variable
	#####
	# NOTE: About paths: http://serverfault.com/a/146142/28798 (i.e. drop files /etc/paths.d $PATH only works in terminal )
	export PATH=~/.rbenv/shims:~/bin:/usr/local/bin:$PATH # standard path: (note rbenv shims in front as it needs to be in front: https://github.com/sstephenson/rbenv#understanding-shims)

	export PATH=$PATH:/opt/local/bin:/opt/local/sbin # for macports (macports owns /opt/local/, see http://guide.macports.org/#installing.shell)
	export MANPATH=/opt/local/share/man:$MANPATH # for macports+man
	export SCALA_HOME=/usr/local/share/scala # http://www.scala-lang.org/documentation/getting-started.html
	export PATH=$PATH:$SCALA_HOME/bin
	export GOROOT=/usr/local/go # http://golang.org/doc/install
	export PATH=$PATH:$GOROOT/bin
	export PATH=$PATH:/usr/local/opt/node/bin #node/npm
	export PATH="$JAVA_HOME/bin:$PATH"
	export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
	# /PATH variable

	#####
	# other variables
	#####
	# JIRA Develpoment: 
	ATLAS_HOME='/usr/local/Cellar/atlassian-plugin-sdk/6.2.2/libexec'
	
else
	echo "Someone tried to load .bashrc again. Denied!"
fi
