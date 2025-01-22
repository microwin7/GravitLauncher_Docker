#!/bin/bash
function setup_env {
    local LaunchServerConfigPath=$PWD"/PUBLIC/LaunchServer.json"

    # Функция для проверки валидности адреса
    function is_valid_address {
        local address="$1"
        if [[ "$(echo "$address" | cut -d '/' -f 1)" =~ ^[0-9a-zA-Z.-]+(:[0-9]+)?$ ]]; then
            return 0
        else
            return 1
        fi
    }

    if [ -f "$LaunchServerConfigPath" ]; then
        echo "Файл $LaunchServerConfigPath найден, выполняется настройка..."

        # Приведение HTTP_PROTOCOL к нижнему регистру
        http_protocol=${NETTY_HTTP_PROTOCOL,,}
        if [[ "$http_protocol" != "http" && "$http_protocol" != "https" ]]; then
            http_protocol="http"
        fi
        # Определение веб-сокет протокола на основе http_protocol
        if [[ "$http_protocol" == "https" ]]; then
            ws_protocol="wss"
        else
            ws_protocol="ws"
        fi
        # Проверка валидности адреса
        if ! is_valid_address "$WS_ADDRESS"; then
            WS_ADDRESS="$(ip route get 1 | awk '{print $(NF-2);exit}'):9275"
        fi
        # Проверка валидности адреса
        if ! is_valid_address "$URL_ADDRESS"; then
            URL_ADDRESS="$WS_ADDRESS"
        fi

        # Формирование URL
        launcher_url="${http_protocol}://${URL_ADDRESS}/$(urlencode "$BINARY_NAME").jar"
        download_url="${http_protocol}://${URL_ADDRESS}/%dirname%/"
        launcher_exe_url="${http_protocol}://${URL_ADDRESS}/$(urlencode "$BINARY_NAME").exe"
        ws_address="${ws_protocol}://${WS_ADDRESS}/api"

        # Заменяем значения в JSON-файле с помощью jq
        jq --arg projectName "$PROJECT_NAME" \
            --arg binaryName "$BINARY_NAME" \
            --arg env "$ENV" \
            --argjson fileServerEnabled "$NETTY_FILE_SERVER_ENABLED" \
            --argjson ipForwarding "$NETTY_IP_FORWARDING" \
            --argjson disableWebApiInterface "$NETTY_DISABLE_WEB_API_INTERFACE" \
            --argjson showHiddenFiles "$NETTY_SHOW_HIDDEN_FILES" \
            --arg launcherURL "$launcher_url" \
            --arg downloadURL "$download_url" \
            --arg launcherEXEURL "$launcher_exe_url" \
            --arg address "$ws_address" \
            '
            .projectName = $projectName |
            .binaryName = $binaryName |
            .env = $env |
            .netty.fileServerEnabled = $fileServerEnabled |
            .netty.ipForwarding = $ipForwarding |
            .netty.disableWebApiInterface = $disableWebApiInterface |
            .netty.showHiddenFiles = $showHiddenFiles |
            .netty.launcherURL = $launcherURL |
            .netty.downloadURL = $downloadURL |
            .netty.launcherEXEURL = $launcherEXEURL |
            .netty.address = $address
            ' "$LaunchServerConfigPath" > "${LaunchServerConfigPath}.tmp" && mv "${LaunchServerConfigPath}.tmp" "$LaunchServerConfigPath"

        echo "Настройка LaunchServer.json завершена."
    else
        echo "Файл $LaunchServerConfigPath не найден."
    fi
}
# Функция для URL-кодирования строки с использованием Python
urlencode() {
    local input="$1"
    local output=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$input'''))")
    echo "$output"
}