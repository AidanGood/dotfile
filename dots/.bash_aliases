
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

if command -v eza &>/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --git --group-directories-first'
    alias lt='eza --tree --level=2'
    alias llt='eza -lah --tree --level=2'
else
    # Fallback to system ls with colour
    alias ls='ls --color=auto'
    alias ll='ls -lah'
fi

cd() {
    builtin cd "$@" && ll
}

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias less='bat --paging=always'
fi

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gr='git review'
alias gd='git diff'
alias gds='git diff --staged'

alias py='python3'
alias pip='pip3'
# Create and activate a venv in the current directory
alias venv='python3 -m venv .venv && source .venv/bin/activate && echo "venv activated"'
alias activate='source .venv/bin/activate'

alias grep='grep --color=auto'
alias path='echo $PATH | tr ":" "\n"'   # print PATH entries one per line
