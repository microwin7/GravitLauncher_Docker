#!/bin/bash
# При использовании на симлинк директориях, обязательно добавлять / в конце
function check_folder_empty {
    if [ ! -d $1 ]; then
        return 0 # Папка не существует
    fi
    if [ -z "$(find "$1" -maxdepth 0 -empty -printf "empty")" ]; then
        return 1 # Папка не пуста
    else
        return 0 # Папка пуста
    fi
}
