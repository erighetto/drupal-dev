FROM webdevops/php-apache-dev:7.2

# Environment variables
ENV APPLICATION_PATH=/var/www/html \
    WEB_DOCUMENT_ROOT=/var/www/html/web

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

# Set recommended PHP.ini settings
RUN {  \
  echo ';;;;;;;;;; General ;;;;;;;;;;'; \
  echo 'memory_limit = 1024M'; \
  echo 'max_input_vars = 5000'; \
  echo 'upload_max_filesize = 64M'; \
  echo 'post_max_size = 64M'; \
  echo 'max_execution_time = 6000'; \
  echo 'date.timezone = Europe/Rome'; \
  echo 'xdebug.remote_host = "host.docker.internal"'; \
  echo 'xdebug.remote_autostart = 1'; \
  echo 'xdebug.remote_connect_back = 0'; \
  echo 'xdebug.remote_enable = 1'; \
  echo 'xdebug.remote_handler = "dbgp"'; \
  echo 'xdebug.remote_port = 9000'; \
  echo ' '; \
  } >> /opt/docker/etc/php/php.ini

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
      echo 'if [ -f ${APPLICATION_PATH}/.aliases ]; then'; \
      echo '    source ${APPLICATION_PATH}/.aliases'; \
      echo 'fi'; \
      echo ' '; \
      echo '# Add terminal config.'; \
      echo 'stty rows 80; stty columns 160;'; \
    } >> ~/.bashrc

# Container must start as root user
USER root

# Default work dir
WORKDIR ${APPLICATION_PATH}
