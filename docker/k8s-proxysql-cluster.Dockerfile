FROM debian:stretch-slim
LABEL maintainer="Scienta <info@scienta.nl>"

ENV VERSION "2.0.0"
ENV STATE "rc2"

RUN apt-get update && \
    apt-get install -y wget mysql-client bsdmainutils && \
    wget https://github.com/sysown/proxysql/releases/download/v${VERSION}-${STATE}/proxysql-${STATE}_${VERSION}-debian9_amd64.deb -O /tmp/proxysql-${VERSION}-debian9_amd64.deb && \
    dpkg -i /tmp/proxysql-${VERSION}-debian9_amd64.deb && \
    rm -f /tmp/proxysql-${VERSION}-debian9_amd64.deb && \
    rm -rf /var/lib/apt/lists/*
#
COPY ./files/proxysql-k8s-cluster.cnf /etc/proxysql.cnf
COPY ./files/entrypoint.sh /entrypoint.sh
COPY ./files/cli/ /proxysql-cli
COPY ./files/data /var/lib/proxysql-data

RUN ln -s /proxysql-cli/proxysql-cli.sh /usr/bin/proxysql-cli

RUN chmod +x -R /entrypoint.sh /files/cli /etc/proxysql.cnf

EXPOSE 6032 6033
ENTRYPOINT [ "/entrypoint.sh" ]
