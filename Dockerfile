FROM docker.osgeo.org/geoserver:2.28.0-gdal

# --- Data Directory Setup ---
# Define the path for the data directory
ARG DATA_DIR_PATH="/apps/geoserver/data_dir"
# Set the crucial GeoServer environment variable to point to that path
ENV GEOSERVER_DATA_DIR ${DATA_DIR_PATH}

# Create the directory, copy initial data, and declare the volume
RUN mkdir -p ${GEOSERVER_DATA_DIR}
# NOTE: This assumes a local 'data' folder exists next to the Dockerfile
COPY data ${GEOSERVER_DATA_DIR}/
VOLUME [ "${GEOSERVER_DATA_DIR}" ]


# Copy fonts (path is correct for Temurin image structure)
# NOTE: This assumes a local 'fonts' folder exists next to the Dockerfile
COPY fonts/* /opt/java/openjdk/lib/fonts/

## PLUGINS
ENV PLUGINS="\
    mongodb \
    css \
    vectortiles \
    charts \
    ysdl \
"

# Set GeoServer version
ENV GEOSERVER_VERSION=2.28.x
ENV SOURCEFORGE_BASE_URL=https://build.geoserver.org/geoserver/${GEOSERVER_VERSION}
ENV PLUGIN_PREFIX_URL=${SOURCEFORGE_BASE_URL}/ext-latest/geoserver-2.28-SNAPSHOT


# Loop through the list to download and extract each plugin directly into the
# GeoServer WEB-INF/lib directory.
RUN echo "Downloading and installing plugins..." && \
    mkdir -p /temp/plugins && \
    for p in ${PLUGINS}; do \
        PLUGIN_FILE=${p}-plugin.zip; \
        PLUGIN_URL=${PLUGIN_PREFIX_URL}-${p}-plugin.zip; \
        echo "--> Downloading ${PLUGIN_URL}"; \
        # The curl -L flag is essential to follow the SourceForge redirect
        curl -L ${PLUGIN_URL} -o /temp/plugins/${PLUGIN_FILE} \
        # Extract the contents (the .jar files) into the GeoServer WEB-INF/lib
        && unzip -o /temp/plugins/${PLUGIN_FILE} -d /usr/local/tomcat/webapps/geoserver/WEB-INF/lib \
        # Cleanup the zip file immediately
        && rm /temp/plugins/${PLUGIN_FILE}; \
    done


# Expose the standard Tomcat port
EXPOSE 8080

# Tomcat's default CMD will run the server, which will now use GEOSERVER_DATA_DIR.
CMD ["catalina.sh", "run"]
