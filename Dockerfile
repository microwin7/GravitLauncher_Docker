FROM microwin7/gravitlauncher:base AS builder
# Устанавливаем рабочую директорию и переменную STARTUP по умолчанию
WORKDIR /app

# Copy the scripts directory to /opt/scripts in the container
COPY scripts /opt/scripts
# Make sure all scripts in /opt/scripts are executable
RUN chmod -R +x /opt/scripts/ && /opt/scripts/build/install_gosu.sh

FROM builder
LABEL author="microwin7"
LABEL maintainer="usa.microwin8@gmail.com"

# Создаем пользователя launcher и его домашнюю директорию
RUN useradd -m -s /bin/bash launcher

ENV STARTUP="java -Dlauncher.useSlf4j=true -jar LaunchServer.jar"

# Настройка порта
EXPOSE 9274

# Устанавливаем точку входа
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]
