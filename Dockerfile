FROM webdevops/php-apache-dev:7.2

# Environment variables
ENV APPLICATION_PATH=/var/www/html \
    WEB_DOCUMENT_ROOT=/var/www/html/web \
    PHP_DEBUGGER=xdebug \
    XDEBUG_REMOTE_CONNECT_BACK=1 \
    XDEBUG_REMOTE_AUTOSTART=1 \
    XDEBUG_REMOTE_HOST=host.docker.internal \
    XDEBUG_REMOTE_PORT=9000 \
    PHP_MEMORY_LIMIT=1024M \
    PHP_DATE_TIMEZONE=Europe/Rome

# Commont tools
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
      sudo \
      gettext \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      mysql-client \
      nano

# Reconfigure GD
RUN docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/

# Add application user to sudoers
RUN usermod -aG sudo ${APPLICATION_USER} \
    && echo "${APPLICATION_USER} ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${APPLICATION_USER}

# Finalize installation and clean up
RUN docker-run-bootstrap \
    && docker-image-cleanup \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Change user
USER ${APPLICATION_USER}

# Composer parallel install plugin
RUN composer global require hirak/prestissimo

# Add bash aliases and terminal conf
RUN { \
      echo ' '; \
      echo '# Add bash aliases.'; \
      echo 'if [ -f $APPLICATION_PATH/.aliases ]; then' | envsubst; \
      echo '    source $APPLICATION_PATH/.aliases' | envsubst; \
      echo 'fi'; \
      echo ' '; \
      echo '# Add terminal config.'; \
      echo 'stty rows 80; stty columns 160;'; \
    } >> ~/.bashrc

# Container must start as root user
USER root

# Default work dir
WORKDIR ${APPLICATION_PATH}
