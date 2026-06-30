FROM docker.io/kartoza/geoserver:2.28.0

# --- Data Directory Setup ---
ARG DATA_DIR_PATH="/apps/geoserver/data_dir"
ENV GEOSERVER_DATA_DIR ${DATA_DIR_PATH}

# 安装必要依赖，确保 unzip 存在
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        gdal-bin \
        libsqlite3-mod-spatialite \
        unzip \
        curl \
    && rm -rf /var/lib/apt/lists/*

# 创建数据目录
RUN mkdir -p ${GEOSERVER_DATA_DIR}
COPY data ${GEOSERVER_DATA_DIR}/
VOLUME [ "${GEOSERVER_DATA_DIR}" ]

# 拷贝字体
COPY fonts/* /opt/java/openjdk/lib/fonts/

## ---- 插件下载与安装：强行创建父目录，彻底解决 unzip 报错 ----
ENV GEOSERVER_VERSION=2.28.x
ENV PLUGIN_PREFIX_URL=https://build.geoserver.org/geoserver/${GEOSERVER_VERSION}/ext-latest/geoserver-2.28-SNAPSHOT

RUN echo "Downloading and installing plugins..." && \
    # 💡 核心大招 1：不管它原先有没有，强行把 Tomcat 内 GeoServer 的核心类库目录轰出来！
    mkdir -p /usr/local/tomcat/webapps/geoserver/WEB-INF/lib && \
    mkdir -p /temp/plugins && \
    cd /temp/plugins && \
    for p in mongodb css vectortiles charts ysld gdal; do \
        echo "--> Downloading ${p}-plugin..."; \
        PLUGIN_FILE="${p}-plugin.zip"; \
        PLUGIN_URL="${PLUGIN_PREFIX_URL}-${p}-plugin.zip"; \
        curl -L "${PLUGIN_URL}" -o "${PLUGIN_FILE}" && \
        # 💡 核心大招 2：精准解压到刚刚强行创建好的标准目录中
        unzip -o "${PLUGIN_FILE}" -d /usr/local/tomcat/webapps/geoserver/WEB-INF/lib/ && \
        rm -f "${PLUGIN_FILE}"; \
    done && \
    rm -rf /temp/plugins

# 暴露标准端口
EXPOSE 8080

# 保持 Kartoza 官方原生 Entrypoint 启动逻辑，不要破坏它的动态链接和权限分配流程
ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]