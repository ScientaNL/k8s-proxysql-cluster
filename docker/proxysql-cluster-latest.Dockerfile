FROM alpine:latest
LABEL maintainer="Scienta <info@scienta.nl>"

ENV TAG "v1.4.13"
ENV NOJEMALLOC 1

RUN mkdir /build && \
    cd /build && \
    apk update && \
    apk add build-base automake bzip2 patch git cmake openssl-dev libc6-compat && \
    apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/main libexecinfo-dev && \
    git clone https://github.com/sysown/proxysql.git && \
    cd proxysql && \
    git checkout ${TAG} && \
    make

FROM alpine:latest
LABEL maintainer="Scienta <info@scienta.nl>"

COPY --from=0 /build/proxysql/src /proxysql

RUN apk update && \
    apk add libgcc libstdc++ openssl-dev mysql-client && \
    ln -s /proxysql/proxysql /usr/bin

EXPOSE 3306 6032

ENTRYPOINT ["proxysql", "-f"]