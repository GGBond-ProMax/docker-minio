#!/bin/bash

# 设置 MinIO 版本
OLD_MINIO_VERSION="latest"  # 当前 MinIO 版本
NEW_MINIO_VERSION="latest"  # 新的 MinIO 版本（用于升级）

# 容器名称
MINIO_CONTAINER_NAME="minio-server"

# MinIO 端口
MINIO_PORT="9000"
MINIO_CONSOLE_PORT="9001"

# 持久化数据的目录
MINIO_DIR="/minio"
MINIO_DATA_DIR="$MINIO_DIR/data"
MINIO_CONFIG_DIR="$MINIO_DIR/config"

# 备份目录
BACKUP_DIR="$MINIO_DIR/backup"
BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DATA_DIR="$BACKUP_DIR/data_$BACKUP_TIMESTAMP"
BACKUP_CONFIG_DIR="$BACKUP_DIR/config_$BACKUP_TIMESTAMP"

# 备份 MinIO 数据和配置
backup_minio() {
  echo "创建 MinIO 备份目录..."
  sudo mkdir -p $BACKUP_DATA_DIR $BACKUP_CONFIG_DIR
  sudo chmod -R 777 $BACKUP_DIR

  # 检查 MinIO 容器是否运行中
  if [ $(docker ps -q -f name=$MINIO_CONTAINER_NAME) ]; then
      echo "MinIO 容器正在运行，停止容器以进行备份..."
      docker stop $MINIO_CONTAINER_NAME
  fi

  # 备份数据和配置
  echo "备份 MinIO 数据和配置..."
  sudo cp -r $MINIO_DATA_DIR/* $BACKUP_DATA_DIR/
  sudo cp -r $MINIO_CONFIG_DIR/* $BACKUP_CONFIG_DIR/

  # 显示备份完成信息
  echo "备份完成："
  echo "数据备份到 $BACKUP_DATA_DIR"
  echo "配置备份到 $BACKUP_CONFIG_DIR"

  # 重新启动 MinIO 容器
  echo "重启 MinIO 容器中"
  docker start $MINIO_CONTAINER_NAME
}

# 升级 MinIO
upgrade_minio() {
  # 删除旧的 MinIO 容器
  echo "删除旧的 MinIO 容器..."
  docker rm -f $MINIO_CONTAINER_NAME

  # 启动升级后的 MinIO 容器
  echo "启动升级后的 MinIO 容器..."
  docker run -d --name $MINIO_CONTAINER_NAME \
    -p $MINIO_PORT:9000 \
    -p $MINIO_CONSOLE_PORT:9001 \
    -e "MINIO_ROOT_USER=minioadmin" \
    -e "MINIO_ROOT_PASSWORD=minioadmin" \
    -v $MINIO_DATA_DIR:/data \
    -v $MINIO_CONFIG_DIR:/root/.minio \
    minio/minio:$NEW_MINIO_VERSION server /data --console-address ":$MINIO_CONSOLE_PORT"

  # 检查升级是否成功
  if [ $(docker ps -q -f name=$MINIO_CONTAINER_NAME) ]; then
    echo "MinIO 已成功升级到版本 $NEW_MINIO_VERSION"
    echo "MinIO 地址: localhost:$MINIO_PORT"
  else
    echo "MinIO 升级失败，请检查日志。"
    exit 1
  fi
}

# 用户操作选择
echo "请选择要执行的操作："
echo "1) 备份 MinIO"
echo "2) 升级 MinIO"
read -p "输入选项 (1 或 2): " user_choice

if [ "$user_choice" == "1" ]; then
  backup_minio
elif [ "$user_choice" == "2" ]; then
  upgrade_minio
else
  echo "无效的选项，脚本退出。"
  exit 1
fi
