FROM php:7-apache
RUN a2enmod rewrite

# install the PHP extensions we need (git for Composer, mysql-client for mysqldump)
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev libpq-dev git mysql-client-5.6 wget nano \
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

#Configure PHP memory limit
RUN {  \
		echo "memory_limit = 512M"; \
	} >> /usr/local/etc/php/php.ini

#Install Drush 8.1.3
RUN wget https://github.com/drush-ops/drush/releases/download/8.1.3/drush.phar && php drush.phar core-status && chmod +x drush.phar \
	&& mv drush.phar /usr/local/bin/drush

#Install Drupal Console
RUN curl http://drupalconsole.com/installer -L -o drupal.phar
RUN mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal
RUN drupal init

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

WORKDIR /var/www/html
