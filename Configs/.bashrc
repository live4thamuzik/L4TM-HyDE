#
# ~/.bashrc
#

fastfetch

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -la --color=auto'
alias cat='bat --paging=never'
PS1='[\u@\h \W]\$ '

eval "$(oh-my-posh init bash --config ~/oh-my-posh/themes/clean-detailed.omp.json)"

#export PATH="$PATH:/home/lt4m.local/bin"
