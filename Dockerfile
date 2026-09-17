# Must match kartoza tag and GitHub build-arg GEOSERVER_VERSION_ARG (not 2.28.x nightlies).
ARG GEOSERVER_VERSION_ARG=2.28.0
FROM docker.io/kartoza/geoserver:${GEOSERVER_VERSION_ARG}

ARG GEOSERVER_VERSION_ARG
ENV GEOSERVER_VERSION=${GEOSERVER_VERSION_ARG}

# --- Data Directory Setup ---
# Define the path for the data directory
ARG DATA_DIR_PATH="/apps/geoserver/data_dir"
# Set the crucial GeoServer environment variable to point to that path
ENV GEOSERVER_DATA_DIR ${DATA_DIR_PATH}

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        gdal-bin \
        libsqlite3-mod-spatialite \
    && rm -rf /var/lib/apt/lists/*

# Create the directory, copy initial data, and declare the volume
RUN mkdir -p ${GEOSERVER_DATA_DIR}
# NOTE: This assumes a local 'data' folder exists next to the Dockerfile
COPY data ${GEOSERVER_DATA_DIR}/
VOLUME [ "${GEOSERVER_DATA_DIR}" ]


# Copy fonts (path is correct for Temurin image structure)
# NOTE: This assumes a local 'fonts' folder exists next to the Dockerfile
COPY fonts/* /opt/java/openjdk/lib/fonts/

# Extra plugins from the kartoza image's /stable_plugins (same 2.28.0 as the war).
# Do not download 2.28.x SNAPSHOT zips: unzip -o leaves gs-foo-2.28.0.jar next to
# gs-foo-2.28-SNAPSHOT.jar and GeoServer fails to start (vectortiles / MetaTilingOutputFormat).
# vectortiles and gdal are already in the kartoza war — do not install again.
ENV PLUGINS="mongodb css charts ysld"

RUN set -eu; \
    lib=/usr/local/tomcat/webapps/geoserver/WEB-INF/lib; \
    for p in ${PLUGINS}; do \
        zip=/stable_plugins/${p}-plugin.zip; \
        if [ ! -f "${zip}" ]; then echo "missing ${zip}" >&2; exit 1; fi; \
        echo "--> ${zip}"; \
        unzip -Z -1 "${zip}" | grep '\.jar$' | while read -r jar; do \
            prefix=$(basename "${jar}" | sed -E 's/(-[0-9].*)\.jar$//'); \
            rm -f "${lib}/${prefix}-"*.jar; \
        done; \
        unzip -j -o "${zip}" '*.jar' -d "${lib}"; \
    done


# Expose the standard Tomcat port
EXPOSE 8080

# Tomcat's default CMD will run the server, which will now use GEOSERVER_DATA_DIR.
CMD ["catalina.sh", "run"]
