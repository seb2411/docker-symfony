#!/bin/bash

declare -A PHP5_MODULES
eval "PHP5_MODULES=($@)"

# disable existing modules
rm /etc/php5/fpm/conf.d/*

# workaround for pdo_mysql and mysql. for reasons i don't comprehend
# even if mysql is listed before pdo_mysql bash associative arrays
# reaches pdo_mysql before mysql. pdo_mysql doesn't exist before mysql
# is installed
if [ ${PHP5_MODULES["mysql"]+_} ]; then
    apt-get install -y php5-mysql
fi

for module in "${!PHP5_MODULES[@]}"; do
    if [ "${PHP5_MODULES["$module"]}" == true ]; then
        apt-get install -y "php5-$module"
    fi

    php5enmod -s fpm $module

    # hack to disable newrelic daemon
    if [ "$module" == "newrelic" ]; then
        echo "newrelic.daemon.dont_launch = 3" >> /etc/php5/fpm/conf.d/20-newrelic.ini
    fi
done
