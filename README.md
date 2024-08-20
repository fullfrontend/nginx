# nginx

nginx image configured with [Confd](https://github.com/kelseyhightower/confd). This image is meant to run behind a 
load balancer like [Traefik](https://traefik.io/)

/!\ Since I need to use [Brotli](https://en.wikipedia.org/wiki/Brotli) compression algorithm, NGINX is compiled with 
it available, enjoy!

## How to use this image

This image is made to be used in conjunction with a php-fpm image [like mine]
(https://github.com/fullfrontend/php-fpm)

I use docker compose to handle my stack so here is my nginx config:
```
nginx:
    image: fullfrontend/nginx
    ports:
        - 80
        
    environment:
        PHP_UPSTREAM: "php-runner:9000"
        VIRTUAL_HOST: "fullfrontend.dev"
        DOCUMENT_ROOT: "/var/www/fullfrontend/"

    volumes_from:
        - application
```

## Environment variables

* PHP_UPSTREAM: where is running php-fpm
* VIRTUAL_HOST: host name to respond to
* DOCUMENT_ROOT: where the files are located

## Example
A Full working example using docker-compose is available in the [example](example) folder
