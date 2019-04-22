# Nextcloud en Hosting.cl
- Se debe deshabilitar SELinux editando el archivo `/etc/selinux/config` y dejando `SELINUX=disabled`, luego reinciar el servidor.
- Se debe habilitar la comuniación entre contenedores en el firewall con `firewall-cmd --permanent --zone=public --add-rich-rule='rule family=ipv4 source address=172.20.0.0/16 accept'`, luego reiniciar el firewall y luego reiniciar docker.
- Se debe cambiar el dueño de la carpeta `app/` con el UID:GID 33:33 (Al parecer no, creo que al tener SELinux deshabilitado esto se hace solo)
  
## Habilitar Collabora
Luego de instalar la app, se debe usar la URL https://collabora.dominio.tld en la configuración. Si aparece un mensaje diciendo *Saved with error* se puede ignorar.
  
## Habilitar OnlyOffice
Luego de instalar la app, se debe usar la siguiente configuración (habilitar configuración avanzada):
  - Document Editing Service address: https://onlyoffice.dominio.tld
  - Document Editing Service address for internal requests from the server: https://onlyoffice.dominio.tld
  - Server address for internal requests from the Document Editing Service: https://nextcloud.dominio.tld
  
## Errores comunes
1. Al entrar al sitio aparece com no seguro. Luego al ver el certificado en el navegador dice emitido por y para letsencrypt-nginx-proxy-companion.
  Esto ocurre porque el servicio que provee los ceritificados aun no lo ha emitido. Posibles razones:
  - Aun esta trabajando en eso. Puede tardar unos 5 minutos.
  - El subdominio nextcloud.dominio.tld aun no responde públicamente a la IP del servidor.
  - Se ha alcanzado el límite de certificados gratuitos posibles para emitir por Let's Encrypt (https://letsencrypt.org/docs/rate-limits/). 
2. Al entrar a https://collabora.hosting.cl/ aparece **502 Bad Gateway**.
  Es muy probable que sea que el servicio de Collabora aun no termina de arrancar. Puede tardar unos 5 - 10 minutos.
