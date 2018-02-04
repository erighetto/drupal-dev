FROM webdevops/php-apache-dev:7.1

MAINTAINER Emanuel Righetto <posta@emanuelrighetto.it>

# Environment variables
ENV APPLICATION_USER=www-data \
    APPLICATION_GROUP=www-data \
    APPLICATION_PATH=/var/www/html \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000 \
    WEB_DOCUMENT_ROOT=/var/www/html/web

# User and group permission
RUN usermod --non-unique --uid 1000 www-data \
    && groupmod --non-unique --gid 1000 www-data

# Commont tools
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
      gettext \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng12-dev \
      mysql-client \
      nano

# Reconfigure GD
RUN docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/

# Install pecl-php-uploadprogress
RUN git clone https://github.com/php/pecl-php-uploadprogress /tmp/php-uploadprogress && \
      cd /tmp/php-uploadprogress && \
      phpize && \
      ./configure --prefix=/usr && \
      make && \
      make install && \
      rm -rf /tmp/*

# Let's keep the house clean
RUN docker-image-cleanup \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add bash aliases
RUN { \
      echo '# Add bash aliases.'; \
      echo 'if [ -f /var/www/html/.aliases ]; then'; \
      echo '    source /var/www/html/.aliases'; \
      echo 'fi'; \
    } >> /root/.bashrc

# Exposing ports
EXPOSE 80 443 9000

# Default work dir
WORKDIR "/var/www/html"

##########################################
#       Specific configurations
##########################################

# Set recommended PHP.ini settings
RUN {  \
  echo ';;;;;;;;;; General ;;;;;;;;;;'; \
  echo 'memory_limit = 1024M'; \
  echo 'max_input_vars = 5000'; \
  echo 'upload_max_filesize = 64M'; \
  echo 'post_max_size = 64M'; \
  echo 'max_execution_time = 6000'; \
  echo 'date.timezone = Europe/Rome'; \
  echo 'extension = uploadprogress.so'; \
  echo ' '; \
  } >> /opt/docker/etc/php/php.ini

# Install Drush for Drupal 7 backward compatibility
RUN wget http://files.drush.org/drush.phar \
	  && chmod +x drush.phar \
	  && mv drush.phar /usr/local/bin/globaldrush

