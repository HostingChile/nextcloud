# Nextcloud en Hosting.cl
- Se debe deshabilitar SELinux editando el archivo `/etc/selinux/config` y dejando `SELINUX=disabled`, luego reinciar el servidor.
- Se debe habilitar la comuniación entre contenedores en el firewall con `firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=172.18.0.0/16 accept'`, luego reiniciar el firewall y luego reiniciar docker.
- Se debe cambiar el dueño de la carpeta `app/` con el UID:GID 33:33
  
## Habilitar Collabora
Luego de instalar la app, se debe usar la URL https://collabora.hosting.cl en la configuración. Si aparece un mensaje diciendo *Saved with error* se puede ignorar.
  
## Habilitar OnlyOffice
Luego de instalar la app, se debe usar la siguiente configuración (habilitar configuración avanzada):
  - Document Editing Service address: https://onlyoffice.dominio.tld
  - Document Editing Service address for internal requests from the server: https://onlyoffice.dominio.tld
  - Server address for internal requests from the Document Editing Service: https://nextcloud.dominio.tld
