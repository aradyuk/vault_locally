#!/bin/bash 

inface=eth0
ver=0.10.3
pub_ip=$(ip a | grep $inface | grep inet | cut -d "t" -f2 | cut -d "/" -f1)
pub_ip="$(echo -e "${pub_ip}" | tr -d '[:space:]')"

# Download and unarchieve:
cd /opt/
sudo wget https://releases.hashicorp.com/vault/"$ver"/vault_"$ver"_linux_amd64.zip
sudo unzip vault_"$ver"_linux_amd64.zip -d .

sudo cp vault /usr/bin/

# Folder structure:
for i in "/etc/vault" "/vault-data" "/logs/vault/"; do sudo mkdir -p $i; done 

# Conf file:
sudo cat <<EOF > /etc/vault/config.json
{
"listener": [{
"tcp": {
"address" : "0.0.0.0:8200",
"tls_disable" : 1
}
}],
"api_addr": "http://$pub_ip:8200",
"storage": {
    "file": {
    "path" : "/vault-data"
    }
 },
"max_lease_ttl": "10h",
"default_lease_ttl": "10h",
"ui":true
}
EOF

# Vault service:
sudo cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=vault service
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/config.json
 
[Service]
EnvironmentFile=-/etc/sysconfig/vault
Environment=GOMAXPROCS=2
Restart=on-failure
ExecStart=/usr/bin/vault server -config=/etc/vault/config.json
StandardOutput=/logs/vault/output.log
StandardError=/logs/vault/error.log
LimitMEMLOCK=infinity
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
 
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start vault.service
sudo systemctl status vault.service
sudo systemctl enable vault.service

export VAULT_ADDR=http://"$pub_ip":8200
echo "export VAULT_ADDR=http://"$pub_ip":8200" >> ~/.bashrc

vault status

