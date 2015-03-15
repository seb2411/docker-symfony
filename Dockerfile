FROM ubuntu:14.10

MAINTAINER Lemarinel Sebastien <lemarinel.s@gmail.com>

ENV DEBIAN_FRONTEND noninteractive


RUN mkdir -p /eexternal
VOLUME [ "/external/" ]

# Install packages needed
# - Apache 2    : server Http
# - Php5-fpm    : FPM version of PHP
# - Php5-Cli    : Php Cli
# - Supervisor  : To manage multiple process in the container
RUN apt-get update \
&& apt-get install -y apache2 apache2-mpm-worker php5-fpm php5-cli supervisor python-pip\
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& rm -rf /tmp/*

RUN pip install supervisor-stdout

# Copying our personalised Vhost to replace the default versrion.
ADD etc/vhost.conf /etc/apache2/sites-available/000-default.conf

# our supervisor config
ADD etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor

# Add Scripts
ADD scripts /opt/scripts

RUN /opt/scripts/enable-apache2-modules.sh alias authz_core deflate mime mpm_worker proxy_fcgi proxy_http rewrite \
    && /opt/scripts/enable-php5-modules.sh ["curl"]=true ["json"]=false ["mcrypt"]=true ["memcached"]=true ["opcache"]=false ["pdo"]=false

# Fix Mutex problem
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /external/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2

RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR


# Add Volume
VOLUME [ "/var/www/" ]

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

# HTTP port
EXPOSE 80

CMD ["/usr/bin/supervisord"]
