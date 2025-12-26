FROM billbear-cn-shanghai.cr.volces.com/base/nginx:1.27.1
ADD main.js /etc/nginx/njs/main.js
ADD nginx.conf.template /etc/nginx/nginx.conf.template
CMD ["/bin/bash", "-c", "envsubst '$GITLAB_TOKEN' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
