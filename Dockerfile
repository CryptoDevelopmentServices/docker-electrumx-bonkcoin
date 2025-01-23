FROM python:3.8

WORKDIR /root/

RUN apt-get update && apt-get upgrade && apt-get install -y libleveldb-dev curl gpg ca-certificates tar dirmngr

RUN curl -o shibacoin-1.0.3.0-linux.tar.gz -Lk https://github.com/shibacoinppc/shibacoin/releases/download/v1.0.3.0/shibacoin-1.0.3.0-linux.tar.gz

RUN tar -xvf shibacoin-1.0.3.0-linux.tar.gz

RUN rm shibacoin-1.0.3.0-linux.tar.gz

RUN install -m 0755 -o root -g root -t /usr/local/bin shibacoin-1.0.3.0/bin/*

RUN pip install uvloop

RUN git clone https://github.com/CryptoDevelopmentServices/docker-electrumx-shibacoin.git \
    && cd electrumx-shibacoin \
    && pip3 install .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /root/.shibacoin
COPY shibacoin.conf /root/.shibacoin/shibacoin.conf

VOLUME ["/data"]

ENV HOME /data
ENV ALLOW_ROOT 1
ENV COIN=Pepecoin
ENV DAEMON_URL=http://pepe:epep@127.0.0.1:22555
ENV EVENT_LOOP_POLICY uvloop
ENV DB_DIRECTORY /data
ENV SERVICES=tcp://:50001,ssl://:50002,wss://:50004,rpc://0.0.0.0:8000
ENV SSL_CERTFILE ${DB_DIRECTORY}/electrumx-shibacoin.crt
ENV SSL_KEYFILE ${DB_DIRECTORY}/electrumx-shibacoin.key
ENV HOST ""

WORKDIR /data

EXPOSE 50001 50002 50004 8000

ENTRYPOINT ["/entrypoint.sh"]