FROM php:7-apache

MAINTAINER Emanuel Righetto <posta@emanuelrighetto.it>

RUN a2enmod rewrite

# Install the PHP extensions we need
RUN apt-get update && apt-get install -y \
	nano \
	git \
	wget \
	mysql-client \
	ssmtp \
	patch \
	unzip \
	openssh-server \
	libpng12-dev \
	libjpeg-dev \
	libpq-dev \
	libxml2-dev \
	libcurl3 \
	libcurl4-gnutls-dev \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mbstring opcache pdo pdo_mysql pdo_pgsql zip calendar json curl xml soap bcmath \
	&& pecl install xdebug \
	&& docker-php-ext-enable xdebug
	
# Install pecl-php-uploadprogress
RUN git clone https://github.com/php/pecl-php-uploadprogress /tmp/php-uploadprogress && \
        cd /tmp/php-uploadprogress && \
        phpize && \
        ./configure --prefix=/usr && \
        make && \
        make install && \
        echo 'extension=uploadprogress.so' > /usr/local/etc/php/conf.d/uploadprogress.ini && \
        rm -rf /tmp/*	

# Let's keep the house clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# See https://secure.php.net/manual/en/opcache.installation.php
RUN { \
  echo 'opcache.memory_consumption=128'; \
  echo 'opcache.interned_strings_buffer=8'; \
  echo 'opcache.max_accelerated_files=4000'; \
  echo 'opcache.revalidate_freq=60'; \
  echo 'opcache.fast_shutdown=1'; \
  echo 'opcache.enable_cli=1'; \
	} >> /usr/local/etc/php/conf.d/opcache-recommended.ini

# Set recommended PHP.ini settings
RUN {  \
  echo ';;;;;;;;;; General ;;;;;;;;;;'; \
  echo 'memory_limit = 512M'; \
  echo 'upload_max_filesize = 64M'; \
  echo 'post_max_size = 64M'; \
  echo 'max_execution_time = 600'; \
  echo 'date.timezone = Europe/Rome'; \
  echo 'error_reporting = E_ALL & ~E_NOTICE & ~E_WARNING'; \
  echo ' '; \
  echo ';;;;;;;;;; Sendmail ;;;;;;;;;;'; \
  echo 'sendmail_path = /usr/sbin/ssmtp -t'; \
  echo ' '; \
  echo ';;;;;;;;;; xDebug ;;;;;;;;;;'; \
  echo 'xdebug.remote_enable = 1'; \
  echo 'xdebug.idekey = "phpstorm"'; \
  echo 'xdebug.remote_host = 172.20.0.1'; \
  echo 'xdebug.remote_port = 9000'; \
  echo 'xdebug.remote_autostart = 0'; \
  echo 'xdebug.profiler_enable = 0'; \
  echo 'xdebug.remote_connect_back = 1'; \
  echo 'xdebug.max_nesting_level = 256'; \
  echo ';xdebug.remote_cookie_expire_time = -9999'; \
	} >> /usr/local/etc/php/conf.d/custom-php-settings.ini

# Send mail conf
RUN echo "mailhub=mailcatcher:25\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

# Install Drush for Drupal 7 backward compatibility
RUN wget http://files.drush.org/drush.phar \
  && chmod +x drush.phar \
  && mv drush.phar /usr/local/bin/drush

# Install Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"
RUN php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer \
	&& rm /tmp/composer-setup.php \
  && chmod +x /usr/local/bin/composer

WORKDIR /var/www/html

# This will fix problem with permission
RUN usermod -u 1000 www-data
