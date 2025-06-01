# Usa una imagen base de Ubuntu
FROM ubuntu:22.04

# Evita interacciones durante instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias necesarias
RUN apt-get update && apt-get install -y \
    autoconf gcc libc6 make wget unzip apache2 \
    apache2-utils php libapache2-mod-php \
    libgd-dev libmcrypt-dev libssl-dev \
    daemon libperl-dev snmp \
    build-essential libnet-snmp-perl gettext \
    vim curl && \
    rm -rf /var/lib/apt/lists/*

# Crea usuario y grupo nagios
RUN useradd nagios && groupadd nagcmd && \
    usermod -a -G nagcmd nagios && \
    usermod -a -G nagcmd www-data

# Descarga e instala Nagios Core
WORKDIR /tmp
RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz && \
    tar zxvf nagios-4.4.6.tar.gz && \
    cd nagios-4.4.6 && \
    ./configure --with-command-group=nagcmd && \
    make all && \
    make install && \
    make install-init && \
    make install-commandmode && \
    make install-config && \
    make install-webconf

# Descarga e instala plugins de Nagios
RUN wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz && \
    tar zxvf nagios-plugins-2.3.3.tar.gz && \
    cd nagios-plugins-2.3.3 && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && make install

# Configura usuario de interfaz web
COPY nagiosadmin.password /tmp/nagiosadmin.password
RUN htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagios $(cat /tmp/nagiosadmin.password)

# Habilita CGI en Apache
RUN a2enmod cgi

# Expón el puerto web
EXPOSE 80

# Script de inicio
CMD ["bash", "-c", "service apache2 start && service nagios start && tail -F /usr/local/nagios/var/nagios.log"]

