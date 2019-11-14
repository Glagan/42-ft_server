# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ncolomer <ncolomer@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2019/11/12 17:30:14 by ncolomer          #+#    #+#              #
#    Updated: 2019/11/14 13:06:08 by ncolomer         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM debian:buster

ENV PASSWORD 		'admin'
ENV USER_WORDPRESS	'ncolomer'

# Utility
RUN apt-get update; \
	apt-get install -y nginx wget procps psmisc debconf debconf-utils perl lsb-release gnupg

# Add MySQL PPA
RUN wget -q http://repo.mysql.com/mysql-apt-config_0.8.9-1_all.deb; \
	export DEBIAN_FRONTEND=noninteractive && dpkg -i mysql-apt-config*; \
	apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5; \
	apt-get update; \
	apt-get install --no-install-recommends --no-install-suggests -y ca-certificates libssl1.1

# Install PHP + NGINX
RUN echo "mysql-server-5.7 mysql-server/root_password password $PASSWORD" | debconf-set-selections; \
	echo "mysql-server-5.7 mysql-server/root_password_again password $PASSWORD" | debconf-set-selections; \
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
	php php-cgi php-mysqli php-pear php-mbstring php-gettext \
	php-common php-phpseclib php-mysql php-fpm unzip mysql-server

# Unzip Wordpress and PhpMyAdmin
RUN mkdir -p /var/www/html
COPY srcs/phpmyadmin.zip /var/www/html
COPY srcs/wordpress.zip /var/www/html
RUN unzip -q /var/www/html/phpmyadmin.zip -d /var/www/html; \
	unzip -q /var/www/html/wordpress.zip -d /var/www/html; \
	chown -R www-data:www-data /var/www/html/wordpress

# NGINX configuration
COPY srcs/www.conf /etc/php/7.3/fpm/pool.d/
COPY srcs/index.html /var/www/html
COPY srcs/default /etc/nginx/sites-available/

# SSL
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj '/C=FR/ST=75/L=Paris/O=42/CN=ncolomer' \
	-keyout /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.crt

# Start
CMD	service mysql start; \
	service nginx start; \
	service php7.3-fpm start; \
	mysql -u root -p$PASSWORD -e "CREATE USER '$USER_WORDPRESS'@'localhost' identified by '$PASSWORD';" ;\
	mysql -u root -p$PASSWORD -e "CREATE DATABASE wordpress;"; \
	mysql -u root -p$PASSWORD -e "GRANT ALL PRIVILEGES ON wordpress.* TO '$USER_WORDPRESS'@'localhost';" ;\
	mysql -u root -p$PASSWORD -e "FLUSH PRIVILEGES;" ;\
	sleep infinity & wait

# Expose the ports
EXPOSE 8080 80 443
