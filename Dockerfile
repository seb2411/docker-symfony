FROM ubuntu:14.10

MAINTAINER Lemarinel Sebastien <lemarinel.s@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install Apache2 and Php 5
RUN apt-get update \
&& apt-get install -y apache2 apache2-mpm-worker php5-fpm php5-cli \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& rm -rf /tmp/*

# apache2 mutex and pid directories don't exist
RUN mkdir /var/lock/apache2 \
    && chown www-data.www-data /var/lock/apache2 \
    && mkdir /var/run/apache2 \
    && chown www-data.www-data /var/run/apache2

ADD etc/vhost.conf /etc/apache2/sites-available/000-default.conf

# php-fpm config
RUN sed -i "/;daemonize/c\daemonize=no" /etc/php5/fpm/php-fpm.conf
RUN echo "listen = 0.0.0.0:9000\n\
pm = ondemand\n\
pm.process_idle_timeout = 60s\n\
pm.max_requests = 50\n\
\
php_admin_value[date.timezone] = UTC\n\
php_admin_flag[opcache.validate_timestamps] = off\n\
php_admin_flag[opcache.save_comments] = off\n\
php_admin_flag[opcache.enable_file_override] = on" >> /etc/php5/fpm/pool.d/www.conf
