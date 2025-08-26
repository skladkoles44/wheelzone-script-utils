#!/bin/bash
# uuid: 2025-08-26T13:19:27+03:00-3657037809
# title: install_loki_kernel.sh
# component: .
# updated_at: 2025-08-26T13:19:27+03:00

set -e

echo "[+] Updating system..."
apt update && apt upgrade -y
apt install -y git python3 python3-pip python3-venv gnupg nginx docker.io docker-compose

echo "[+] Creating directory structure..."
mkdir -p ~/wheelzone/{logs/{chatlog,chatend,todo,done,insights,events},vault/{encrypted,archives},wiki/{entries,assets,csv_imports},api,scripts,ci,security/gpg_keys,ui/wiki_ui}
cd ~/wheelzone && git init

echo "[+] Generating GPG key..."
gpg --quick-gen-key "Loki Kernel" default default never
KEY_ID=$(gpg --list-secret-keys --with-colons | grep ^sec | cut -d: -f5 | head -n1)
gpg --export-secret-key -a "$KEY_ID" > ~/wheelzone/security/gpg_keys/private.key
chmod 600 ~/wheelzone/security/gpg_keys/private.key

echo "[+] Setting up Python API (Flask)..."
cd ~/wheelzone/api
python3 -m venv venv
source venv/bin/activate
pip install flask markdown pyyaml python-dotenv
deactivate

echo "[+] Configuring nginx..."
cat > /etc/nginx/sites-available/wheelzone <<NGINX
server {
    listen 80;
    server_name wheelzone.local;
    location / {
        proxy_pass http://localhost:5000;
    }
}
NGINX
ln -sf /etc/nginx/sites-available/wheelzone /etc/nginx/sites-enabled/wheelzone
systemctl restart nginx

echo "[+] Setup complete. Loki Kernel installed."
