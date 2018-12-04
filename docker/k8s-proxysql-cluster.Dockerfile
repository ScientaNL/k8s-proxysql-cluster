FROM debian:stretch-slim
LABEL maintainer="Scienta <info@scienta.nl>"

ENV TAG "1.4.13"

RUN apt-get update && \
    apt-get install -y wget mysql-client && \
    wget https://github.com/sysown/proxysql/releases/download/v${TAG}/proxysql_${TAG}-debian9_amd64.deb -O /tmp/proxysql.deb && \
    dpkg -i /tmp/proxysql.deb && \
    rm -f /tmp/proxysql.deb && \
    rm -rf /var/lib/apt/lists/*

COPY ./files/init-k8s-cluster.sh /init-k8s-cluster.sh
COPY ./files/proxysql-k8s-cluster.cnf /proxysql-k8s-cluster.cnf
COPY ./files/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /init-k8s-cluster.sh

EXPOSE 6032 6033
ENTRYPOINT [ "/entrypoint.sh" ]