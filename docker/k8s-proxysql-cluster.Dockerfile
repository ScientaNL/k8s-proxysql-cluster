FROM debian:stretch-slim
LABEL maintainer="Scienta <info@scienta.nl>"

ENV VERSION "2.0.0"
ENV STATE "rc2"

RUN apt-get update && \
    apt-get install -y wget mysql-client && \
    wget https://github.com/sysown/proxysql/releases/download/v${VERSION}-${STATE}/proxysql-${STATE}_${VERSION}-debian9_amd64.deb -O /tmp/proxysql-${VERSION}-debian9_amd64.deb && \
    dpkg -i /tmp/proxysql-${VERSION}-debian9_amd64.deb && \
    rm -f /tmp/proxysql-${VERSION}-debian9_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 6032 6033

COPY ./files/init-k8s-cluster.sh /init-k8s-cluster.sh
COPY ./files/proxysql-k8s-cluster.cnf /proxysql-k8s-cluster.cnf
COPY ./files/entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]