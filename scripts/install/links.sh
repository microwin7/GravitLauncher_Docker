#!/bin/bash
function sync_directories {
    local folder=$1
    local src_dir="${PWD}/PUBLIC"
    local dest_dir="${PWD}"

    # Проверяем, существует ли папка в директории src_dir
    if [ ! -d "${src_dir}/${folder}" ]; then
        # Папка не существует, создаем ее
        mkdir -p "${src_dir}/${folder}"
        echo "Папка ${folder} создана в ${src_dir}"
    fi

    # Создаем символическую ссылку в директории dest_dir
    if [ ! -L "${dest_dir}/${folder}" ]; then
        ln -s "${src_dir}/${folder}" "${dest_dir}/${folder}"
        echo "Символическая ссылка на папку ${folder} создана в ${dest_dir}"
    fi
}
function link_libraries {
    local folder=$1
    local src_dir="${PWD}/PUBLIC/libraries"
    local dest_dir="${PWD}/${folder}/PUBLIC"

    # Проверяем, существует ли папка в директории src_dir
    if [ ! -d "${src_dir}/${folder}" ]; then
        # Папка не существует, создаем ее
        mkdir -p "${src_dir}/${folder}"
        echo "Создание папки ${src_dir}/${folder}"
    fi
    # Создаем символическую ссылку в директории dest_dir
    if [ ! -L ${dest_dir} ]; then
        ln -sf "${src_dir}/${folder}" "${dest_dir}"
        echo "Создание символической ссылки из: ${src_dir}/${folder} в: ${dest_dir}"
    fi
}