#!/bin/bash

# 设置 MinIO 版本
MINIO_VERSION="latest"

# 检查 Docker 是否安装
if ! [ -x "$(command -v docker)" ]; then
  echo "Error: Docker is not installed." >&2
  echo "[$(date)] Error: Docker is not installed."
  exit 1
fi

# 设置 MinIO 的相关配置
MINIO_CONTAINER_NAME=minio-server
MINIO_USER=minioadmin
MINIO_PASSWORD=minioadmin
MINIO_DIR=/minio
MINIO_DATA_DIR=/minio/data
MINIO_CONFIG_DIR=/minio/config
MINIO_PORT=9000
MINIO_AND_PORT=9001

# 拉取 MinIO 的 Docker 镜像
echo "正在拉取 MinIO Docker 镜像..."
docker pull minio/minio:$MINIO_VERSION

# 创建存储数据和配置的目录
echo "正在创建 MinIO 数据目录和配置目录..."
mkdir -p $MINIO_DATA_DIR
mkdir -p $MINIO_CONFIG_DIR

# 给予目录权限
echo "设定权限"
chmod -R 777 $MINIO_DIR

# 启动临时容器以复制配置文件
echo "正在启动临时容器以复制配置文件..."
docker run -d --name temp-minio \
  -e "MINIO_ROOT_USER=$MINIO_USER" \
  -e "MINIO_ROOT_PASSWORD=$MINIO_PASSWORD" \
  minio/minio:$MINIO_VERSION server /data sleep infinity 

# 从容器中复制配置文件
echo "正在从容器中复制配置文件..."
docker cp temp-minio:/root/.minio $MINIO_CONFIG_DIR

# 停止临时容器
docker stop temp-minio

# 启动 MinIO 容器
echo "正在启动 MinIO 容器..."
docker run -d --name $MINIO_CONTAINER_NAME \
  -p $MINIO_PORT:9000 \
  -p $MINIO_AND_PORT:9001 \
  -e "MINIO_ROOT_USER=$MINIO_USER" \
  -e "MINIO_ROOT_PASSWORD=$MINIO_PASSWORD" \
  -v $MINIO_DATA_DIR:/data \
  -v $MINIO_CONFIG_DIR:/root/.minio \
  minio/minio server /data --console-address ":$MINIO_AND_PORT"

echo "MinIO 正在运行，端口号为 $MINIO_PORT"
echo "使用访问密钥 (Access Key): $MINIO_USER 和秘钥 (Secret Key): $MINIO_PASSWORD 访问 MinIO"

