## VARIABLES
PRIVATE_IP=$(ip -o -4 addr show dev eth1 | cut -d ' ' -f 7 | cut -f 1 -d '/')

## Update server
apt-get update && apt-get dist-upgrade -y

## Change SSH port to 10022, PasswordAuthentication=no
sed -i "s/#Port=22 .*/Port 10022/" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
test -e /etc/init.d/ssh && /etc/init.d/ssh restart

## Modify fstab
DISK_ID=$(lsblk -io NAME,TYPE,MOUNTPOINT | grep -v "[SWAP]" | grep disk | awk '{print $1;}')
DISK_TYPE=$(cat /sys/block/"$DISK_ID"/queue/rotational)
if [ "$DISK_TYPE" = "1" ];
then
    echo "Modifying fstab for rotational disk"
    sed -i 's/errors=remount-ro/errors=remount-ro,noatime/g' /etc/fstab
    sed -i 's/defaults/defaults,noatime/g' /etc/fstab
else
    echo "Modifying fstab for SSD disk"
    sed -i 's/errors=remount-ro/errors=remount-ro,noatime,discard/g' /etc/fstab
    sed -i 's/defaults/defaults,noatime,discard/g' /etc/fstab
fi

## Setup timezone & NTP
timedatectl set-timezone Asia/Kolkata
timedatectl set-ntp on

## Setup Swap & tune swap usage for server
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
sysctl -w vm.swappiness=10
sysctl -w vm.vfs_cache_pressure=50
echo 'vm.swappiness=10' >> tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> tee -a /etc/sysctl.conf

## Install basic packages vim-nox curl unzip software-properties-common build-essential ntp
apt-get install -y vim-nox curl unzip build-essential ntp

## Setup PHP
add-apt-repository ppa:ondrej/php
apt-get update && apt-get install -y php7.4-fpm php7.4-cli php7.4-dev php-mongodb php-pear php7.4-curl php-intl php-json php7.4-mcrypt php7.4-mysql php-zip php-common php7.4-opcache php-readline php7.4-xml php-imagick php-imap composer

## Setup Nginx
# Add the mainline release
wget -q https://nginx.org/keys/nginx_signing.key -O - | apt-key add -
echo "deb http://nginx.org/packages/mainline/ubuntu/ bionic nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx" > /etc/apt/sources.list.d/nginx.list
apt-get update && apt-get install nginx

## Todo Copy SSL Certificates

# Generate dhparam
openssl dhparam -out /etc/nginx/dhparam.pem

# Increase File Limit
cat >> /etc/security/limits.conf <<EOF
www-data soft nofile 65535
www-data hard nofile 65535
EOF

## Increase File size and Connection limits
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/override.conf <<EOF
[Service]
LimitNOFILE=100000
EOF
systemctl daemon-reload
systemctl restart nginx.service

cat >> /etc/sysctl.conf <<EOF

# Tuning system for large number of connections
fs.file-max = 70000
net.ipv4.tcp_max_syn_backlog = 100000
net.core.somaxconn = 100000
net.core.netdev_max_backlog = 100000
net.ipv4.ip_local_port_range=1024 65535
EOF
sysctl -p

## Setup Google Chrome for E-Receipt Service
wget -q https://dl-ssl.google.com/linux/linux_signing_key.pub -O - | apt-key add -
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
apt-get update && apt-get install -y google-chrome-unstable

## Setup Nodejs
curl -sL https://deb.nodesource.com/setup_16.x | bash -
apt-get update && apt-get install -y nodejs

# Set NODE_ENV and PM2_HOME environment variables
cat >> /etc/environment <<EOF
NODE_ENV=production
PM2_HOME=/etc/pm2/
EOF

## Setup PM2
npm i -g pm2@latest
mkdir -p /etc/pm2/


## Clone Repositories
mkdir -p /var/www
cd /var/www
git clone git@gitlab.com:letzchange/donor-frontend
cd /var/www/donor-frontend
npm i && npm run build
git clone git@gitlab.com:letzchange/campaigns
cd /var/www/campaigns
find ./ -maxdepth 2 -type f -name 'package.json' -execdir npm i \;
find ./ -maxdepth 2 -type f -name 'package.json' -execdir npm run build \;
git clone git@gitlab.com:letzchange/platform-services
## Install all node_modules
cd /var/www/platform-services
find ./ -maxdepth 2 -type f -name 'package.json' -execdir npm i \;
## Install PHP dependencies
cd /var/www/platform-services/donation-service/
composer install

git clone git@gitlab.com:letzchange/donation-frontend
cd /var/www/donation-frontend
npm i && npm run build -- --env=prod
git clone git@gitlab.com:letzchange/nonprofit-dashboard
cd /var/www/nonprofit-dashboard
npm i && npm run build

## Run Services on boot
pm2 startOrRestart /etc/pm2/pm2-ecosystem.json
pm2 save
pm2 startup
systemctl enable nginx.service
systemctl enable php7.4-fpm.service

## Setup Crontab
cat > /tmp/crontab <<EOF

0 0 * * * /root/sync-groups-gapps.sh

# Clear tmp dir
0 0 */7 * * find /tmp -maxdepth 1 -mtime +7 -print0 | xargs -n 100 -0 rm -r
EOF
crontab /tmp/crontab

