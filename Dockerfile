FROM nginx:alpine

# Copie la config nginx personnalisée
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copie le contenu web
COPY index.html /usr/share/nginx/html/index.html

# Expose le port 80
EXPOSE 80

# Healthcheck intégré
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/health || exit 1
