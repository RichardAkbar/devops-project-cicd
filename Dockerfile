FROM nginx:stable-alpine


RUN sed -i \
      -e '/^[[:space:]]*user[[:space:]]\+nginx;/d' \
      -e 's|pid[[:space:]]\+/run/nginx.pid;|pid /tmp/nginx.pid;|' \
      -e 's|/var/log/nginx/access.log|/dev/stdout|' \
      -e 's|/var/log/nginx/error.log|/dev/stderr|' \
      /etc/nginx/nginx.conf \
    && sed -i 's|listen[[:space:]]\+80;|listen 8080;|' \
      /etc/nginx/conf.d/default.conf \
    && sed -i '/^[[:space:]]*include \/etc\/nginx\/conf.d\/\*\.conf;/i\
    client_body_temp_path /tmp/nginx/client_temp;\
    proxy_temp_path /tmp/nginx/proxy_temp;\
    fastcgi_temp_path /tmp/nginx/fastcgi_temp;\
    uwsgi_temp_path /tmp/nginx/uwsgi_temp;\
    scgi_temp_path /tmp/nginx/scgi_temp;' \
      /etc/nginx/nginx.conf \
    && mkdir -p /tmp/nginx/client_temp \
                /tmp/nginx/proxy_temp \
                /tmp/nginx/fastcgi_temp \
                /tmp/nginx/uwsgi_temp \
                /tmp/nginx/scgi_temp \
    && chown -R nginx:nginx /tmp/nginx

COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css

USER nginx
EXPOSE 8080
