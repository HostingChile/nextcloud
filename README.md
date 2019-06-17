# Nextcloud en Hosting.cl

## Instalación
- Instalar Vim, Git y Docker con `yum install -y vim git docker`
- Instalar Docker Compose con `curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose`
- Dejar SELinux en modo permisivo:
  - Ejecutar `setenforce 0`. Este cambio se pierde al reiniciar el servidor, por lo que es necesario el paso siguiente.
  - Editar el archivo `vim /etc/selinux/config` y dejando `SELINUX=permissive` para mantener los cambios al reiniciar el servidor. Este cambio lo toma solo al reiniciar el servidor, por lo que es necesario el paso anterior.
- Habilitar el servicio de Docker para que se ejecute la reiniciar el servidor `systemctl enable docker` 
- Descargar el repositorio con `git clone https://github.com/tikoflano/nextcloud.git /home/nextcloud`
- Para facilitar la ejecución de los comandos de docker-compose es mejor editar el archivo `vim ~/.bash_profile` y agregar la siguiente variable de entorno, separando los archivos `docker-compose.*.yml` que se usen con un `:`:
  ```
  COMPOSE_FILE=docker-compose.yml:<OTROS ARCHIVOS docker-compose.*.yml A USAR>
  
  export COMPOSE_FILE
  ```
  Luego se debe ejecutar `source ~/.bash_profile` para que tome las variables.
- **Opcional**: Agregar un alias a docker-compose en el archivo `vim ~/.bashrc` con `alias dc='docker-compose'` y luego ejecutar `source ~/.bash_profile` para que tome los cambios. Si se hace este paso se puede reemplazar el comando `docker-compose` por `dc` en los siguientes pasos.
- Copiar el archivo de configuración de ejemplo `cp /home/nextcloud/example.env /home/nextcloud/.env`
- Editar el archivo de configuracion `vim /home/nextcloud/.env` con los valores que se quieran usar
- Se debe habilitar la comunicación entre contenedores en el firewall con `firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=<SUBNET> accept'`, luego reiniciar el firewall y docker con `systemctl restart firewalld && systemctl restart docker`.
- Ingresar a la carpeta `cd /home/nextcloud` y levantar los servicios con `docker-compose up -d`

## Configuración por defecto
Una vez que Nextcloud esté instalado se puede ejecutar el comando `docker-compose exec nextcloud setup` para ejecutar la configuración por defecto que se le da a nextcloud, la cual incluye:
- Correcciones a la base de datos
- Correcciones a las solicitudes web para que se cargue correctamente la página y se logeen correctamente las IPs de los visitantes
- Setear el *locale* por defecto: es_CL
- Crear la carpeta *Base* del usuario admin para que sea usada de base para los nuevos usuarios. Por defecto viene vacía.
- Hacer que el cron se ejecute periódicamente y no con las visitas de la página
- Luego si la API de las apps está disponible:
  - Instalar/actualizar y configurar el <DOCUMENT EDITOR> a usar
  - Instalar/actualizar y configurar el antivirus
  - Instalar/actualizar las apps por defecto definidas en el archivo `.env`
  - Limitar el uso solo para admin de las apps definidas en el archivo `.env`
  
Cada vez que se ejecuta este comando se ejecutan todas estas tareas por lo que se sobreescribirán los cambios hechos manualmente si es necesario. En caso de tener una ap pdeshabilitada, este comando la actualizará pero no la habilitará.

## Cambiar parámetros
Si se cambia algun parámetro del archivo `.env` es necesario reconstruir los contenedores con el comando `docker-compose up -d --force-recreate <SERVICIO A REINICIAR>`, si no se especifica un `<SERVICIO A REINICIAR>` se reiniciarán todos.

En caso de cambiar el valor de `<SUBNET>` se debe eliminar manualmente la red actual. Para esto se deben parar los contenedores con `docker-sompose stop` y luego eliminar la red con `docker network rm nextcloud_default`. Luego al hacer `docker-compose up -d` se recreará la red en el nuevo rango definido en `<SUBNET>`.

## Actualización
Primero se debe traer la última versión de los archivos de este repositorio con `git pull`. Luego se debe ejecutar el comando `docker-compose pull && docker-compose up -d`. Esto descargará las últimas imágenes y actualizará los contenedores. Como la información se encuentra en volúmenes, no se pierde nada. Luego se puede ejecutar el comando `docker system prune -af` para eliminar las imágenes antiguas y liberar espacio en el disco.

Luego de la actualización se recomienda entrar a `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/settings/admin/overview` y revisar si la actualización fue realizada correctamente y si hay más acciones que se deben realizar.

**Importante**: las actualziaciones pueden generar que algunas apps dejen de funcionar. Por defecto Nextcloud deshabilita algunas aplicaciones las cuales deben ser actualizadas y habilitadas manualmente en `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/settings/apps`

## Restaurar respaldo
Hay que restaurar:
- Archivos de Nextcloud, incluyendo configuración, apps y archivos respaldados.

  Se deben copiar los archivos, confirmar que el dueño de los archivos tiene UID 33 ejcutando `chown -R 33 data/nextcloud/`.
- Base de datos.

  Se usa el contenedor *databse-backup* para esto:
  - Ver qué respaldos hay disponibles con `docker-compose exec database-backup ls /backup`
  - Restaurar alguno con `docker-compose exec database-backup /restore.sh /backup/<DUMP A USAR>`. Si se quiere usaer el último disponible, se puede usar `docker-compose exec database-backup /restore.sh /backup/latest.nextcloud.sql.gz`.

## Collabora
Para comprobar si está ejecutándose se puede ingresar a `https://<DOCUMENT_EDITOR_SUBDOMAIN>.<DOMAIN>`, debe mostrar el mensaje "ok".

Se puede ingresar a `https://<DOCUMENT_EDITOR_SUBDOMAIN>.<DOMAIN>/loleaflet/dist/admin/admin.html` con los datos de acceso definidos en el archivo `.env`.
  
## OnlyOffice  
Para comprobar si está ejecutándose se puede ingresar a `https://<DOCUMENT_EDITOR_SUBDOMAIN>.<DOMAIN>`
  
## Servidor de correo integrado
Se se usa el archivo `docker-compose.mail.yml`, se ejecutará un contenedor con un servidor de correo listo y se agregará la configuración al Nextcloud. En caso de usar el servidor de correo propio, se debe configurar en `https://<NEXTCLOUD_SUBDOMAIN>.<DOMAIN>/settings/admin`.
  
## Usar certificado propio
- Eliminar la variables de entorno `LETSENCRYPT_*` del archivo .
- Copiar en `/home/nextcloud/data/proxy/certs/` los archivos .crt y .key que componen el certificado. El nombre de estos archivos debe ser exactamente igual al nombre del `VIRTUAL_HOST` del servicio, terminado con .crt y .key

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

## Ejecutar comandos OCC
Para usar los comandos de Nextcloud CLI (comandos OCC) se debe ejcutar:

`docker-compose exec --user www-data nextcloud php occ <COMMAND>`
  
## Errores comunes
Los errores más comunes y su solución están en https://github.com/tikoflano/nextcloud/wiki
