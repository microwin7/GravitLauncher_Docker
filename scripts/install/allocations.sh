#!/bin/bash
# LaunchServer.jar | "ServerWrapper.jar" "PUBLIC/" |
function wget_put {
    local repo=$1
    local filename=$2
    local folder="${PWD}/$3"
    if [ ! -d ${folder} ]; then
        mkdir -p ${folder}
    fi
    local link="https://github.com/GravitLauncher/${repo}/releases/latest/download/${filename}"
    printf "Скачивание $filename из репозитория: $repo, ветка: master, по ссылке: $link в папку: ${folder}\n"
    wget -q -P ${folder} "$link"
}
# "LauncherModules.zip" "modules_all" | "LaunchServerModules.zip" "modules_all" | runtime.zip "runtime"
function wget_unzip_put {
    local repo="$1"
    local filename="$2"
    local folder="${PWD}/$3"
    local branch="$4"
    : ${branch:="master"}
    if [ ! -d ${folder} ]; then
        mkdir -p ${folder}
    fi
    if [ $branch == "master" ]; then
        local link="https://github.com/GravitLauncher/${repo}/releases/latest/download/${filename}"
        printf "Скачивание $filename из репозитория: $repo, ветка: master, по ссылке: $link\n"
        wget -qO- "$link" | bsdtar -xf- --no-same-owner --no-same-permissions -C ${folder}
    else
        local link="https://nightly.link/GravitLauncher/${repo}/workflows/push/${branch}/${repo}.zip"
        printf "Скачивание из репозитория $repo, ветка: ${branch}, по ссылке: $link\n"
        wget -qO- "$link" | bsdtar -xf- --no-same-owner --no-same-permissions -C ${folder}
    fi
}

function rebase {
    local folder="${PWD}/$2"
    if [ ! -d ${folder} ]; then
        mkdir -p ${folder}
    fi
    mv ${PWD}/$1 $folder
}

function unzip_rebase {
    local folder="${PWD}/$2"
    if [ ! -d ${folder} ]; then
        mkdir -p ${folder}
    fi
    unzip $1 -d $folder
}
