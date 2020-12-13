# Build Quix backend
FROM ubuntu:20.04 as build

ARG SBT_VERSION=1.4.1

RUN \
  apt-get update && \
  apt-get -y install curl \
  default-jdk && \
  curl -L -o sbt-$SBT_VERSION.deb https://dl.bintray.com/sbt/debian/sbt-$SBT_VERSION.deb && \
  dpkg -i sbt-$SBT_VERSION.deb && \
  rm sbt-$SBT_VERSION.deb && \
  apt-get install sbt && \
  sbt sbtVersion -Dsbt.rootdir=true;

WORKDIR /quix-backend

COPY /quix-backend/build.sbt .
COPY /quix-backend/version.sbt .
RUN sbt update -Dsbt.rootdir=true;
COPY /quix-backend/quix-webapps/quix-web-spring/pom.xml ./quix-webapps/quix-web-spring/pom.xml
RUN \
    apt -y install maven && \
    mvn -B -f /quix-backend/quix-webapps/quix-web-spring/pom.xml dependency:resolve --fail-never

COPY /quix-backend/quix-api/src ./quix-api/src
COPY /quix-backend/quix-core/src ./quix-core/src
COPY /quix-backend/quix-modules/quix-presto-module/src ./quix-modules/quix-presto-module/src
COPY /quix-backend/quix-modules/quix-athena-module/src ./quix-modules/quix-athena-module/src
COPY /quix-backend/quix-modules/quix-bigquery-module/src ./quix-modules/quix-bigquery-module/src
COPY /quix-backend/quix-modules/quix-jdbc-module/src ./quix-modules/quix-jdbc-module/src
COPY /quix-backend/quix-modules/quix-python-module/src ./quix-modules/quix-python-module/src
COPY /quix-backend/quix-modules/quix-dummy-module/src ./quix-modules/quix-dummy-module/src
COPY /quix-backend/quix-webapps/quix-web-spring/src ./quix-webapps/quix-web-spring/src

RUN sbt +publishM2 -Dsbt.rootdir=true;
RUN mvn -f /quix-backend/quix-webapps/quix-web-spring/pom.xml install -DskipTests

# Build Quix frontend
FROM node:10-buster as build2

WORKDIR /
COPY ./quix-frontend ./
WORKDIR /client
RUN npm install
WORKDIR /shared
RUN npm install
WORKDIR /service
RUN npm install
RUN npm run build
WORKDIR /shared
RUN npm prune --production
WORKDIR /service
RUN npm prune --production

# ---------------------------------------------------------------------------------
FROM ubuntu:20.04

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8

# Presto
ENV JAVA_HOME /usr/lib/jvm/zulu11
ENV LANG en_US.UTF-8
RUN \
    set -xeu && \
    apt-get update && \
    apt-get -y install default-jdk && \
    mkdir -p /usr/lib/presto /data/presto /var/presto/data/var

COPY ./presto-server-346 /usr/lib/presto
COPY ./presto-aerospike.properties /usr/lib/presto/etc/aerospike.properties.template
RUN chmod -R 0777 /usr/lib/presto /var/presto

# MySQL
RUN apt-get -y install mysql-server

# Quix backend
RUN apt-get update && \
  apt-get install -q -y --no-install-recommends \
  python3 \
  python-dev \
  python3-dev \
  python3-pip \
  libsnappy-dev \
  language-pack-en \
  build-essential \
  wget \
  gettext\
  && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache --upgrade pip setuptools wheel py4j

WORKDIR /quix-webapps/quix-web-spring
COPY /quix-backend/lib/aerospike-jdbc-driver-all-1.0-SNAPSHOT.jar ./

COPY --from=build /quix-backend/quix-webapps/quix-web-spring/target/quix-web-spring-*.jar ./quix.jar

RUN wget -q -P BOOT-INF/lib/ \
    https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.10/postgresql-42.2.10.jar \
    https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.19/mysql-connector-java-8.0.19.jar \
    https://repo1.maven.org/maven2/io/prestosql/presto-jdbc/346/presto-jdbc-346.jar

RUN jar uf0 quix.jar \
    BOOT-INF/lib/postgresql-42.2.10.jar \
    BOOT-INF/lib/mysql-connector-java-8.0.19.jar \
    BOOT-INF/lib/presto-jdbc-346.jar \
    aerospike-jdbc-driver-all-1.0-SNAPSHOT.jar

# Quix frontend
COPY --from=build2 /shared /shared
COPY --from=build2 /service /service

RUN apt-get update && \
    apt-get -y install nodejs npm iputils-ping net-tools && \
    rm -f .env || true && \
    npm install -g pm2


EXPOSE 3000
EXPOSE 8081

WORKDIR /service
COPY ./entrypoint.sh .
COPY ./.env .
RUN chmod -R 0777 ./entrypoint.sh

# entrypoint
CMD ["./entrypoint.sh"]