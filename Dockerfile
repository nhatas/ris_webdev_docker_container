# use Ubuntu 20.04 as base container
FROM ubuntu:20.04

# required for PHPMyAdmin silent installation
RUN echo "phpmyadmin phpmyadmin/internal/skip-preseed boolean true" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/mysql/admin-user string nobody" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/mysql/admin-pass password password" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/mysql/app-pass password password" |debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/app-password-confirm password password" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections

#install necessary packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y \
    apache2 \
    git \
    libapache2-mod-php \
    libnss-sss \
    mariadb-server \
    nano \
    php7.4 \
    phpmyadmin \
    uuid-runtime \
    vim \
    && apt-get install -y debconf-utils \
    && apt-get clean

# overwrite default configuration files
WORKDIR /etc/apache2
COPY apache2.conf .
COPY envvars .
COPY ports.conf .

WORKDIR /etc/apache2/sites-available
COPY 000-default.conf .

WORKDIR /etc/phpmyadmin
COPY config.inc.php .

CMD /bin/bash
ENTRYPOINT []
 
# set timezone
RUN ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
RUN echo "America/Chicago" > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

# set folder permissions
RUN chmod -R 777 /var/lib/mysql /var/log/mysql /var/lib/phpmyadmin
RUN rm -fr /var/lib/mysql/mysql /var/lib/mysql/performance_schema
RUN apt-get install uuid-runtime

# copy script to generate mysql configuration
WORKDIR /app
COPY script.sh .
RUN chmod a+x script.sh
RUN chmod -R 777 /app

# required for SSL connection
RUN a2enmod ssl 
EXPOSE 8081

