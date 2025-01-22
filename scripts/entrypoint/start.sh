#!/bin/bash

function start {
    if [ -f $PWD"/LaunchServer.json" ]; then
        START_COMMAND=${STARTUP}
    elif [ -f $PWD"/PUBLIC/LaunchServer.json" ]; then
        START_COMMAND=${STARTUP}
    else
        # Разделить строку на массив по пробелам
        IFS=' ' read -r -a command <<<"${STARTUP}"
        # Добавить аргумент после первого элемента массива
        first_element="${command[0]}"
        args="-Dlaunchserver.prepareMode=true"
        START_COMMAND="$first_element $args ${command[@]:1}"
    fi

    exec gosu ${runAsUser}:${runAsGroup} bash -c "${START_COMMAND}" "$@"
}
