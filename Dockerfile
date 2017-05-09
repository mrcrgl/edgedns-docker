FROM debian:sid-slim

RUN useradd -ms /bin/bash dns

WORKDIR /home/dns/

ADD docker-entrypoint.sh /

ADD https://github.com/jedisct1/edgedns/releases/download/0.2.2/edgedns-0.2.2-x86_64-unknown-linux-gnu.tar.gz .

RUN tar -xzf edgedns-0.2.2-x86_64-unknown-linux-gnu.tar.gz && \
    rm edgedns-0.2.2-x86_64-unknown-linux-gnu.tar.gz && \
    mv edgedns /usr/local/bin/


USER dns
ADD edgedns.toml /home/dns/edgedns.toml

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["edgedns", "--config", "/home/dns/edgedns.toml"]
