ARG NGINX_VERSION=1.27.4
ARG NGINX_CACHE_PURGE_VERSION=2.5.3
ARG BROTLI_MODULE_COMMIT=6e975bc

FROM nginx:${NGINX_VERSION}-alpine AS builder

ARG NGINX_VERSION
ARG NGINX_CACHE_PURGE_VERSION

WORKDIR /root/

ARG TARGETPLATFORM

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        ARCHITECTURE="64"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        ARCHITECTURE="arch=armv8-a"; \
    else \
        ARCHITECTURE="64"; \
    fi && \
    apk add --update --no-cache \
        build-base \
        git \
        pcre-dev \
        openssl-dev \
        zlib-dev \
        linux-headers \
        tar \
        cmake && \
    curl -L -o nginx-${NGINX_VERSION}.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zvxf nginx-${NGINX_VERSION}.tar.gz && \
    git clone https://github.com/google/ngx_brotli.git && \
    cd ngx_brotli && \
    git reset --hard ${BROTLI_MODULE_COMMIT} && \
    git submodule update --init --recursive && \
    mkdir -p deps/brotli/out && \
    cd deps/brotli/out && \
    cmake -D CMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
          -D CMAKE_BUILD_TYPE=Release \
          -D BUILD_SHARED_LIBS=OFF \
          -D CMAKE_C_FLAGS="-Ofast -m${ARCHITECTURE} -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
          -D CMAKE_CXX_FLAGS="-Ofast -m${ARCHITECTURE} -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
          -D CMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . --config Release && \
    cmake --build . --config Release --target install && \
    cd ../../../.. && \
    curl -L -o ngx_cache_purge-${NGINX_CACHE_PURGE_VERSION}.tar.gz https://github.com/nginx-modules/ngx_cache_purge/archive/refs/tags/${NGINX_CACHE_PURGE_VERSION}.tar.gz && \
    tar -zvxf ngx_cache_purge-${NGINX_CACHE_PURGE_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --add-dynamic-module=../ngx_brotli \
        --add-dynamic-module=../ngx_cache_purge-${NGINX_CACHE_PURGE_VERSION} \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-cc-opt='-Os -fomit-frame-pointer -g' \
        --with-ld-opt=-Wl,--as-needed,-O1,--sort-common && \
    make modules

FROM nginx:${NGINX_VERSION}-alpine

ARG NGINX_VERSION
ENV CONFD_VERSION=0.16.0

LABEL maintainer="Cedric Michaux <cedric@fullfrontend.be>"

EXPOSE 80

RUN mkdir -p /tmp/cores/

RUN apk --no-cache add bash && \
    apk --no-cache add --virtual .build-deps curl && \
    curl -L -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 && \
    chmod +x /usr/local/bin/confd && \
    apk del .build-deps

COPY --from=builder /root/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_filter_module.so /usr/lib/nginx/modules/
COPY --from=builder /root/nginx-${NGINX_VERSION}/objs/ngx_http_brotli_static_module.so /usr/lib/nginx/modules/
COPY --from=builder /root/nginx-${NGINX_VERSION}/objs/ngx_http_cache_purge_module.so /usr/lib/nginx/modules/

COPY entrypoint.sh /etc/nginx/entrypoint.sh

COPY confd/ /etc/confd

ENTRYPOINT ["/etc/nginx/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]