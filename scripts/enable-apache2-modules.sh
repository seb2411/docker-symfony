#!/bin/bash

# disable existing modules
rm /etc/apache2/mods-enabled/*

for module in $@; do
    a2enmod $module
done
