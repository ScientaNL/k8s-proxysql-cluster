FROM debian:stretch-slim
LABEL maintainer="Scienta <info@scienta.nl>"

ENV PROXYSQL_VERSION "1.4.14"

ENV PROXYSQL_SERVICE proxysql

ENV PROXYSQL_ADMIN_USERNAME cluster1
ENV PROXYSQL_ADMIN_PASSWORD secret1pass

ENV MYSQL_ADMIN_USERNAME root
ENV MYSQL_ADMIN_PASSWORD password

RUN apt-get update && \
    apt-get install -y \
    wget \
    mysql-client \
    gettext-base \
    bsdmainutils && \
    wget https://github.com/sysown/proxysql/releases/download/v${PROXYSQL_VERSION}/proxysql_${PROXYSQL_VERSION}-debian9_amd64.deb -O /tmp/proxysql-${PROXYSQL_VERSION}-debian9_amd64.deb && \
    dpkg -i /tmp/proxysql-${PROXYSQL_VERSION}-debian9_amd64.deb && \
    rm -f /tmp/proxysql-${PROXYSQL_VERSION}-debian9_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

COPY /docker/files/proxysql-k8s-cluster.cnf /etc/proxysql.cnf
COPY /docker/files/entrypoint.sh /entrypoint.sh
COPY /docker/files/cli/ /proxysql-cli

RUN ln -s /proxysql-cli/proxysql-cli.sh /usr/bin/proxysql-cli && \
    chmod +x -R /entrypoint.sh /proxysql-cli /etc/proxysql.cnf

ENV CONFIG_TEMPLATE ""

EXPOSE 6032 6033 6080
ENTRYPOINT [ "/entrypoint.sh" ]
