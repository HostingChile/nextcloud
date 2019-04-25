# Nextcloud en Hosting.cl

## Instalación
- Instalar Vim, Git y Docker con `yum install -y vim git docker`
- Instalar Docker Compose con `curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose`
- Dejar SELinux en modo permisivo.. Primero temporalmente con `setenforce 0` y luego editando el archivo `vim /etc/selinux/config` y dejando `SELINUX=permissive` para mantener los cambios al reinicar el servidor.
- Habilitar el servicio de Docker para que se ejecute la reiniciar el servidor `systemctl enable docker` 
- Descargar el repositorio con `git clone https://github.com/tikoflano/nextcloud.git /home/nextcloud`
- Se debe habilitar la comunicación entre contenedores en el firewall con `firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=172.20.0.0/16 accept'`, luego reiniciar el firewall y docker con `systemctl restart firewalld && systemctl restart docker`.
- Para facilitar la ejecución de los comandos de docker-compose es mejor editar el archivo `~/.bash_profile` y agregar la siguiente variable de entorno:
  ```
  COMPOSE_FILE=/home/nextcloud/docker-compose.yml:[AGREGAR LOS OTROS ARCHIVOS docker-compose QUE SE USARÁN]
  
  export COMPOSE_FILE
  ```
  Luego se debe ejecutar `source ~/.bash_profile` para que tome las variables.
- **Opcional**: Agregar un alias a docker-compose en el archivo `~/.bashrc` con `alias dc='docker-compose'` y luego ejecutar `source ~/.bash_profile` para que tome los cambios. Si se hace este paso se puede reemplazar el comando `docker-compose` por `dc` en los siguientes pasos.

- **Opcional**: Ejecutar `docker-compose pull` para que baje las imágenes a usar. Útil para la creación de plantillas de VM.
- Copiar el archivo de configuración de ejemplo `cp /home/nextcloud/example.env /home/nextcloud/.env`
- Editar el archivo de configuracion `vim /home/nextcloud/.env` con los valores que se quieran usar

- Ejecutar `docker-compose up -d`. Luego se puede ingresar a `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>`. Cuando ya muestre la página de manera correcta se puede continuar y ejecutar los comandos:
  - `docker-compose exec --user www-data nextcloud php occ db:convert-filecache-bigint` para evitar un aviso que sale en el estado del sistema
  - `docker-compose exec -u www-data nextcloud php occ background:cron` para cambiar le modo de ejecución de los trabajos en segundo plano

## Habilitar Collabora
Luego de instalar la app, se debe usar la URL `https://<COLLABORA_SUBDOMAIN>.<DOMAIN>` en la configuración. Si aparece un mensaje diciendo *Saved with error* se puede ignorar.

Para comprobar si está ejecutándose se puede ingresar a `https://<COLLABORA_SUBDOMAIN>.<DOMAIN>/loleaflet/dist/admin/admin.html`
  
## Habilitar OnlyOffice
Luego de instalar la app, se debe usar la siguiente configuración (habilitar configuración avanzada):
  - **Document Editing Service address**: `https://<ONLYOFFICE_SUBDOMAIN>.<DOMAIN>`
  - **Document Editing Service address for internal requests from the server**: `https://<ONLYOFFICE_SUBDOMAIN>.<DOMAIN>`
  - **Server address for internal requests from the Document Editing Service**: `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>`
  
Para comprobar si está ejecutándose se puede ingresar a `https://<ONLYOFFICE_SUBDOMAIN>.<DOMAIN>`
  
## Usar servidor de correo integrado
Si se usa el archivo ``docker-compose.mail.yml` el sistema tendrá un servidor de correos integrado. Para usarlo se debe usar la siguiente configuración:
  - **Send mode**: SMTP
  - **Encrytpion**: None
  - **From address**: `<ELEGIR_NOMBRE>@<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>`
  - **Authentication** method: None
  - **Server address**: mail : 25
  
## Usar certificado propio
- Eliminar la variables de entorno `LETSENCRYPT_*` del archivo .
- Copiar en `/var/lib/docker/volumes/nextcloud_proxy-certs/_data/` los archivos .crt y .key que componen el certificado. El nombre de estos archivos debe ser exactamente igual al nombre del `VIRTUAL_HOST` del servicio, terminado con .crt y .key

Con esto el contendor proxy generará el virtualhost correspondiente para que use el certificado.
  
## Errores comunes
1. Al entrar al sitio aparece como no seguro. Luego al ver el certificado en el navegador dice emitido por y para *letsencrypt-nginx-proxy-companion*.
  Esto ocurre porque el servicio que provee los ceritificados aun no lo ha emitido. Posibles razones:
  - Aun esta trabajando en eso. Puede tardar unos 5 minutos.
  - El subdominio nextcloud.dominio.tld aun no responde públicamente a la IP del servidor.
  - Se ha alcanzado el límite de certificados gratuitos posibles para emitir por Let's Encrypt (https://letsencrypt.org/docs/rate-limits/). 
2. **502 Bad Gateway**
Alguno de los servicios aún no arranca, hay que esperar unos 5 minutos. En caso de persistir el problema se deben ver los logs.
