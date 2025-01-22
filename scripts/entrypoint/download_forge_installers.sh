#!/bin/bash
# Функция для получения версии Forge
get_forge_version() {
    local version="$1"
    local json_data="$2"
    local forge_version=$(echo "$json_data" | jq -r --arg version "$version" '.promos[$version + "-latest"]')
    # local forge_version=$(echo "$json_data" | jq -r --arg version "$version" '.promos[$version + "-recommended"]')

    if [ -z "$forge_version" ]; then
        forge_version=$(echo "$json_data" | jq -r --arg version "$version" '.promos[$version + "-latest"]')
    fi

    echo "$forge_version"
}

# Функция для получения позиции версии в массиве promos
get_version_position() {
    local version="$1"
    local json_data="$2"
    local position=0

    for key in $(echo "$json_data" | jq -r '.promos | keys_unsorted[]'); do
        if [[ "$key" == "$version-latest" || "$key" == "$version-recommended" ]]; then
            echo "$position"
            return
        fi
        position=$((position + 1))
    done

    echo "-1"
}

# Функция для разбора переменной MIRROR_HELPER_INSTALLERS и скачивания недостающих файлов
download_forge_installers() {
    local installers_json="$1"
    local workspace_dir1="config/MirrorHelper/workspace/"
    local installers_dir="${workspace_dir1}installers"

    # Создание директории если она не существует
    if check_folder_empty "$workspace_dir1"; then
        echo "Ожидание создания папки ${workspace_dir1} ЛаунчСервером"
        return 1
    fi
    mkdir -p "$installers_dir"

    # Разбор переменной MIRROR_HELPER_INSTALLERS
    printf "Разбор переменной MIRROR_HELPER_INSTALLERS:\n$installers_json"

    # Получение данных о версиях
    json_data=$(curl -s https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json)
    if [[ $? -ne 0 ]]; then
        echo "Не удалось загрузить данные о версиях Forge"
        exit 1
    fi

    # Преобразуем JSON строку в нормальный формат
    for type in $(echo "$installers_json" | jq -r 'keys_unsorted[]'); do
        versions=$(echo "$installers_json" | jq -r --arg type "$type" '.[$type][]' | tr '\n' ' ')
        echo "Тип: $type | Версии: $versions"
        if [ "$type" == "FORGE" ]; then
            for version in $versions; do
                installer_file="${installers_dir}/forge-${version}-installer-nogui.jar"
                if [ ! -f "$installer_file" ]; then
                    echo "Файл ${installer_file} не найден. Загрузка..."

                    # Поиск нужной версии
                    forge_version=$(get_forge_version "$version" "$json_data")
                    if [ -z "$forge_version" ]; then
                        echo "Не удалось найти версию Forge для Minecraft $version"
                        exit 1
                    fi

                    # Получение позиции версии
                    version_position=$(get_version_position "$version" "$json_data")

                    # Формирование URL и скачивание
                    if [ "$version" == "1.7.10" ]; then
                        installer_url="https://mirror.gravit-support.ru/files/net/minecraftforge/forge/${version}-${forge_version}-${version}/forge-${version}-${forge_version}-${version}-installer.jar"
                    elif [ "$version" == "1.12.2" ]; then
                        # URL для получения информации о релизах
                        URL="https://api.github.com/repos/CleanroomMC/Cleanroom/releases"

                        # Получение JSON данных
                        response=$(curl -s "$URL")

                        # Проверка наличия новых релизов
                        if [[ $(echo "$response" | jq '. | length') -gt 0 ]]; then
                            # Получение нулевого элемента из релизов
                            latest_release=$(echo "$response" | jq '.[0]')

                            # Перебор массива assets и поиск инсталлеров
                            installer_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name | test("cleanroom-.*-installer.jar")) | .browser_download_url')

                            # Проверка наличия найденного инсталлер файла
                            if [[ -z "$installer_url" ]]; then
                                echo "Инсталлер CleanRoom $version не найден."
                                break
                            fi
                        else
                            echo "Нет доступных релизов CleanRoom $version"
                            break
                        fi
                    elif [ "$version_position" -le "$(get_version_position '1.10' "$json_data")" ]; then
                        installer_url="https://maven.minecraftforge.net/net/minecraftforge/forge/${version}-${forge_version}-${version}/forge-${version}-${forge_version}-${version}-installer.jar"
                    else
                        installer_url="https://maven.minecraftforge.net/net/minecraftforge/forge/${version}-${forge_version}/forge-${version}-${forge_version}-installer.jar"
                    fi

                    echo "Скачивание с URL: $installer_url"
                    curl -L -o "$installer_file" "$installer_url"
                    chown launcher:launcher "$installer_file"
                    if [[ $? -ne 0 ]]; then
                        echo "Не удалось скачать файл $installer_file"
                        exit 1
                    fi
                    echo "Файл $installer_file успешно скачан"
                else
                    echo "Файл ${installer_file} уже существует"
                fi
            done
        elif [ "$type" == "NEOFORGE" ]; then
            # https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge
            echo "NEOFORGE скачивание инсталлеров ВРЕМЕННО НЕ ПОДДЕРЖИВАЕТСЯ"
        fi
    done
}
