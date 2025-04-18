#!/bin/bash

if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    sudo apt update
    sudo apt install -y pwgen
    sudo apt install -y docker.io docker-compose
fi

read -p "OwnCloud Domain (örneğin: backup.csadigital.net): " DOMAIN
read -p "Admin Kullanıcı Adı: " ADMIN_USERNAME
read -p "Admin Şifresi: " ADMIN_PASSWORD

DB_USER=$(pwgen -s 12 1)
DB_PASS=$(pwgen -s 16 1)
ROOT_PASS=$(pwgen -s 16 1)

echo "Veritabanı Kullanıcı Adı: $DB_USER"
echo "Veritabanı Şifresi: $DB_PASS"
echo "Root Şifresi: $ROOT_PASS"

mkdir -p ~/owncloud && cd ~/owncloud

cat <<EOF > docker-compose.yml
version: '3.7'
services:
  owncloud-db:
    image: mariadb:10.5
    container_name: owncloud-db
    environment:
      MYSQL_ROOT_PASSWORD: $ROOT_PASS
      MYSQL_PASSWORD: $DB_PASS
      MYSQL_DATABASE: owncloud
      MYSQL_USER: $DB_USER
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - owncloud-network
    restart: unless-stopped

  owncloud:
    image: owncloud/server
    container_name: owncloud
    environment:
      - OWNCLOUD_DOMAIN=$DOMAIN
      - OWNCLOUD_DB_TYPE=mysql
      - OWNCLOUD_DB_NAME=owncloud
      - OWNCLOUD_DB_USERNAME=$DB_USER
      - OWNCLOUD_DB_PASSWORD=$DB_PASS
      - OWNCLOUD_DB_HOST=owncloud-db
      - OWNCLOUD_ADMIN_USERNAME=$ADMIN_USERNAME
      - OWNCLOUD_ADMIN_PASSWORD=$ADMIN_PASSWORD
      - OWNCLOUD_DATA_DIR=/var/www/html/data
    volumes:
      - owncloud_data:/var/www/html
    ports:
      - "8080:8080"
    depends_on:
      - owncloud-db
    networks:
      - owncloud-network
    restart: unless-stopped

volumes:
  db_data:
  owncloud_data:

networks:
  owncloud-network:
    driver: bridge
EOF

sudo docker-compose up -d

echo "OwnCloud kurulumu başlatıldı. Web arayüzüne erişmek için http://$DOMAIN:8080 veya https://$DOMAIN adresine gidin."
