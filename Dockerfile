FROM php:7-apache
RUN a2enmod rewrite

# install the PHP extensions we need (git for Composer, mysql-client for mysqldump)
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev libpq-dev git mysql-client-5.5 wget nano \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mbstring opcache pdo pdo_mysql pdo_pgsql zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

WORKDIR /root

#Configure PHP settings
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
		echo 'sendmail_path = /usr/bin/env catchmail --smtp-ip mailcatcher --smtp-port 10025 -f test@example.com'; \
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

#Install Drush 8.1.7
RUN wget https://github.com/drush-ops/drush/releases/download/8.1.7/drush.phar && php drush.phar core-status && chmod +x drush.phar \
	&& mv drush.phar /usr/local/bin/drush

#Install Drupal Console
RUN curl http://drupalconsole.com/installer -L -o drupal.phar
RUN mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal
RUN drupal init

#Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

WORKDIR /var/www/html

#This will fix problem with permission
RUN usermod -u 1000 www-data
