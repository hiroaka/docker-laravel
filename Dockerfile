FROM php:8.1-apache 


RUN apt update && apt install -y libicu-dev libxml2-dev libzip-dev libonig-dev zlib1g-dev libpng-dev git zip unzip curl  libapache2-mod-security2 nano vim \
     && rm -rf /var/lib/apt/lists/* \
     && docker-php-ext-configure intl \
     && docker-php-ext-configure gd \
     && docker-php-ext-install mysqli gd intl mbstring pdo_mysql exif zip  xml \
     && a2enmod headers rewrite ssl security2

# copia o entreypoint
COPY ./.docker/entrypoint /var/www/entrypoint
# adiciona permissão de execução para o Entrypoint
RUN chmod +x /var/www/entrypoint

# instala o Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \ 
     && php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \ 
     && php composer-setup.php --install-dir=/usr/bin --filename=composer \
     && php -r "unlink('composer-setup.php');"

# configurações extras para o PHP ini
COPY ./php/zz-php.ini /usr/local/etc/php/conf.d/zz-php.ini
# copia o mod_ssl do apache
COPY ./.docker/ssl.conf /etc/apache2/mods-available/ssl.conf
# outras configurações do apache
COPY ./.docker/my.conf /etc/apache2/conf-enabled/my.conf
COPY ./.docker/security.conf /etc/apache2/conf-enabled/security.conf

RUN a2enmod ssl \
     && a2ensite default-ssl \
     && openssl req -subj '/CN=example.com/O=My Company Name LTD./C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem

#copia o certificado de segurança
# COPY ./ssl/ssl-cert-snakeoil.pem  /etc/ssl/certs/ssl-cert-snakeoil.pem
# COPY ./ssl/ssl-cert-snakeoil.key /etc/ssl/private/ssl-cert-snakeoil.key


# configuração do site defaul
COPY ./.docker/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./.docker/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
RUN a2ensite 000-default.conf && a2ensite default-ssl.conf 

# HEaders de Cookie Apache
RUN  echo "Header always edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure;SameSite=Lax" >> /etc/apache2/apache2.conf

# Set working directory
WORKDIR /var/www/html


ENTRYPOINT [ "/var/www/entrypoint" ]


