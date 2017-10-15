FROM webdevops/php-apache-dev:7.1

MAINTAINER Emanuel Righetto <posta@emanuelrighetto.it>

# User and group permission
ENV APPLICATION_USER=www-data \
    APPLICATION_GROUP=www-data \
    APPLICATION_PATH=/var/www/html \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000
RUN usermod --non-unique --uid 1000 www-data
RUN groupmod --non-unique --gid 1000 www-data

# Commont tool
RUN apt-get update && apt-get install -y nano \
    spell \
    mysql-client \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# Install pecl-php-uploadprogress
RUN git clone https://github.com/php/pecl-php-uploadprogress /tmp/php-uploadprogress && \
		cd /tmp/php-uploadprogress && \
		phpize && \
		./configure --prefix=/usr && \
		make && \
		make install && \
		rm -rf /tmp/*

# Let's keep the house clean
RUN docker-image-cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

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
  echo ';;;;;;;;;; Sendmail ;;;;;;;;;;'; \
  echo 'sendmail_path = /usr/sbin/ssmtp -t'; \
  } >> /opt/docker/etc/php/php.ini

# Send mail conf
RUN echo "mailhub=mailcatcher:25\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

# Install Drush for Drupal 7 backward compatibility
RUN wget http://files.drush.org/drush.phar \
	  && chmod +x drush.phar \
	  && mv drush.phar /usr/local/bin/drush

# Apache conf
ENV WEB_DOCUMENT_ROOT=/var/www/html/web
RUN a2dismod autoindex -f
RUN rm /var/www/html/index.html

# Exposing ports
EXPOSE 80 443 9000

# Default work dir
WORKDIR "/var/www/html"
