# nginx

[![](https://images.microbadger.com/badges/version/he8us/nginx.svg)](http://microbadger.com/images/he8us/nginx "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/he8us/nginx.svg)](http://microbadger.com/images/he8us/nginx "Get your own image badge on microbadger.com")

nginx image configured with [Confd](https://github.com/kelseyhightower/confd)

## How to use this image

This image is made to be used in conjunction with an other php-fpm image. You can see mine for my prod server on [it's repo](https://github.com/he8us/php-fpm-prod)

I use docker compose to handle my stack so here is my nginx config:

    nginx:
        image: he8us/nginx
        ports:
            - 80
        environment:
            VIRTUAL_HOST: he8us.dev
            DOCUMENT_ROOT: /var/www/he8us/
            LOG_FILE: he8us
    
        links:
            - myPhpEntry:php
            
        volumes_from:
            - application

