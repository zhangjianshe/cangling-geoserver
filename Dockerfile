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

# Expose the standard Tomcat port
EXPOSE 8080

# Tomcat's default CMD will run the server, which will now use GEOSERVER_DATA_DIR.
CMD ["catalina.sh", "run"]
