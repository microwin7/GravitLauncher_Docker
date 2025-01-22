#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
NC='\033[0m' # Без цвета

# Функция для обработки модулей
process_modules() {
    local env_var="$1"
    local postfix="$2"
    local target_dir="$3"

    # Получение значения переменной окружения
    local modules_var=$(eval echo \$$env_var)
    if [ -z "$modules_var" ]; then
        echo "Переменная окружения $env_var пуста или не существует"
        return
    fi

    # Установка IFS на запятую
    IFS=','

    # Разбор модулей из переменной окружения
    local modules=($modules_var)

    # Создание массива для существующих модулей
    declare -A env_modules
    for module in "${modules[@]}"; do
        env_modules["$(echo "$module" | tr -d '[:space:]')"]=1
    done

    # Проверка на наличие модулей в целевой директории
    for file in "$target_dir"/*.jar "$target_dir"/*.jar.disabled; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")
        if [[ "$filename" == *.jar.disabled ]]; then
            module_name="${filename%.jar.disabled}"
        else
            module_name="${filename%.jar}"
        fi

        # Переименование, если модуля нет в переменной окружения и он не JavaRuntime
        if [[ -z "${env_modules[$module_name]}" && "$module_name" != "JavaRuntime" ]]; then
            echo "Переименование $file в ${target_dir}/${module_name}.jar.disabled"
            mv "$file" "${target_dir}/${module_name}.jar.disabled"
        fi
    done

    # Обработка модулей из переменной окружения
    for module in "${!env_modules[@]}"; do
        local module_file="${PWD}/modules_all/${module}${postfix}.jar"
        local target_file="${target_dir}/${module}.jar"
        local disabled_file="${target_dir}/${module}.jar.disabled"

        # Дополнительная проверка для модуля LauncherGuard
        if [ "$module" == "LauncherGuard" ]; then
            local guard_dir="${PWD}/launcher-pack/guard"
            local guard_valid=false
            if [ -d "$guard_dir" ]; then
                while IFS= read -r -d '' subdir; do
                    if [ -n "$(find "$subdir" -maxdepth 1 -type f -name "*.exe" -print -quit)" ] &&
                        [ -n "$(find "$subdir" -maxdepth 1 -type f -name "*.dll" -print -quit)" ]; then
                        guard_valid=true
                        break
                    fi
                done < <(find "$guard_dir" -mindepth 1 -maxdepth 1 -type d -print0)
            fi
            if [ "$guard_valid" = false ]; then
                echo -e "${RED}Необходимо скомпилировать .exe и .dll бинарные файлы для LauncherGuard и поместить их в launcher-pack/guard/ директорию${NC}"
                echo -e "${RED}Посетите страницу исходного кода GravitGuard: https://github.com/GravitLauncher/GravitGuard${NC}"
                unset env_modules["LauncherGuard"]
                continue
            fi
        fi
        # Дополнительная проверка для модуля OpenSSLSignCode
        if [ "$module" == "OpenSSLSignCode" ]; then
            enabled=$(jq '.sign.enabled' LaunchServer.json)
            # Проверить значение в блоке if
            if [ "$enabled" != "true" ]; then
                echo -e "${RED}Правило для включения модуля OpenSSLSignCode требует, чтобы была включена подпись в '.sign.enabled' LaunchServer.json${NC}"
                unset env_modules["OpenSSLSignCode"]
                continue
            fi
        fi

        # Проверка наличия модуля в исходной папке
        if [ -f "$module_file" ]; then
            # Проверка на наличие отключенного модуля
            if [ -f "$disabled_file" ]; then
                echo "Включение модуля $disabled_file"
                mv "$disabled_file" "$target_file"
            elif [ ! -f "$target_file" ]; then
                echo "Копирование $module_file в $target_file"
                cp "$module_file" "$target_file"
            else
                echo "Файл $target_file уже существует"
            fi

            # Дополнительная проверка для модуля DiscordGame
            if [ "$module" == "DiscordGame" ]; then
                local discord_lib_dir="${PWD}/launcher-libraries/PUBLIC"
                local discord_lib_file="${discord_lib_dir}/discord-game-sdk4j-master-v0.1-g5cdac34-224.jar"
                if [ ! -f "$discord_lib_file" ]; then
                    echo "Загрузка зависимости для DiscordGame в $discord_lib_file"
                    mkdir -p "$discord_lib_dir"
                    curl -L -o "$discord_lib_file" "https://javadoc.jitpack.io/com/github/JnCrMx/discord-game-sdk4j/master-v0.1-g5cdac34-224/discord-game-sdk4j-master-v0.1-g5cdac34-224.jar"
                    if [ $? -eq 0 ]; then
                        echo "Зависимость для DiscordGame успешно загружена"
                    else
                        echo "Не удалось загрузить зависимость для DiscordGame"
                    fi
                else
                    echo "Зависимость для DiscordGame присутствует"
                fi
            fi
        else
            echo "Модуль $module не найден в $module_file"
        fi
    done

    # Восстановление IFS
    unset IFS
}
