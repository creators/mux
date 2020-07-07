#!/usr/bin/env bash

# _this=$(readlink -f "${BASH_SOURCE[0]}") #linux
_this=$(readlink "${BASH_SOURCE[0]}") #macos
_dir=${_this%/*}

: "${INVENTORY:=$_dir/prj}"

declare -A __o

main () {
    # mapfile -t files < <(find "$INVENTORY" -type f) #linux
    # parse_yaml $files
    local project="${1:-base}"

    if ! $(tmux has-session -t=$project 2>/dev/null); then
        new "$project"
    fi

    attach "$project"
}

attach() {
    local project="$1"
    local cmd="attach-session"

    if [ ! -z "$TMUX" ]; then
        cmd="switch-client"
    fi

    tmux $cmd -t $project
}

new() {
    local project="$1"

    tmux new-session -d -s $project
    source $INVENTORY/$project.sh
}

# https://stackoverflow.com/a/21189044
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

___printlist() {
    ERM "LIST"
    mapfile -t files < <(find "$INVENTORY" -type f) #linux
    ERM $files
    exit
}

___printhelp() {

cat << 'EOB' >&2
mux - tmux project manager

SYNOPSIS
    --------
    mux PROJECT
    mux --list|-l
    mux --help|-h
    mux --version|-v

OPTIONS
-------
    --list|-l
    Show list avalable projects.

    --help|-h
    Show help and exit.

    --version|-v
    Show version and exit.
EOB
}

___printversion() {

cat << 'EOB' >&2
mux - version: 2020.06.26.0
updated: 2020-06-24 by Remchi
EOB
}

set -E
trap '[ "$?" -ne 77 ] || exit 77' ERR

ERM(){ >&2 echo "$*"; }
ERR(){ >&2 echo "[WARNING]" "$*"; }
ERX(){ >&2 echo "[ERROR]" "$*" && exit 77 ; }

# eval set --"$(getopt --name "mux" \
#   --options "lhv" \
#   --longoptions "list,help,version" \
#   -- "$@"
# )" #linux
eval set --"$(getopt "lhv" $*)" #maxos

while true; do
  case "$1" in
    --list      | -l ) __o[list]=1 ;;
    --help      | -h ) __o[help]=1 ;;
    --version   | -v ) __o[version]=1 ;;
    -- ) shift ; break ;;
    *  ) break ;;
  esac
  shift
done

if [[ ${__o[list]:-} = 1 ]]; then
  ___printlist
  exit
elif [[ ${__o[help]:-} = 1 ]]; then
  ___printhelp
  exit
elif [[ ${__o[version]:-} = 1 ]]; then
  ___printversion
  exit
fi

main "${@:-}"
