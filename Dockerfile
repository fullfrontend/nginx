FROM nginx:stable-alpine

MAINTAINER Cedric Michaux <cedric@fullfrontend.eu>

EXPOSE 80

COPY entrypoint.sh /etc/nginx/entrypoint.sh
COPY confd/ /etc/confd

ENV CONFD_VERSION 0.16.0

RUN \
    apk add --update curl bash && \
    curl -L -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 && \
    chmod +x /usr/local/bin/confd


ENTRYPOINT ["/etc/nginx/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
