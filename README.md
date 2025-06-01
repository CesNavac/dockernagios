FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias
RUN apt-get update && apt-get install -y \
    autoconf gcc libc6 make wget unzip apache2 \
    apache2-utils php libapache2-mod-php \
    libgd-dev libmcrypt-dev libssl-dev \
    daemon libperl-dev snmp \
    build-essential libnet-snmp-perl gettext \
    vim curl && \
    rm -rf /var/lib/apt/lists/*

# Configura Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Crea usuario y grupo nagios
RUN useradd nagios && groupadd nagcmd && \
    usermod -a -G nagcmd nagios && \
    usermod -a -G nagcmd www-data

# Instala Nagios Core
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

# Crea usuario web nagios con contraseña 'admin123'
RUN htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagios admin123

# Escribe commands.cfg con todos los comandos necesarios
RUN echo 'define command {' > /usr/local/nagios/etc/objects/commands.cfg && \
    echo '    command_name    check-host-alive' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '    command_line    $USER1$/check_ping -H $HOSTADDRESS$ -w 100.0,20% -c 500.0,60%' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '}' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo 'define command {' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '    command_name    notify-service-by-email' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '    command_line    /bin/echo "Service Alert: $SERVICEDESC$ on $HOSTNAME$ is $SERVICESTATE$"' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '}' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo 'define command {' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '    command_name    notify-host-by-email' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '    command_line    /bin/echo "Host Alert: $HOSTNAME$ is $HOSTSTATE$"' >> /usr/local/nagios/etc/objects/commands.cfg && \
    echo '}' >> /usr/local/nagios/etc/objects/commands.cfg

# Escribe localhost.cfg con host y servicio funcional
RUN echo 'define host {' > /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    use                     linux-server' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    host_name               localhost' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    alias                   Localhost' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    address                 127.0.0.1' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    check_command           check-host-alive' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    max_check_attempts      5' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    check_period            24x7' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    notification_interval   30' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    notification_period     24x7' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '}' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo 'define service {' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    use                     generic-service' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    host_name               localhost' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    service_description     PING' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '    check_command           check-host-alive' >> /usr/local/nagios/etc/objects/localhost.cfg && \
    echo '}' >> /usr/local/nagios/etc/objects/localhost.cfg

# Habilita CGI
RUN a2enmod cgi

# Script de inicio
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'service apache2 start' >> /start.sh && \
    echo 'service nagios start' >> /start.sh && \
    echo 'tail -F /usr/local/nagios/var/nagios.log' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
#### Pruebas del push hacia git #####
#### ![image](https://github.com/user-attachments/assets/a1888571-43e4-40b0-9830-370e1d32d64a) ######
### link directo para verificar la imagen de docker https://github.com/users/CesNavac/packages/container/package/nagios-core ####
### Prueba que en mi maquina si funciono ![image](https://github.com/user-attachments/assets/59cb0184-6bc2-47c8-b391-aca0b9e22b86)####
### screen de lo descrito ![image](https://github.com/user-attachments/assets/3c49d520-36a8-492f-a1ee-0e08f8485bfd)###



