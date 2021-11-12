#
# Aerospike Server Dockerfile
#
# http://github.com/aerospike/aerospike-server.docker
#
# This docker file is compatible with Aerospike Community Edition. It provides Java and Python environments and access to the Aerospike DB.
FROM jupyter/base-notebook:python-3.8.6

USER root

ENV AEROSPIKE_VERSION 5.6.0.5
ENV AEROSPIKE_SHA256 defa39f96d5068f69d1e4d187fa20d7f4095966c9eac80b1e1de30c15cd0c651
ENV LOGFILE /var/log/aerospike/aerospike.log


ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}
USER root
RUN chown -R ${NB_UID} ${HOME}

# BEGIN TEST

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone

RUN sudo apt-get update\
  && sudo apt-get install build-essential -y\
  && sudo apt-get install git -y
  
# spark notebook
RUN mkdir /opt/spark-nb; cd /opt/spark-nb\
  && wget -qO- https://javadl.oracle.com/webapps/download/AutoDL?BundleId=245467_4d5417147a92418ea8b615e228bb6935 | tar -xvz\
  && wget -qO- https://archive.apache.org/dist/spark/spark-3.0.0/spark-3.0.0-bin-hadoop3.2.tgz | tar -xvz\
  && pip install findspark numpy pandas matplotlib sklearn\
  && wget https://docs.aerospike.com/artifacts/aerospike-spark/3.1.0/aerospike-spark-assembly-3.1.0.jar

# js kernel
#RUN apt-get update\
#  && apt-get install nodejs npm\
#  && npm install -g --unsafe-perm ijavascript\
#  && ijsinstall --install=global

#RUN sudo apt-get update -y\
#  && apt-get install nodejs npm\
#  && npm config set prefix "/home/jovyan" \
#  && npm install -g ijavascript\
#  && ijsinstall

# c# kernel

# c kernel
#RUN pip install jupyter-c-kernel\
#  && install_c_kernel

# go kernel
#RUN wget -O go.tgz https://golang.org/dl/go1.17.3.linux-amd64.tar.gz\
#  && tar -C /usr/local -xzf go.tgz
#ENV PATH=$PATH:/usr/local/go/bin
#ENV GO111MODULE=on
#RUN go install github.com/gopherdata/gophernotes@v0.7.3\
#  && go get github.com/aerospike/aerospike-client-go/v5
#RUN mkdir -p ~/.local/share/jupyter/kernels/gophernotes\
#  && cd ~/.local/share/jupyter/kernels/gophernotes\
#  && cp $(go env GOPATH)/pkg/mod/github.com/gopherdata/gophernotes@v0.7.3/kernel/* "."\
#  && sed "s_gophernotes_$(go env GOPATH)/bin/gophernotes_" <kernel.json.in >kernel.json
#fix dependencies
#RUN cd $(go env GOPATH)/pkg/mod/github.com/aerospike/aerospike-client-go/v5@v5.6.0\
#  && go get -u\
#  && go mod tidy
#RUN cd $(go env GOPATH)/pkg/mod/github.com/go-zeromq/zmq4@v0.13.0\
#  && go get -u\
#  && go mod tidy
#RUN cd $(go env GOPATH)/pkg/mod/github.com/gopherdata/gophernotes@v0.7.3\  
#  && go get -u\
#  && go mod tidy
# END TEST

# install jupyter notebook extensions, and enable these extensions by default: table of content, collapsible headers, and scratchpad
RUN pip install jupyter_contrib_nbextensions\
  && jupyter contrib nbextension install --sys-prefix\
  && jupyter nbextension enable toc2/main --sys-prefix\
  && jupyter nbextension enable collapsible_headings/main --sys-prefix\
  && jupyter nbextension enable scratchpad/main --sys-prefix
  
RUN sudo apt install vim -y

RUN  mkdir /var/run/aerospike\
  && apt-get update -y \
  && apt-get install software-properties-common dirmngr gpg-agent -y --no-install-recommends\
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9 \
  && apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main' \
  && apt-get install -y --no-install-recommends build-essential wget lua5.2 gettext-base libldap-dev curl unzip python python3-pip python3-dev python3 zulu-11\
  && wget "https://www.aerospike.com/artifacts/aerospike-server-enterprise/${AEROSPIKE_VERSION}/aerospike-server-enterprise-${AEROSPIKE_VERSION}-ubuntu20.04.tgz" -O aerospike-server.tgz \  
  && echo "$AEROSPIKE_SHA256 *aerospike-server.tgz" | sha256sum -c - \
  && mkdir aerospike \
  && tar xzf aerospike-server.tgz --strip-components=1 -C aerospike \
  && dpkg -i aerospike/aerospike-server-*.deb \
  && dpkg -i aerospike/aerospike-tools-*.deb \
  && wget https://github.com/aerospike/aerospike-loader/releases/asloader-2.3.5.ubuntu20.04.amd64.deb -O aerospike/asloader.deb \  
  && dbpkg -i aerospike/asloader.deb \
  && pip install --no-cache-dir aerospike\
  && pip install --no-cache-dir pymongo\
  && wget "https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip" -O ijava-kernel.zip\
  && unzip ijava-kernel.zip -d ijava-kernel \
  && python3 ijava-kernel/install.py --sys-prefix\
  && rm ijava-kernel.zip\
  && rm -rf aerospike-server.tgz aerospike /var/lib/apt/lists/* \
  && rm -rf /opt/aerospike/lib/java \
  && apt-get purge -y \
  && apt autoremove -y \
  && mkdir -p /var/log/aerospike  
  
COPY aerospike /etc/init.d/
RUN usermod -a -G aerospike ${NB_USER}

# Add the Aerospike configuration specific to this dockerfile
COPY aerospike.template.conf /etc/aerospike/aerospike.template.conf
COPY aerospike.conf /etc/aerospike/aerospike.conf
COPY features.conf /etc/aerospike/features.conf

RUN chown -R ${NB_UID} /etc/aerospike
RUN chown -R ${NB_UID} /opt/aerospike
RUN chown -R ${NB_UID} /var/log/aerospike
RUN chown -R ${NB_UID} /var/run/aerospike

#RUN fix-permissions /etc/aerospike/
#RUN fix-permissions /var/log/aerospike

COPY notebooks* /home/${NB_USER}/notebooks
RUN echo "Versions:" > /home/${NB_USER}/notebooks/README.md
RUN python -V >> /home/${NB_USER}/notebooks/README.md
RUN java -version 2>> /home/${NB_USER}/notebooks/README.md
RUN asd --version >> /home/${NB_USER}/notebooks/README.md
RUN echo -e "Aerospike Python Client `pip show aerospike|grep Version|sed -e 's/Version://g'`" >> /home/${NB_USER}/notebooks/README.md
RUN echo -e "Aerospike Java Client 5.0.0" >> /home/${NB_USER}/notebooks/README.md

COPY jupyter_notebook_config.py /home/${NB_USER}/
RUN  fix-permissions /home/${NB_USER}/

# I don't know why this has to be like this 
# rather than overiding
COPY entrypoint.sh /usr/local/bin/start-notebook.sh
#I had to do this to get the container to launch, not sure what I was doing wrong
RUN chmod +x /usr/local/bin/start-notebook.sh
WORKDIR /home/${NB_USER}/notebooks  
USER ${NB_USER}
