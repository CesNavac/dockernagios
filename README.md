 #Usar una imagen base de Ubuntu
FROM ubuntu:22.04

# Evita interacciones durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias necesarias para armar una imagen de docker con nagios
RUN apt-get update && apt-get install -y \
    autoconf gcc libc6 make wget unzip apache2 \
    apache2-utils php libapache2-mod-php \
    libgd-dev libmcrypt-dev libssl-dev \
    daemon libperl-dev libssl-dev snmp \
    build-essential libnet-snmp-perl gettext \
    && rm -rf /var/lib/apt/lists/*

# Crea usuario y grupo nagios
RUN useradd nagios && groupadd nagcmd \
    && usermod -a -G nagcmd nagios \
    && usermod -a -G nagcmd www-data
# datos del usuario
# usuario: nagios
# clave: duoc.2025


# Descarga e instala Nagios Core
WORKDIR /tmp
RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz && \
    tar zxvf nagios-4.4.6.tar.gz && \
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

# Instala plugins de Nagios
RUN wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz && \
    tar zxvf nagios-plugins-2.3.3.tar.gz && \
    cd nagios-plugins-2.3.3 && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && make install
    cd nagios-4.4.6 && \
    ./configure --with-command-group=nagcmd && \
    make all && \
    make install && \
    make install-init && \
    make install-commandmode && \
    make install-config && \
    make install-webconf
# Instala plugins de Nagios
RUN wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz && \
    tar zxvf nagios-plugins-2.3.3.tar.gz && \
    cd nagios-plugins-2.3.3 && \
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
    make && make install

# Configura usuario para interfaz web (usaremos archivo copiado después)
COPY nagiosadmin.password /tmp/nagiosadmin.password
RUN htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagios $(cat /tmp/nagiosadmin.password)

# Habilita módulos y servicios
RUN a2enmod cgi && \
    update-rc.d nagios defaults

# Expón el puerto de la interfaz web
EXPOSE 80

# Comando para iniciar Apache y Nagios
CMD ["bash", "-c", "service apache2 start && service nagios start && tail -f /usr/local/nagios/var/nagios.log"]
### A continuacion adjunto la imagen que subi junto con los comandos ###
### ![image](https://github.com/user-attachments/assets/d1141c41-01cf-4bc0-95fd-20e809cc37fb)
### Link para ver la imagen subida, esta en publico###
### https://github.com/users/CesNavac/packages/container/package/nagios-core 
