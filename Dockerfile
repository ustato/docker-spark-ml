FROM openjdk:8-jre
MAINTAINER ustato "https://github.com/ustato"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends apt-utils \
 && apt-get install -y locales \
  build-essential \
  curl \
  git \
  libbz2-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  llvm \
  make \
  tk-dev \
  wget \
  xz-utils \
  zlib1g-dev \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \\
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create user for Spark
RUN useradd -ms /bin/bash spark
RUN useradd -ms /bin/bash hadoop

# HADOOP
ENV HADOOP_VERSION 3.1.1
ENV HADOOP_HOME /opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:$HADOOP_HOME/lib/native
RUN wget -q -O- --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | tar -xz -C /opt/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R hadoop:hadoop $HADOOP_HOME

# SPARK
ENV SPARK_VERSION 2.4.4
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop2.7
ENV SPARK_HOME /home/spark
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN wget -q -O- --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 \
  "http://mirrors.advancedhosters.com/apache/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | tar xz --strip 1 -C $SPARK_HOME/ \
  && chown -R spark:spark $SPARK_HOME

# Python
### pyenv install
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/bin:$PATH
ARG PYTHON_VERSION=anaconda3-5.3.1
RUN curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer \
  | bash
ENV PATH=$HOME/.pyenv/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv.git /tmp/pyenv && \
  cd /tmp/pyenv/plugins/python-build && \
  ./install.sh && \
  rm -rf /tmp/pyenv
RUN python-build $PYTHON_VERSION /usr/local/
RUN if command pip >/dev/null 2>&1; then \
  echo "pip already installed. Skipping manual installation."; \
  else \
  echo "Installing pip manually"; \
  curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
  chmod 755 /tmp/get-pip.py && \
  /tmp/get-pip.py && \
  rm /tmp/get-pip.py; \
  fi
RUN pip install pipenv

### add script and data
RUN mkdir /home/worker
ADD src /home/worker/src
ADD data /home/worker/data

# Launch
USER root
WORKDIR $SPARK_HOME
CMD ["su", "-c", "bin/spark-class org.apache.spark.deploy.master.Master", "spark"]
