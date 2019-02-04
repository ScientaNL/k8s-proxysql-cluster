FROM debian:jessie-slim
LABEL maintainer="Scienta <info@scienta.nl>"

ENV VERSION "2.0.1"

RUN apt-get update && \
    apt-get install -y \
    wget \
    mysql-client \
    openssl \
    libev-dev \
    bsdmainutils && \
    wget https://github.com/sysown/proxysql/releases/download/v${VERSION}/proxysql_${VERSION}-debian8_amd64.deb -O /tmp/proxysql-${VERSION}-debian8_amd64.deb && \
    dpkg -i /tmp/proxysql-${VERSION}-debian8_amd64.deb && \
    rm -f /tmp/proxysql-${VERSION}-debian8_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

COPY ./files/proxysql-k8s-cluster.cnf /etc/proxysql.cnf
COPY ./files/entrypoint.sh /entrypoint.sh
COPY ./files/cli/ /proxysql-cli
COPY ./files/data /var/lib/proxysql-data

RUN ln -s /proxysql-cli/proxysql-cli.sh /usr/bin/proxysql-cli && \
    chmod +x -R /entrypoint.sh /proxysql-cli /etc/proxysql.cnf

EXPOSE 6032 6033
ENTRYPOINT [ "/entrypoint.sh" ]
