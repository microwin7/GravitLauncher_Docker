#!/bin/bash
function sync_files {
    local filename=$1
    local src_dir="${PWD}/PUBLIC"
    local dest_dir="${PWD}"

    # Файл не найден в src_dir
    if [ ! -f "${src_dir}/${filename}" ]; then
        # Проверяем, существует ли файл в директории dest_dir
        if [ -f "${dest_dir}/${filename}" ]; then
            # Проверяем, является ли файл в dest_dir символической ссылкой
            if [ -L "${dest_dir}/${filename}" ]; then
                echo "Файл ${filename} является ссылкой в ${dest_dir}, ничего не делаем"
            else
                # Создаем резервную копию файла в dest_dir
                cp "${dest_dir}/${filename}" "${dest_dir}/${filename}.bak"
                echo "Создан backup файл ${dest_dir}/${filename}.bak"
                # Перемещаем файл в src_dir
                mv "${dest_dir}/${filename}" "${src_dir}/${filename}"
                # Создаем символическую ссылку в dest_dir на файл в src_dir
                ln -s "${src_dir}/${filename}" "${dest_dir}/${filename}"
                echo "Файл ${filename} перемещен в ${src_dir}, создана ссылка в ${dest_dir}"
            fi
        else
            echo "Файл ${filename} не найден в ${src_dir} и отсутствует в ${dest_dir}"
        fi
    fi
}
