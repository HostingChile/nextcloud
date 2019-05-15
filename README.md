# Nextcloud en Hosting.cl

## Instalación
- Instalar Vim, Git y Docker con `yum install -y vim git docker`
- Instalar Docker Compose con `curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose`
- Dejar SELinux en modo permisivo:
  - Ejecutar `setenforce 0`. Este cambio se pierde al reiniciar el servidor, por lo que es necesario el paso siguiente.
  - Editar el archivo `vim /etc/selinux/config` y dejando `SELINUX=permissive` para mantener los cambios al reiniciar el servidor. Este cambio lo toma solo al reiniciar el servidor, por lo que es necesario el paso anterior.
- Habilitar el servicio de Docker para que se ejecute la reiniciar el servidor `systemctl enable docker` 
- Descargar el repositorio con `git clone https://github.com/tikoflano/nextcloud.git /home/nextcloud`
- Para facilitar la ejecución de los comandos de docker-compose es mejor editar el archivo `vim ~/.bash_profile` y agregar la siguiente variable de entorno, reemplazando `DOCUMENT_EDITOR` por *onlyoffice* o *collabora* según el editor que se vaya a usar:
  ```
  COMPOSE_FILE=docker-compose.yml:docker-compose.<DOCUMENT_EDITOR>.yml
  
  export COMPOSE_FILE
  ```
  Luego se debe ejecutar `source ~/.bash_profile` para que tome las variables.
- **Opcional**: Agregar un alias a docker-compose en el archivo `vim ~/.bashrc` con `alias dc='docker-compose'` y luego ejecutar `source ~/.bash_profile` para que tome los cambios. Si se hace este paso se puede reemplazar el comando `docker-compose` por `dc` en los siguientes pasos.
- Copiar el archivo de configuración de ejemplo `cp /home/nextcloud/example.env /home/nextcloud/.env`
- Editar el archivo de configuracion `vim /home/nextcloud/.env` con los valores que se quieran usar
- Se debe habilitar la comunicación entre contenedores en el firewall con `firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=<SUBNET> accept'`, luego reiniciar el firewall y docker con `systemctl restart firewalld && systemctl restart docker`.
- Ingresar a la carpeta `cd /home/nextcloud` y levantar los servicios con `docker-compose up -d --build`

## Cambiar parámetros
Si se cambia algun parámetro del archivo `.env` es necesario reconstruir los contenedores con el comando `docker-compose up -d --force-recreate --build <SERVICIO A REINICIAR>`, si no se especifica un `<SERVICIO A REINICIAR>` se reiniciarán todos.

## Actualización
Primero se debe traer la última versión de los archivos de este repositorio con `git pull`. Luego se debe ejecutar el comando `docker-compose pull --ignore-pull-failures && docker-compose up -d --build`. Esto descargará las últimas imágenes y actualizará los contenedores. Como la información se encuentra en volúmenes, no se pierde nada. Luego se puede ejecutar el comando `docker system prune -af` para eliminar las imágenes antiguas y liberar espacio en el disco.

Luego de la actualización se recomienda entrar a `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/settings/admin/overview` y revisar si la actualización fue realizada correctamente y si hay más acciones que se deben realizar.

**Importante**: las actualziaciones pueden generar que algunas apps dejen de funcionar. Por defecto Nextcloud deshabilita algunas aplicaciones las cuales deben ser actualizadas y habilitadas manualmente en `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/settings/apps`

## Collabora
Para comprobar si está ejecutándose se puede ingresar a `https://<COLLABORA_SUBDOMAIN>.<DOMAIN>`, debe mostrar el mensaje "ok".

Se puede ingresar a `https://<COLLABORA_SUBDOMAIN>.<DOMAIN>/loleaflet/dist/admin/admin.html` con los datos de acceso definidos en el archivo `.env`.
  
## OnlyOffice  
Para comprobar si está ejecutándose se puede ingresar a `https://<ONLYOFFICE_SUBDOMAIN>.<DOMAIN>`
  
## Servidor de correo integrado
El sistema viene con un servidor de correo propio listo y ya configurado. Si se quiere usar el correo propio se debe cambiar la configuración en `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/settings/admin`
  
## Usar certificado propio
- Eliminar la variables de entorno `LETSENCRYPT_*` del archivo .
- Copiar en `/var/lib/docker/volumes/nextcloud_proxy-certs/_data/` los archivos .crt y .key que componen el certificado. El nombre de estos archivos debe ser exactamente igual al nombre del `VIRTUAL_HOST` del servicio, terminado con .crt y .key

Con esto el contendor proxy generará el virtualhost correspondiente para que use el certificado.

## Usar Pico CMS
Si se usa esta aplicación, se debe realizar un cambio a la configuración del virtualhost en el Nginx para que sirva las páginas. Para esto hay que crear el archivo `vim /var/lib/docker/volumes/nextcloud_proxy-vhost/_data/<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>_location` y poner la siguiente configuración (reemplazando los valores necesarios):

```
location /sites/ {
  rewrite /sites/(.*) /apps/cms_pico/pico/$1 break;
  location ~ ^/apps/cms_pico/pico/(\.htaccess|\.git|config|content|content-sample|lib|vendor|CHANGELOG\.md|composer\.(json|lock)) {
    return 404;
  }
  proxy_redirect off;
  proxy_pass http://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/;
}
```
  
## Errores comunes
1. Al entrar al sitio aparece como no seguro. Luego al ver el certificado en el navegador dice emitido por y para *letsencrypt-nginx-proxy-companion*.
  Esto ocurre porque el servicio que provee los ceritificados aun no lo ha emitido. Posibles razones:
  - Aun esta trabajando en eso. Puede tardar unos 5 minutos.
  - El subdominio nextcloud.dominio.tld aun no responde públicamente a la IP del servidor.
  - Se ha alcanzado el límite de certificados gratuitos posibles para emitir por Let's Encrypt (https://letsencrypt.org/docs/rate-limits/). 
2. **502 Bad Gateway**
Alguno de los servicios aún no arranca, hay que esperar unos 5 minutos. En caso de persistir el problema se deben ver los logs.
3. Las imágenes de Docker se descargan muy lento. Es probable que sea un límite impuesto por la red por lo cual debe contactarse con el administrador de red.
