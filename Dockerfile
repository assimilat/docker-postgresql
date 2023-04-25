ARG PG_VERSION=latest

FROM postgres:$PG_VERSION as builder

ARG WAL_G_VERSION
ARG PATRONI_VERSION

RUN apt-get update && \
    apt-get install -y \
        python \
        python3 \
        python3-venv \
        python3-yaml \
        python3-requests \
        python3-psycopg2 \
        libpq-dev \
        git \
        wget \
        make \
        gcc \
        postgresql-server-dev-$PG_MAJOR

RUN python3 -m venv --system-site-packages /opt/patroni
RUN /opt/patroni/bin/pip install "patroni==3.0.1"

RUN python3 -m venv --system-site-packages /opt/yacron
RUN /opt/yacron/bin/pip install yacron

RUN mkdir -p /opt/wal-g/bin && \
    cd /opt/wal-g/bin && \
    wget https://github.com/wal-g/wal-g/releases/download/v2.0.1/wal-g-pg-ubuntu-20.04-amd64.tar.gz && \
    tar xvf wal-g-pg-ubuntu-20.04-amd64.tar.gz && \
    mv wal-g-pg-ubuntu-20.04-amd64 wal-g && \
    rm *.tar.gz

FROM postgres:$PG_VERSION

RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-venv \
        python3-yaml \
        python3-requests \
        python3-psycopg2 \
        pgbackrest \
        barman \
        dumb-init \
        curl \
        daemontools \
        liblz4-tool \
        less \
        vim \
        lzop \
        sshpass \
        pv \
        gettext-base

ARG CITUS_VERSION

RUN curl https://install.citusdata.com/community/deb.sh | bash && \
    apt-get install -y postgresql-$PG_MAJOR-citus-$CITUS_VERSION

COPY setup_db.sh /docker-entrypoint-initdb.d/setup_db.sh

COPY psql pg_dump pg_dumpall wal-g /usr/local/bin/

COPY scripts/ /postgresql-scripts/

COPY --from=builder /opt/wal-g/ /opt/wal-g/

COPY --from=builder /opt/patroni/ /opt/patroni/

RUN ln -s /opt/patroni/bin/patroni /usr/local/bin && \
    ln -s /opt/patroni/bin/patronictl /usr/local/bin

COPY --from=builder /opt/yacron/ /opt/yacron/

RUN ln -s /opt/yacron/bin/yacron /usr/local/bin

RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq
