#!/bin/sh

mkdir bundler > /dev/null 2>&1

cp -u ../../standalone/liferay_wildfly_bundler.sh bundler
cp -u -r ../../standalone/bin bundler

docker build --build-arg APPSERVER_TYPE="wildfly" \
             --build-arg APPSERVER_VERSION="13.0.0.Final" \
             --build-arg LIFERAY_PREFIX="liferay-ce-portal" \
             --build-arg LIFERAY_FULL_VERSION="7.1.0-ga1-20180703012531655" \
             --build-arg LIFERAY_HOME="/opt/liferay" \
             --build-arg APPSERVER_HOME_PATH="/opt/wildfly" \
             --build-arg APPSERVER_DOWNLOAD_URL="http://download.jboss.org/wildfly/13.0.0.Final/wildfly-13.0.0.Final.zip" \
             --build-arg LIFERAY_BASE_URL="https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.1.0%20GA1" \
             --build-arg LIFERAY_COPY_CLUSTER_PATH="/bundler/t m p/cluster" \
             --build-arg LIFERAY_TURN_OFF_LOGGING="true" \
             --build-arg JDBC_DRIVER_DOWNLOAD_URL="https://jdbc.postgresql.org/download/postgresql-42.2.4.jar" \
             --build-arg JDBC_DRIVER_CLASSNAME="org.postgresql.Driver" \
             --build-arg JDBC_DRIVER_CONNECTION_URL="jdbc:postgresql:ddd" \
             --build-arg JDBC_DRIVER_USERNAME="postgres" \
             --build-arg JDBC_DRIVER_PASSWORD="postgres" \
             --build-arg JDBC_CREDENTIAL_STORE_PASSWORD="change_cs_pass" \
             --build-arg MAIL_CREDENTIAL_STORE_PASSWORD="cs_pass" \
             --build-arg MAIL_HOST="smtp.yandex.ru" \
             --build-arg MAIL_PORT="465" \
             --build-arg MAIL_USERNAME="yandex@yandex.ru" \
             --build-arg MAIL_PASSWORD="mail_pass" \
             --build-arg MAIL_ENABLE_SSL="true" \
             --build-arg MAIL_ENABLE_TLS="false" \
             --build-arg PROMETHEUS_DOWNLOAD_URL="http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar" \
             --build-arg PROMETHEUS_COPY_CONFIG_PATH="/bundler/t m p/prometheus/config.yaml" \
             --build-arg ELASTIC_TRANSPORT_ADDRESSES="127.0.0.1:9300" \
             --build-arg ELASTIC_CLUSTER_NAME="clustery_mcclusterface" \
             --tag ljb .

# docker rm $(docker ps -a -q)
# docker rmi -f $(docker images --filter "dangling=true" -q --no-trunc)
# docker rmi ljb:latest

# docker run -p 8181:8080 \
#            -p 8282:8443 \
#            -p 9779:9779 \
#            -p 8787:8787 \
#            -e JDBC_DRIVER_CLASSNAME="org.postgresql.Driver" \
#            -e JDBC_DRIVER_CONNECTION_URL="jdbc:postgresql://192.168.1.111/ddd" \
#            -e JDBC_DRIVER_USERNAME="postgres" \
#            -e JDBC_DRIVER_PASSWORD="postgres" \
#            -e MAIL_USERNAME="segeysarge@yandex.ru" \
#            -e MAIL_PASSWORD="MBX7srWLEHscBwiD" \
#            -e ELASTIC_TRANSPORT_ADDRESSES="192.168.1.111:9300" \
#            -e ELASTIC_CLUSTER_NAME="clustery_mcclusterface" \
#            -e DEBUG="true" \
#            -i -a stdout ljb
