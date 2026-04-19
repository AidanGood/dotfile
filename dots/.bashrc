
# Non-interactive shell return 
[[ $- != *i* ]] && return

HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups   # ignore duplicates and lines starting with space
HISTTIMEFORMAT="%F %T  "
shopt -s histappend                # append, don't overwrite history file
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"  # flush history after each command

shopt -s globstar      # ** matches across directories
shopt -s checkwinsize  # update LINES/COLUMNS after each command
shopt -s cdspell       # auto-correct minor typos in cd
shopt -s autocd        # type a directory name to cd into it
shopt -s cmdhist       # save multi-line commands as single history entry

# ~/.local/bin for user scripts and pipx-installed tools
export PATH="${HOME}/.local/bin:${PATH}"

if [[ -f "${HOME}/.bash_aliases" ]]; then
    source "${HOME}/.bash_aliases"
fi

export EDITOR="vim"
export VISUAL="vim"
export PAGER="less"
export LESS="-R --quit-if-one-screen"

# C development
export CC="clang"
export CXX="clang++"
