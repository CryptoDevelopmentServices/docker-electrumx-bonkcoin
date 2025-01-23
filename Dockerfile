FROM python:3.8

WORKDIR /root/

# Install necessary dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y libleveldb-dev curl gpg ca-certificates tar dirmngr openssl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and verify Shibacoin binaries
RUN curl -Lk -o shibacoin-1.0.3.0-linux.tar.gz https://github.com/shibacoinppc/shibacoin/releases/download/v1.0.3.0/shibacoin-1.0.3.0-linux.tar.gz && \
    tar -xvf shibacoin-1.0.3.0-linux.tar.gz && \
    rm shibacoin-1.0.3.0-linux.tar.gz && \
    install -m 0755 -o root -g root -t /usr/local/bin shibacoin-1.0.3.0-linux/* && \
    rm -rf shibacoin-1.0.3.0-linux

# Install Python modules
RUN pip install uvloop

# Clone and use ElectrumX server repository
RUN git clone --branch main https://github.com/CryptoDevelopmentServices/docker-electrumx-shibacoin.git && \
    cd docker-electrumx-shibacoin && \
    cp -r electrumx /usr/local/lib/python3.8/dist-packages/ && \
    pip install -r requirements.txt && \
    cd .. && rm -rf docker-electrumx-shibacoin

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Prepare Shibacoin configuration
RUN mkdir -p /root/.shibacoin
COPY shibacoin.conf /root/.shibacoin/shibacoin.conf

# Generate placeholder SSL certificates (replace with real ones in production)
RUN mkdir -p /data && \
    openssl req -x509 -newkey rsa:2048 -keyout /data/electrumx-shibacoin.key -out /data/electrumx-shibacoin.crt -days 365 -nodes -subj "/CN=localhost"

# Define persistent storage volume
VOLUME ["/data"]

# Define environment variables
ENV HOME /data
ENV ALLOW_ROOT 1
ENV COIN=Shibacoin
ENV DAEMON_URL=http://shibacoin:noicabihs@127.0.0.1:22555
ENV EVENT_LOOP_POLICY uvloop
ENV DB_DIRECTORY /data
ENV SERVICES=tcp://:50001,ssl://:50002,wss://:50004,rpc://0.0.0.0:8000
ENV SSL_CERTFILE=${DB_DIRECTORY}/electrumx-shibacoin.crt
ENV SSL_KEYFILE=${DB_DIRECTORY}/electrumx-shibacoin.key
ENV HOST ""

WORKDIR /data

# Expose necessary ports
EXPOSE 50001 50002 50004 8000

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
