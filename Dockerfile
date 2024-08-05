FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем необходимые утилиты и ключи Temurin JDK
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        ARCH_LINK="x64" && ARCH_PATH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ARCH_LINK="aarch64" && ARCH_PATH="arm64"; \
    else \
        echo "Unsupported architecture" && exit 1; \
    fi && \
    apt-get update && \
    apt-get install -y \
    gnupg2 \
    wget \
    apt-transport-https \
    unzip \
    curl \
    openssh-server \
    git \
    osslsigncode \
    jq \
    iproute2 \
    libarchive-tools && \
    mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print $2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y temurin-21-jdk && \
    wget https://download2.gluonhq.com/openjfx/22.0.2/openjfx-22.0.2_linux-${ARCH_LINK}_bin-jmods.zip && \
    unzip openjfx-22.0.2_linux-${ARCH_LINK}_bin-jmods.zip && \
    cp javafx-jmods-22.0.2/* /usr/lib/jvm/temurin-21-jdk-${ARCH_PATH}/jmods && \
    rm -r javafx-jmods-22.0.2 && \
    rm -rf openjfx-22.0.2_linux-${ARCH_LINK}_bin-jmods.zip

# Установка локалей

RUN apt-get install -y locales && locale-gen ru_RU.UTF-8
ENV LANGUAGE=ru_RU.utf8 \
    LANG=ru_RU.utf8 \
    LC_ALL=ru_RU.utf8
RUN update-locale LANG=ru_RU.UTF-8 LC_ALL=ru_RU.UTF-8
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Устанавливаем переменные окружения обратно в стандартное значение
ENV DEBIAN_FRONTEND=dialog
