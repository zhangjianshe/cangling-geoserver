# ==============================================================================
# 1. BUILDER STAGE: Download and Extract GeoServer WAR and Plugins
# ==============================================================================
FROM eclipse-temurin:17-jdk-jammy AS builder

# Set GeoServer version
ENV GEOSERVER_VERSION=2.28.x
ENV SOURCEFORGE_BASE_URL=https://build.geoserver.org/geoserver/${GEOSERVER_VERSION}
ENV PLUGIN_PREFIX_URL=${SOURCEFORGE_BASE_URL}/ext-latest/geoserver-2.28-SNAPSHOT

# Install necessary utilities (curl, unzip) and clean up apt cache
RUN apt-get update && apt-get install -y --no-install-recommends unzip curl \
    gdal-bin \
    libgdal-dev \
    && rm -rf /var/lib/apt/lists/* \

# Temporary working directory for downloads and extraction
WORKDIR /temp

# --- Download and Extract GeoServer WAR ---
RUN echo "Downloading GeoServer WAR..." && \
    curl -L ${SOURCEFORGE_BASE_URL}/geoserver-${GEOSERVER_VERSION}-latest-war.zip -o geoserver.zip \
    && unzip geoserver.zip -d . \
    && unzip geoserver.war -d geoserver \
    && rm geoserver.zip geoserver.war

# --- Download and Extract Plugins ---
# List of plugin short names (the part between GEOSERVER_VERSION and -plugin.zip)
ENV PLUGINS="\
    app-schema \
    authkey \
    cas \
    charts \
    control-flow \
    css \
    csw-iso \
    csw \
    db2 \
    dxf \
    excel \
    feature-pregeneralized \
    geopkg-output \
    grib \
    gwc-s3 \
    h2 \
    iau \
    importer \
    inspire \
    jp2k \
    libjpeg-turbo \
    mapml \
    mbstyle \
    metadata \
    mongodb \
    monitor \
    ogcapi-features \
    ogr-wfs \
    ogr-wps \
    params-extractor \
    printing \
    pyramid \
    querylayer \
    rat \
    sldservice \
    vectortiles \
    wcs2_0-eo \
    web-resource \
    wmts-multi-dimensional \
    ysld \
    gdal \
    wps \
"

  #     wps-cluster-hazelcast \
  #    wps-download \
  #    wps-excel \
  #    wps-jdbc \
  #    wps \
  #    mysql \
  #    netcdf-out \
  #    netcdf \
  #    gdal \
     #    geofence \
     #    geofence-server-h2 \
     #    geofence-server-postgres \
     #    geofence-wps \
     #    sqlserver \
     #    oracle \

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
        && unzip -o /temp/plugins/${PLUGIN_FILE} -d /temp/geoserver/WEB-INF/lib \
        # Cleanup the zip file immediately
        && rm /temp/plugins/${PLUGIN_FILE}; \
    done

# ==============================================================================
# 2. RUNTIME STAGE: Deploy the customized GeoServer WAR
# ==============================================================================
# Use a lightweight official Tomcat image as the base for the final image.
FROM tomcat:9.0-jdk17-temurin-jammy

# Remove default Tomcat webapps for a clean install
RUN rm -rf /usr/local/tomcat/webapps/*

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

# Copy the fully prepared GeoServer web application from the builder stage
# The 'geoserver' directory is the expanded WAR file containing all plugins.
COPY --from=builder /temp/geoserver /usr/local/tomcat/webapps/geoserver

# Copy fonts (path is correct for Temurin image structure)
# NOTE: This assumes a local 'fonts' folder exists next to the Dockerfile
COPY fonts/* /opt/java/openjdk/lib/fonts/

# Expose the standard Tomcat port
EXPOSE 8080

# Tomcat's default CMD will run the server, which will now use GEOSERVER_DATA_DIR.
CMD ["catalina.sh", "run"]
