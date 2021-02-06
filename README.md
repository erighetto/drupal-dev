# drupal-dev
Drupal Development Enviroment featuring:

 - PHP 7.4  
 - Apache 2.4
 - Composer

extension of webdevops/php-apache-dev:7.4 image

cfr: https://github.com/webdevops/Dockerfile/tree/master/docker/php-apache-dev/7.4

For Drupal 7 you can easy install the last release compatible:

    wget -O drush.phar https://github.com/drush-ops/drush/releases/download/8.1.15/drush.phar  
    chmod +x drush.phar  
    mv drush.phar /usr/local/bin/drush

docker-compose.yml example:
https://gist.github.com/erighetto/d245e4a662cc6b93d38f25d9418b7ed0
