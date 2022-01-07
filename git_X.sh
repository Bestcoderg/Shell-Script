#Author : Bestcoderg
#Date : 2021/09/24
#Usage : A convenient script to handle project git operation,
#           put this script into the same directory as roserver
#detail : You can use this scrip like this: ./git_X.sh <operations> <params> 
#           $<operations> means operations you wish to execut.
#           $<params> used when your operation needs param,such as ./git_X.sh checkout <branch_name>
#           your operaions could be connected by '/', which means you need to do multiple opreations at once
#-----------------------------------------------------------------------------------------------
#!/bin/bash

# 填入文件名/相对路径
DIRS_NAME=("config" "rogamelibs" "roserver" )
# 操作符优先级
DEFAULT_OPERATIONS=("clean" "fetch" "checkout" "pull" "gc" "newbranch" "syncorigin")
# ---- 请定义你的快捷指令 ----
DEFINE_CMDS=("reset" "setto" "neworigin")
reset=clean/pull
setto=fetch/checkout/pull
neworigin=newbranch/syncorigin
# ----------------------------
AUTO_REBASE=true

# region: functions
RO_DIR=$(pwd)
# 当前所在分支名
function current_branch() {
    local folder="$(pwd)"
    [ -n "$1" ] && folder="$1"
    [ ! -d $folder ] && return 233
    git -C "$folder" rev-parse --abbrev-ref HEAD | grep -v HEAD || \
    git -C "$folder" describe --exact-match HEAD || \
    git -C "$folder" rev-parse HEAD
}

# 确认所输入分支名是否存在本地分支
function check_branch_local(){
    [ ! -d $1 ] && return 233
    [ -z "$2" ] && return 233
    git -C "$1" rev-parse --verify $2 >/dev/null 2>&1 
}

# 确认所输入分支名是否存在origin分支
function check_branch_origin(){
    [ ! -d $1 ] && return 233
    [ -z "$2" ] && return 233
    git -C "$1" rev-parse --verify origin/$2 >/dev/null 2>&1 
}

# 是否是合法操作
function check_operation()
{
    [ -z "$1" ] && return 233
    for op_v in ${DEFAULT_OPERATIONS[@]}
    do
        [ $op_v = $1 ] && return 0
    done
    return 1
}

# 确认输入的参数是否是正确的
function check_params()
{
    local params=$1
    local operations=(${params//\// })
    for pa_v in ${operations[@]}
    do 
        check_operation $pa_v
        if [ $? -ne 0 ];then
            echo -e "\033[46;31;5m 输入了非法的参数: $pa_v \033[0m"
            return 1
        fi
    done
    return 0
}

function git_pull()
{
    if [ $# -ne 1 ];then
        echo -e "\033[46;31;5m ERROR: Wrong param \033[0m" 
        return 
    fi
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5m ERROR: Directory not Exist: $1 \033[0m"
        return
    fi


    local branch_name=`current_branch $1`
    echo -e "\033[44;33m INFO: git pull --rebase, DIR=$1; Branch=$branch_name \033[0m"
    #git -C $1 pull --rebase origin $branch_name:$branch_name
    git -C $1 fetch --progress --prune --recurse-submodules=no origin
    git -C $1 rebase origin/$branch_name
    if [[ $? -ne 0 ]] && [[ $AUTO_REBASE =~ "true" ]];then #rebase fail -> auto stash
        git -C $1 stash push --message "X_script automatic stash on Pull --rebase."
        git -C $1 rebase origin/$branch_name
        git -C $1 stash pop --index stash@{0}
    fi
}

function git_pull_all()
{
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_pull $dirv_
    done
}

function git_checkout()
{
    if [ $# -ne 2 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
    
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5mERROR: Directory not Exist: $1 \033[0m"
        return
    fi

    check_branch_local $1 $2
    # 如果存在本地分支，直接切出
    if [ $? -eq 0 ];then
        local branch_name=`current_branch $1`
        echo -e "\033[44;33m INFO: git checkout local_branch, DIR=$1; Branch=$2 \033[0m"
        git -C $1 checkout $2
    else 
        check_branch_origin $1 $2
        # 本地分支不存在此分支,但已经从远端拉到此分支
        if [ $? -eq 0 ];then
            echo -e "\033[44;33m INFO: git checkout origin_branch, DIR=$1; Branch=$2 \033[0m"
            git -C $1 checkout -b $2 origin/$2
        else
            echo -e "\033[46;31;5mERROR: 不存在名为$2的分支, DIR=$1 \033[0m"
        fi
    fi
} 

function git_checkout_all()
{
    if [ $# -ne 1 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
   
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_checkout $dirv_ $1
    done
}

function git_fetch ()
{
    if [ $# -ne 1 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5mERROR: Directory not Exist: $1 \033[0m"
        return
    fi

    echo -e "\033[44;33m INFO: git fetch, DIR=$1 \033[0m"
    git -C $1 fetch --all
}

function git_fetch_all ()
{
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_fetch $dirv_
    done
}

function git_clean()
{
    if [ $# -ne 1 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5mERROR: Directory not Exist: $1 \033[0m"
        return
    fi

    echo -e "\033[44;33m INFO: git clean, DIR=$1 \033[0m"
    git -C $1 checkout .
    git -C $1 clean -df
}

function git_clean_all()
{
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_clean $dirv_
    done
}

function git_gc()
{
    if [ $# -ne 1 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5mERROR: Directory not Exist: $1 \033[0m"
        return
    fi

    echo -e "\033[44;33m INFO: git GC, DIR=$1 \033[0m"
    git -C $1 gc 
}

function git_gc_all()
{
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_gc $dirv_
    done
}

function git_newbranch()
{
    if [ $# -ne 2 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
    
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5mERROR: Directory not Exist: $1 \033[0m"
        return
    fi

    # 如果存在本地/远程分支，则提示操作失败
    check_branch_local $1 $2
    if [ $? -eq 0 ];then
        echo -e "\033[46;31;5mERROR: Branch: $2 has Existed in $1 as Local Branch! \033[0m"
        return 
    fi
    check_branch_origin $1 $2
    if [ $? -eq 0 ];then
        echo -e "\033[46;31;5mERROR: Branch: $2 has Existed in $1 as Origin Branch! \033[0m"
        return
    fi
    
    git -C $1 checkout -b $2
}

function git_newbranch_all()
{
    if [ $# -ne 1 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
   
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_newbranch $dirv_ $1
    done
}

function git_syncorigin()
{
    if [ $# -ne 1 ]
    then
        echo -e "\033[46;31;5mERROR: Wrong param \033[0m" 
        return 
    fi
    if [ ! -d $1 ];then
        echo -e "\033[46;31;5mERROR: Directory not Exist: $1 \033[0m"
        return
    fi

    local branch_name=`current_branch $1`
    echo -e "\033[44;33m INFO: git sync Branch:$branch_name to Origin, DIR=$1 \033[0m"
    git -C $1 push origin $branch_name
    git -C $1 branch --set-upstream-to=origin/$branch_name $branch_name
}

function git_syncorigin_all()
{
    for dirv in ${DIRS_NAME[@]}
    do
        local dirv_=$RO_DIR/$dirv
        git_syncorigin $dirv_
    done
}

# region: script body
if [ $# -eq 0 ];then 
    echo -e "请输入参数(fetch/checkout/pull/clean/gc/newbranch/syncorigin)"
    echo -e "输入 \033[33;33;5m--help\033[0m 获取帮助"
    exit 0
fi
if [ $1 = "--help" ];then
    echo -e "请输入操作符(fetch/checkout/pull/clean/gc/newbranch/syncorigin)"
    echo -e "或是输入快捷命令："
    for qv in ${DEFINE_CMDS[@]}
    do
        eval echo "$qv = \$$qv"
    done
    exit 0
fi

params=$1
for vcx in ${DEFINE_CMDS[@]}
do
    if [ $1 = $vcx ];then
        eval params=\$$vcx
    fi
done

check_params $params
[ $? -ne 0 ] && exit 0

opreations=(${params//\// })
for v in ${DEFAULT_OPERATIONS[@]}
do 
    if [[ $params =~ $v ]];then 
        echo -e "\033[33;33;5m Operation $v executed \033[0m"
        git_${v}_all $2
    fi
done

