FROM tomcat:9-jdk11

WORKDIR /temp

ARG DATA_DIR="/apps/geoserver/data_dir"

COPY geoserver /usr/local/tomcat/webapps/geoserver
COPY libs/* /usr/local/tomcat/webapps/geoserver/WEB-INF/lib
COPY fonts/* /opt/java/openjdk/lib/fonts/

RUN mkdir -p ${DATA_DIR}
COPY data ${DATA_DIR}/


VOLUME [ "${DATA_DIR}" ]

# clean up
RUN rm -rf /temp

# expose port 8080
EXPOSE 8080

# start tomcat
CMD ["catalina.sh", "run"]


