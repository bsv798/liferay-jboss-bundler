FROM openshift/openjdk18-openshift

USER root

ENV \
    ELASTIC_HOME=${ELASTIC_HOME}

ARG \
	ELASTIC_TEMP=/tmp/elasticsearch.zip

RUN useradd -r elastic

RUN \
    mkdir "${ELASTIC_HOME}" && \
    curl -Lo "${ELASTIC_TEMP}" "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}.zip" && \
	unzip -q -o -d "${ELASTIC_HOME}" "${ELASTIC_TEMP}" && \
	mkdir -p "${ELASTIC_HOME}" && \
	mv "${ELASTIC_HOME}/elasticsearch-$ELASTIC_VERSION"/* "${ELASTIC_HOME}" && \
	rm -rf "${ELASTIC_HOME}/elasticsearch-${ELASTIC_VERSION}" && \
	rm -rf "${ELASTIC_TEMP}"

COPY "elasticsearch.yml" "${ELASTIC_HOME}/config"

RUN \
	"${ELASTIC_HOME}/bin/elasticsearch-plugin" install analysis-icu && \
	"${ELASTIC_HOME}/bin/elasticsearch-plugin" install analysis-kuromoji && \
	"${ELASTIC_HOME}/bin/elasticsearch-plugin" install analysis-smartcn && \
	"${ELASTIC_HOME}/bin/elasticsearch-plugin" install analysis-stempel

RUN chown -R elastic ${ELASTIC_HOME} && \
	chgrp -R root ${ELASTIC_HOME} && \
	chmod -R g+rw ${ELASTIC_HOME}

EXPOSE 9200 9300

USER elastic

CMD exec "${ELASTIC_HOME}/bin/elasticsearch"
