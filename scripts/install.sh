#!/bin/bash
mkdir -p ${PWD}/PUBLIC
# Включение всех скриптов из /opt/scripts/install
for script in /opt/scripts/install/*.sh; do
    source "$script"
done
# Включение всех скриптов из /opt/scripts/all
for script in /opt/scripts/all/*.sh; do
    source "$script"
done
folders=(".keys" "config" "logs" "modules" "launcher-modules" "profiles" "truststore" "updates" "launcher-pack" "runtime" "proguard")
# Цикл по каждой папке
for folder in "${folders[@]}"; do
    sync_directories "$folder"
done
chmod 700 "${PWD}/PUBLIC/.keys"

: "${LAUNCHER_BRANCH:="master"}"
: "${RUNTIME_BRANCH:="master"}"

if [ "$LAUNCHER_BRANCH" == "master" ]; then
    if [ ! -f "$PWD/LaunchServer.jar" ]; then
        wget_put "Launcher" "LaunchServer.jar" ""
    fi
    if [ ! -f "$PWD/PUBLIC/ServerWrapper.jar" ]; then
        wget_put "Launcher" "ServerWrapper.jar" "PUBLIC/"
    fi
    if check_folder_empty "libraries" ||
        check_folder_empty "launcher-libraries"; then
        wget_unzip_put "Launcher" "libraries.zip" ""
    fi
    if check_folder_empty "modules_all"; then
        wget_unzip_put "Launcher" "LauncherModules.zip" "modules_all"
        wget_unzip_put "Launcher" "LaunchServerModules.zip" "modules_all"
        
        wget_put "LauncherPrestarter" "Prestarter.exe" "./PUBLIC/"
        ln -s "PUBLIC/Prestarter.exe" Prestarter.exe
        wget_put "LauncherPrestarter" "Prestarter_module.jar" "modules_all"
    fi
else
    if
        [ ! -f "$PWD/LaunchServer.jar" ] ||
            [ ! -f "$PWD/PUBLIC/ServerWrapper.jar" ] ||
            check_folder_empty "libraries" ||
            check_folder_empty "launcher-libraries" ||
            check_folder_empty "modules_all"
    then
        wget_unzip_put Launcher "" tmp $LAUNCHER_BRANCH
        if [ ! -f "$PWD/LaunchServer.jar" ]; then
            rebase tmp/LaunchServer.jar
        fi
        if [ ! -f "$PWD/PUBLIC/ServerWrapper.jar" ]; then
            rebase tmp/ServerWrapper.jar "PUBLIC/"
        fi
        if check_folder_empty "libraries" ||
            check_folder_empty "launcher-libraries"; then
            unzip_rebase tmp/libraries
        fi
        if check_folder_empty "modules_all"; then
            rebase "tmp/modules/*" modules_all
        fi
        # rm -rf tmp
    fi
fi

if [ "$RUNTIME_BRANCH" == "master" ]; then
    if [ ! -f "$PWD/launcher-modules/JavaRuntime.jar" ]; then
        wget_put "LauncherRuntime" "JavaRuntime_lmodule.jar" "launcher-modules"
        mv "launcher-modules/JavaRuntime_lmodule.jar" "launcher-modules/JavaRuntime.jar"
    fi
    if check_folder_empty "runtime/"; then
        wget_unzip_put "LauncherRuntime" "runtime.zip" "runtime"
    fi
else
    if [ ! -f "$PWD/launcher-modules/JavaRuntime.jar" ] ||
        check_folder_empty "runtime/"; then
        wget_unzip_put LauncherRuntime "" tmp $RUNTIME_BRANCH
        if [ ! -f "$PWD/launcher-modules/JavaRuntime.jar" ]; then
            rebase tmp/JavaRuntime_lmodule.jar launcher-modules
            mv "launcher-modules/JavaRuntime_lmodule.jar" "launcher-modules/JavaRuntime.jar"
        fi
        if check_folder_empty "runtime/"; then
            unzip_rebase tmp/runtime.zip runtime
        fi
        # rm -rf tmp
    fi
fi

# Список папок для синхронизации
libraries_folders=("libraries" "launcher-libraries" "launcher-libraries-compile")
# Fix отсутствующей папки в libraries.zip
mkdir -p "${PWD}/launcher-libraries-compile"
# Цикл по каждой папке
for libraries_folder in "${libraries_folders[@]}"; do
    link_libraries "$libraries_folder"
done
