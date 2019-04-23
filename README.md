# Nextcloud en Hosting.cl

## Instalación
- Instalar Vim, Git y Docker con `yum install -y vim git docker`
- Deshabilitar SELinux. Primero temporalmente con `setenforce 0` y luego editando el archivo `vim /etc/selinux/config` y dejando `SELINUX=disabled` para mantener los cambios al reinicar el servidor.
- Habilitar el servicio de Docker para que se ejecute la reiniciar el servidor `systemctl enable docker`
- Instalar Docker Compose con `curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose` 
- Descargar el repositorio con `git clone https://github.com/tikoflano/nextcloud.git /home/nextcloud`
- Se debe habilitar la comunicación entre contenedores en el firewall con `firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=172.20.0.0/16 accept'`, luego reiniciar el firewall y luego reiniciar docker con `systemctl restart firewalld && systemctl restart docker`.
- Copiar el archivo de configuración de ejemplo `cp /home/nextcloud/example.env /home/nextcloud/.env`
- Editar el archivo de configuracion `vim /home/nextcloud/.env` con los valores que se quieran usar
- **OBSOLETO**: Se debe cambiar el dueño de la carpeta `app/` con el UID:GID 33:33 (Al parecer no, creo que al tener SELinux deshabilitado esto se hace solo)

## Iniciar los servicios
- Se inicia con, `docker-compose -f docker-compose.yml up -d` pero su se quiere agregar Collabora y/o OnlyOffice se deben agregar los parámetros `-f docker-compose.collabora.yml` y `-f docker-compose.onlyoffice.yml` respectivamente.

## Habilitar Collabora
Luego de instalar la app, se debe usar la URL https://collabora.dominio.tld en la configuración. Si aparece un mensaje diciendo *Saved with error* se puede ignorar.
  
## Habilitar OnlyOffice
Luego de instalar la app, se debe usar la siguiente configuración (habilitar configuración avanzada):
  - *Document Editing Service address*: https://onlyoffice.dominio.tld
  - *Document Editing Service address for internal requests from the server*: https://onlyoffice.dominio.tld
  - *Server address for internal requests from the Document Editing Service*: https://nextcloud.dominio.tld
  
## Errores comunes
1. Al entrar al sitio aparece como no seguro. Luego al ver el certificado en el navegador dice emitido por y para *letsencrypt-nginx-proxy-companion*.
  Esto ocurre porque el servicio que provee los ceritificados aun no lo ha emitido. Posibles razones:
  - Aun esta trabajando en eso. Puede tardar unos 5 minutos.
  - El subdominio nextcloud.dominio.tld aun no responde públicamente a la IP del servidor.
  - Se ha alcanzado el límite de certificados gratuitos posibles para emitir por Let's Encrypt (https://letsencrypt.org/docs/rate-limits/). 
2. Al entrar a https://collabora.dominio.tld/ aparece **502 Bad Gateway**.
  Es muy probable que sea que el servicio de Collabora aun no termina de arrancar. Puede tardar unos 5 - 10 minutos.
