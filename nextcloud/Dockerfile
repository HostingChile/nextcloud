FROM nextcloud:latest

COPY setup.sh /

RUN sed -i '$i/bin/bash /setup.sh' /entrypoint.sh && chmod +x /setup.sh
