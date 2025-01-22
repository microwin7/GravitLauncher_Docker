#!/bin/bash
# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

if [ ! -f "${PWD}/LaunchServer.json" ]; then
    export ADDRESS="127.0.0.1:9274"
    export PROJECTNAME=$PROJECT_NAME
fi


# Включение всех скриптов из /opt/scripts/entrypoint
for script in /opt/scripts/entrypoint/*.sh; do
    source "$script"
done
# Включение всех скриптов из /opt/scripts/all
for script in /opt/scripts/all/*.sh; do
    source "$script"
done

# The Dockerfile ENVs take precedence here, but defaulting for testing consistency
: "${UID:=1000}"
: "${GID:=1000}"

runAsUser=launcher
runAsGroup=launcher

if [[ -v UID ]]; then
    if [[ $UID != 0 ]]; then
        if [[ $UID != $(id -u launcher) ]]; then
            printf "Changing uid of launcher to $UID\n"
            usermod -u $UID launcher
        fi
    else
        runAsUser=root
    fi
fi

if [[ -v GID ]]; then
    if [[ $GID != 0 ]]; then
        if [[ $GID != $(id -g launcher) ]]; then
            printf "Changing gid of launcher to $GID\n"
            groupmod -o -g "$GID" launcher
        fi
    else
        runAsGroup=root
    fi
fi

if [[ -v GID ]]; then
    if [[ $GID != 0 ]]; then
        if [[ $GID != $(id -g launcher) ]]; then
            printf "Changing gid of launcher to $GID\n"
            groupmod -o -g "$GID" launcher
        fi
    else
        runAsGroup=root
    fi
fi

if  [ ! -f "$PWD/LaunchServer.jar" ] || \
    [ ! -f "$PWD/PUBLIC/ServerWrapper.jar" ] || \
    [ ! -d "$PWD/libraries" ] || \
    [ ! -d "$PWD/launcher-libraries" ] || \
    [ ! -d "$PWD/launcher-libraries-compile" ] || \
    [ ! -d "$PWD/modules_all" ] || \
    [ ! -f "$PWD/launcher-modules/JavaRuntime.jar" ] || \
    check_folder_empty "runtime/"; then
    printf "Начата установка ЛаунчСервера\n"
    /opt/scripts/install.sh
fi

# Проверка и копирование модулей для MODULES
process_modules "MODULES" "_module" "${PWD}/modules"

# Проверка и копирование модулей для LAUNCHER_MODULES
process_modules "LAUNCHER_MODULES" "_lmodule" "${PWD}/launcher-modules"

# Вызов функции для скачивания файлов
download_forge_installers "$MIRROR_HELPER_INSTALLERS"

# Список файлов для синхронизации
files=("LaunchServer.json" "log4j2.xml" "RuntimeLaunchServer.json")

# Цикл по каждому файлу
for file in "${files[@]}"; do
    sync_files "$file"
done

setup_env

printf "Changing ownership of $PWD to $UID ...\n"
chown -R ${runAsUser}:${runAsGroup} $PWD

printf "\033[1m\033[33mlauncher@gravitlauncher~ \e[1;35mMade by microwin7 for GravitLauncher Community\n"
printf "\033[1m\033[33mlauncher@gravitlauncher~ \e[1;34mhttps://gravitlauncher.com\n"
# Set environment variable that holds the Internal Docker IP
export INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}') && printf "ВАШ IP АДРЕС КОНТЕЙНЕРА: ${INTERNAL_IP}\n"

start
