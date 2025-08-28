# 1. Check Ubuntu Version
lsb_release -a

# Example output: -----------
# No LSB modules are available.
# Distributor ID:	Ubuntu
# Description:	Ubuntu 22.04.2 LTS
# Release:	22.04
# Codename:	jammy
# -----------

# This script is only functional for 
# Update local registry

# 2. Add MongoDB GPG Key
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

# 3. Add the APT source
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# 4. Update package list.
sudo apt update

# 5. Install MongoDB.
sudo apt install -y mongodb-org

# 6. Start & Enable MongoDB.
sudo systemctl start mongod
sudo systemctl enable mongod

# 7. Update IP for External Access
vim /etc/mongod.conf
# Update these lines 
# net:
#   bindIp: 0.0.0.0
#   port: 27017

# 8. Open port on firewall
sudo ufw allow 27017/tcp

