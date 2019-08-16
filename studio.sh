#!/bin/bash

BLACK="\033[01;30m"
MAGENTA="\033[1;31m"
ORANGE="\033[1;33m"
GREEN="\033[1;32m"
PURPLE="\033[1;35m"
WHITE="\033[1;37m"
BOLD=""
RESET="\033[m"

_error_exit() {
    echo >&2 -e "${MAGENTA}${BOLD}"
    echo >&2 "Studio Crashing: $@"
    echo >&2 -e "${RESET}"
    exit 1
}

_append_once() {
    grep -qxF "${2}" "${1}" || echo "${2}" >> "${1}"
}


## configure home directory
HOME="/src"
cd "${HOME}"


## install git and verify clean environmental repository
hab pkg binlink core/git

STUDIO_HEAD="$(git rev-parse --verify HEAD^{commit} 2>/dev/null )"
test -z "${STUDIO_HEAD}" && _error_exit "No git HEAD detected, ensure the studio is launched within an initialized git repository with at least one commit"
test -z "$(git status --porcelain)" || _error_exit "You have uncommited changes, commit or clear any changes and start the studio in a clean working tree"


## configure git environment
STUDIO_GIT_DIR="$(git rev-parse --git-dir)"

export GIT_CONFIG="/hab/cache/.gitconfig"
STUDIO_USER_NAME=`git config user.name`
STUDIO_USER_EMAIL=`git config  user.email`
STUDIO_USER_DIRTY=""

if [ -z "${STUDIO_USER_NAME}" ]; then
    [ -z "${STUDIO_USER_DIRTY}" ] && echo
    read -p "Your full name for git commits: " STUDIO_USER_NAME
    STUDIO_USER_DIRTY=1
fi

if [ -z "${STUDIO_USER_EMAIL}" ]; then
    [ -z "${STUDIO_USER_DIRTY}" ] && echo
    read -p "Your email address for git commits: " STUDIO_USER_EMAIL
    STUDIO_USER_DIRTY=1
fi

if [ -n "${STUDIO_USER_DIRTY}" ]; then
    read -p "Save git user ${STUDIO_USER_NAME} <${STUDIO_USER_EMAIL}> (y/n)? " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || _error_exit

    git config user.name "${STUDIO_USER_NAME}"
    git config user.email "${STUDIO_USER_EMAIL}"
fi

export GIT_AUTHOR_NAME="${STUDIO_USER_NAME}"
export GIT_AUTHOR_EMAIL="${STUDIO_USER_EMAIL}"
export GIT_COMMITTER_NAME="${STUDIO_USER_NAME}"
export GIT_COMMITTER_EMAIL="${STUDIO_USER_EMAIL}"

_append_once "${STUDIO_GIT_DIR}/info/exclude" "/.bash_history"
_append_once "${STUDIO_GIT_DIR}/info/exclude" "/.viminfo"


## configure hab environment
export HAB_STUDIO_SUP="false"


## configure shell UX
_studio_commit() {
    echo "${STUDIO_HEAD}"
}

_studio_install_prompt() {
    if [ -z "${_STUDIO_PROMPT_INSTALLED}" ]; then
        _STUDIO_PROMPT_INSTALLED=1
        PS1='\[\e[0;32m\][\[\e[0;36m\]\#\[\e[0;32m\]]${HAB_STUDIO_BINARY+[\[\e[1;31m\]HAB_STUDIO_BINARY\[\e[0m\]]}[$(_studio_commit):\[\e[0;35m\]\w\[\e[0;32m\]:\[\e[1;37m\]`echo -n $?`\[\e[0;32m\]]\$\[\e[0m\] '
    fi

    pushd "${HOME}" > /dev/null
    if [ -n "$(git status --porcelain)" ]; then
        git add --all
        git commit -m "$(history | tac | cut -c 8-)"
        history -a
        history -c
    fi
    popd > /dev/null

    STUDIO_HEAD="$(git rev-parse --short HEAD)"
}
PROMPT_COMMAND="_studio_install_prompt"


## configure shell history
export HISTFILE="/hab/cache/.bash_history"
history -c


## all done, print welcome
STUDIO_PRETTY_FORMAT='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
echo
echo "Studio ready! Recent commits:"
git -c color.ui=always log --graph --pretty=format:"${STUDIO_PRETTY_FORMAT}" --abbrev-commit | sed 's/^/  /'
echo
echo
