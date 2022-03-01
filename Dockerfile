FROM ubuntu:20.04

LABEL maintainer=FreeTAKTeam

ARG FTS_VERSION=1.9.8
ARG FTS_UI_VERSION=1.9.8
ARG FTS_MAP_VERSION=0.2.5
ARG FTS_RTSP_VERSION=0.17.17
# UTC for buildtimes
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime

#APT
RUN apt-get update && \
    apt-get install -y unzip wget nano libssl-dev libffi-dev curl python3 python3-pip libxml2-dev libxslt-dev python3-lxml python3-dev python3-setuptools build-essential &&\
    rm -rf /var/lib/apt/lists/*


#PIP3
RUN pip3 install supervisor &&\
    pip3 install requests &&\
    pip3 install flask_login &&\
    pip3 install FreeTAKServer==${FTS_VERSION} && \
    pip3 install FreeTAKServer-UI==${FTS_UI_VERSION} && \
    pip3 install defusedxml &&\
    pip3 install pyopenssl &&\
    pip3 install pytak &&\
#    pip3 install itsdangerous==2.0.1 &&\
#    pip3 install markupsafe==2.0.1


#MAP
RUN /bin/sh -c wget https://github.com/FreeTAKTeam/FreeTAKHub/releases/download/v${FTS_MAP_VERSION}/FTH-webmap-linux-${FTS_MAP_VERSION}.zip     -O /opt/FTH-webmap-linux-${FTS_MAP_VERSION}.zip &&\
    cd /opt &&\
    unzip /opt/FTH-webmap-linux-${FTS_MAP_VERSION}.zip &&\
    mv /opt/FTH-webmap-linux-${FTS_MAP_VERSION} /opt/FTH-webmap-linux &&\
    chmod a+x /opt/FTH-webmap-linux &&\
    echo '{ "BOT_TOKEN": "Example123", "FTH_FTS_URL": "127.0.0.1", "ChatId": "example123", "FTH_FTS_API_Auth": "exampleauth", "FTH_FTS_API_Port": 19023, "FTH_FTS_TCP_Port": 8087 }' > /opt/config.json

#RTSP
RUN wget "https://github.com/aler9/rtsp-simple-server/releases/download/v0.17.17/rtsp-simple-server_v0.17.17_linux_amd64.tar.gz"      -O /opt/rtsp-simple-server_v0.17.17_linux_amd64.tar.gz &&\ 
    cd /opt &&\
    tar -xzf rtsp-simple-server_v0.17.17_linux_amd64.tar.gz &&\
    chmod a+x /opt/rtsp-simple-server
#RTSP Config
# 
COPY rtsp-simple-server.yml /opt/rtsp-simple-server.yml
# Create FTS user
RUN addgroup --gid 1000 fts && \
    adduser --disabled-password --uid 1000 --ingroup fts --home /home/fts fts

# Supervisord conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Logrotation
COPY ftsrotate /etc/logrotate.d/ftsrotate

COPY fatalexit /usr/local/bin/fatalexit
RUN  chmod +x /usr/local/bin/fatalexit


# Start script
# This handles env variables and starts the service
COPY start-fts.sh /start-fts.sh
RUN chmod +x /start-fts.sh

# FTS ports
EXPOSE 8080
EXPOSE 8087
EXPOSE 8089
EXPOSE 8443
EXPOSE 19023
# FTS UI port
EXPOSE 5000
# FTS MAP port
EXPOSE 800
#FTS RTSP SERVER ports
EXPOSE 8554
EXPOSE 1935
EXPOSE 8888
EXPOSE 9997
# UI Config changes
RUN sed -i 's/root/data/g' /usr/local/lib/python3.8/dist-packages/FreeTAKServer-UI/config.py &&\
    sed -i 's+certpath = .*+certpath = "/data/certs/"+g' /usr/local/lib/python3.8/dist-packages/FreeTAKServer-UI/config.py  &&\
    #Adjust database path
    sed -i 's/data\/FTSDataBase.db/data\/database\/FTSDataBase.db/g' /usr/local/lib/python3.8/dist-packages/FreeTAKServer-UI/config.py &&\
    chmod 777 /usr/local/lib/python3.8/dist-packages/FreeTAKServer-UI/config.py &&\
    chmod 777 /usr/local/lib/python3.8/dist-packages/FreeTAKServer-UI/

# FTS MainConfig changes
RUN sed -i 's+first_start = .*+first_start = False+g' /usr/local/lib/python3.8/dist-packages/FreeTAKServer/controllers/configuration/MainConfig.py   &&\
    sed -i 's/\r$//' /start-fts.sh

VOLUME ["/data"]
COPY FTSConfig.yaml /opt/FTSConfig.yaml

ENV IP=127.0.0.1
ENV APPIP=0.0.0.0

# Use non root user
# TODO: Folder perms
#USER fts



ENTRYPOINT ["/bin/bash", "/start-fts.sh"]
