#!/bin/bash


function help()
{
    echo "USAGE: git_log_filter.sh [start date] [end date]"
    echo "       e.g.  git_log_filter.sh 2008-10-01 2008-11-01"
    exit 1
}

if [ $# != 2 ];then
   help
fi


git log --pretty=format:'%C(bold yellow)%h%C(reset) %C(bold cyan)%ci%C(reset)%n    %s'  --since="$1" --before="$2" --stat --graph


