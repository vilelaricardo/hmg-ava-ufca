FROM php:8.1-apache

# Instalar extensões do PHP necessárias pelo Moodle
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
libxml2-dev \
libzip-dev \
libxslt-dev \
zip \
unzip \
git \
cron \
&& docker-php-ext-configure gd --with-jpeg \
&& docker-php-ext-install -j$(nproc) gd \
&& docker-php-ext-install pdo_pgsql \
&& docker-php-ext-install pgsql \
&& docker-php-ext-install soap \
&& docker-php-ext-install intl \
&& docker-php-ext-install zip \
&& docker-php-ext-install opcache \
&& docker-php-ext-install xsl

# Habilitar o mod_rewrite para o Apache
RUN a2enmod rewrite

# Copiar o código fonte do Moodle para o container
COPY . /var/www/html/

RUN mkdir -p /var/www/moodledata && \
chown -R www-data:www-data /var/www/moodledata && \
chmod -R 777 /var/www/moodledata

# Copia a pasta pt_br para o diretório moodledata/lang
COPY lang/pt_br /var/www/moodledata/lang/pt_br

# Alterar as permissões da pasta do Moodle
RUN chown -R www-data:www-data /var/www/html \
&& chmod -R 755 /var/www/html

# Copiar o arquivo php.ini-development para php.ini e ajustar max_input_vars, post_max_size e upload_max_filesize
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini \
&& sed -i 's/;max_input_vars = [0-9]*/max_input_vars = 5000/' /usr/local/etc/php/php.ini \
&& sed -i 's/post_max_size = .*/post_max_size = 100M/' /usr/local/etc/php/php.ini \
&& sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' /usr/local/etc/php/php.ini \
&& sed -i 's/;extension=xsl/extension=xsl/' /usr/local/etc/php/php.ini

# Configurar o cron job para executar cron.php a cada 30 minutos
RUN echo '*/30 * * * * /usr/local/bin/php /var/www/html/admin/cli/cron.php > /proc/1/fd/1 2>&1' > /etc/cron.d/moodle-cron \
&& chmod 0644 /etc/cron.d/moodle-cron \
&& crontab /etc/cron.d/moodle-cron

# Expor a porta 80
EXPOSE 80

# Comando para iniciar o cron e o apache
CMD ["bash", "-c", "cron && apache2-foreground"]
