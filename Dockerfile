FROM php:7-apache
RUN a2enmod rewrite

# install the PHP extensions we need (git for Composer, mysql-client for mysqldump)
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
	&& docker-php-ext-install opcache gd mbstring pdo pdo_mysql pdo_pgsql zip mysqli calendar json curl xml soap \
	&& pecl install xdebug \
	&& docker-php-ext-enable xdebug

# Let's keep the house clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

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

# Configure PHP settings
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

WORKDIR /root

# Install Drush 8.1.7
RUN wget https://github.com/drush-ops/drush/releases/download/8.1.7/drush.phar && php drush.phar core-status \
	&& mv drush.phar /usr/local/bin/drush

# Install Drupal Console
RUN curl http://drupalconsole.com/installer -L -o drupal.phar \
  && mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal \
  && drupal init

# Install Composer
# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php -r "if (hash_file('SHA384', 'composer-setup.php') === 'aa96f26c2b67226a324c27919f1eb05f21c248b987e6195cad9690d5c1ff713d53020a02ac8c217dbf90a7eacc9d141d') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && php -r "unlink('composer-setup.php');" \
  && chmod +x /usr/local/bin/composer

# Test and Coding standard
RUN curl -L https://phar.phpunit.de/phpunit.phar > /usr/local/bin/phpunit \
  && curl -L http://www.phing.info/get/phing-latest.phar > /usr/local/bin/phing \
  && curl -L https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar > /usr/local/bin/phpcs \
  && curl -L https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar > /usr/local/bin/phpcbf
  
# Set the permissions  
RUN chmod 0755 /usr/local/bin/*

# Configure additional coding-standards directory
RUN mkdir -p /usr/local/share/coding-standards \
  && phpcs --config-set installed_paths /usr/local/share/coding-standards

# Install Symfony2 code styling
RUN curl -L https://github.com/escapestudios/Symfony2-coding-standard/archive/master.zip > /tmp/Symfony2-coding-standard.zip \
  && unzip /tmp/Symfony2-coding-standard.zip -d /tmp/Symfony2-coding-standard \
  && mv /tmp/Symfony2-coding-standard/Symfony2-coding-standard-master/Symfony2 /usr/local/share/coding-standards \
  && rm -rf /tmp/Symfony2-coding-standard*

# Install Drupal code styling 
RUN curl -L https://ftp.drupal.org/files/projects/coder-8.x-2.9.zip > /tmp/drupal-coder.zip \
  && unzip /tmp/drupal-coder.zip -d /tmp/drupal-coder \
  && mv /tmp/drupal-coder/coder/coder_sniffer/Drupal /usr/local/share/coding-standards \
  && rm -rf /tmp/drupal-coder*

WORKDIR /var/www/html

# This will fix problem with permission
RUN usermod -u 1000 www-data
