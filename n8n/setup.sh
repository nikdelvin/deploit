#!/bin/bash

DOMAIN=""
PASSWORD=""
OPTIONS="p:u:d:h:r"

while getopts "$OPTIONS" OPT; do
    case $OPT in
        p)
            PASSWORD="$OPTARG"
            ;;
        d)
            DOMAIN="$OPTARG"
            ;;
        h)
            echo -e "\e[32mSETUP PROCESS >>>\e[0m Usage: $0 -p <password> -d <domain>"
            echo "  -p <password>: Specifies the current user password."
            echo "  -d <domain>: Specifies domain name for NGINX config."
            exit 0
            ;;
        r)
            echo -e "\e[31mREMOVAL PROCESS >>>\e[0m This command execution will remove all N8N data from this machine including:"
            echo -e "\e[33m1.\e[0m Docker volumes, images and containers" 
            echo -e "\e[33m2.\e[0m Dockerfile folder and it's contains"
            echo -e "\e[33m3.\e[0m Nginx configaration for workflow.$DOMAIN"
            echo -e "\e[33m4.\e[0m Let's Encrypt SSL certificates for workflow.$DOMAIN"
            while true; do
                read -p "Do you want to proceed? (yes/no) " yn
                case $yn in
                    [Yy]* ) 
                        echo "Proceeding..."
                        cd /var/www/n8n
                        echo $PASSWORD | sudo docker compose down --volumes --rmi all
                        sudo rm -rf /var/www/n8n
                        sudo certbot --non-interactive delete --cert-name workflow.$DOMAIN
                        sudo rm -rf /etc/nginx/sites-enabled/workflow.$DOMAIN.conf
                        echo -e "\e[31mREMOVAL PROCESS >>>\e[0m Completed"
                        exit 0
                        ;;
                    [Nn]* ) echo "Exiting..."; exit 0;;
                    * ) echo "Invalid input. Please answer 'yes' or 'no'.";;
                esac
            done
            ;;
        \?)
            echo -e "\e[31mSETUP ERROR >>>\e[0m Invalid option -$OPTARG" >&2
            echo "Use -h for help." >&2
            exit 1
            ;;
        :)
            echo -e "\e[31mSETUP ERROR >>>\e[0m Option -$OPTARG requires an argument." >&2
            echo "Use -h for help." >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$PASSWORD" ]; then
    echo -e "\e[31mSETUP ERROR >>>\e[0m Current user password (-p) is required." >&2
    echo "Use -h for help." >&2
    exit 1
fi
if [ -z "$DOMAIN" ]; then
    echo -e "\e[31mSETUP ERROR >>>\e[0m Domain name (-d) is required." >&2
    echo "Use -h for help." >&2
    exit 1
fi

echo -e "\e[32mSETUP INITIALIZATION >>>\e[0m Please be ensure that before start this initialization you created all necessary DNS records for your domain:"
echo -e "\e[33m1.\e[0m workflow.$DOMAIN"
echo -e "\e[32mSETUP PROCESS >>>\e[0m Started"
echo $PASSWORD | sudo -S apt update
sudo apt upgrade -y
echo -e "\e[32mSETUP PROCESS >>>\e[0m Installing NGINX..."
sudo apt install -y nginx
echo -e "\e[32mSETUP PROCESS >>>\e[0m Working with UFW Rules..."
sudo ufw allow 'OpenSSH'
sudo ufw allow 'Nginx Full'
echo -e "\e[32mSETUP PROCESS >>>\e[0m Enabling UFW..."
echo "y" | sudo ufw enable
sudo chown -R $USER /etc/nginx/sites-enabled
sudo chown -R $USER /var/www
echo -e "\e[32mSETUP PROCESS >>>\e[0m Installing Docker..."
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo -e "\e[32mSETUP PROCESS >>>\e[0m Testing Docker Installation..."
DOCKER_INSTALLATION_RESULT=$(sudo docker run hello-world | \
    grep "This message shows that your installation appears to be working correctly.")
if [[ -n "$DOCKER_INSTALLATION_RESULT" ]]; then
    echo -e "\e[32mSETUP PROCESS >>>\e[0m Docker Installation completed"
else
    echo -e "\e[31mSETUP ERROR >>>\e[0m Docker Installation not completed"
    exit 1
fi
echo -e "\e[32mSETUP PROCESS >>>\e[0m Installing n8n..."
cd /var/www
mkdir n8n
cd n8n
curl -O https://raw.githubusercontent.com/n8n-io/n8n-hosting/main/docker-compose/withPostgresAndWorker/docker-compose.yml
curl -o init-data.sh https://raw.githubusercontent.com/n8n-io/n8n-hosting/main/docker-compose/withPostgresAndWorker/init-data.sh
POSTGRES_USER=root
POSTGRES_PASSWORD=$(openssl rand -base64 16)
POSTGRES_DB=n8n
POSTGRES_NON_ROOT_USER="$USER"
POSTGRES_NON_ROOT_PASSWORD=$(openssl rand -base64 16)
ENCRYPTION_KEY=$(openssl rand -base64 16)
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
N8N_RUNNERS_ENABLED=true
echo -e "POSTGRES_USER=\"root\"\nPOSTGRES_PASSWORD=\"$POSTGRES_PASSWORD\"\nPOSTGRES_DB=\"n8n\"\nPOSTGRES_NON_ROOT_USER=\"$USER\"\nPOSTGRES_NON_ROOT_PASSWORD=\"$POSTGRES_NON_ROOT_PASSWORD\"\nENCRYPTION_KEY=\"$ENCRYPTION_KEY\"\nN8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true\nN8N_RUNNERS_ENABLED=true" > .env
sudo docker compose --env-file .env up -d
echo -e "\e[32mSETUP PROCESS >>>\e[0m Waiting for N8N deploy to be completed..."
sleep 60
N8N_DEPLOY_RESULT=$(curl http://127.0.0.1:5678/setup | \
    grep "n8n")
if [[ -n "$N8N_DEPLOY_RESULT" ]]; then
    echo -e "\e[32mSETUP PROCESS >>>\e[0m N8N deploy completed"
else
    echo -e "\e[31mSETUP ERROR >>>\e[0m N8N deploy not completed"
    exit 1
fi
echo -e "\e[32mSETUP PROCESS >>>\e[0m Configuring NGINX for n8n..."
cd /etc/nginx/sites-enabled
echo -e "server {\n\tserver_name workflow.$DOMAIN;\n\tlocation / {\n\t\tproxy_pass http://127.0.0.1:5678;\n\t}\n\tlisten [::]:80;\n}" > "workflow.$DOMAIN.conf"
echo -e "\e[32mSETUP PROCESS >>>\e[0m Installing Certbot for NGINX..."
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --non-interactive --agree-tos --nginx -d "workflow.$DOMAIN"
sudo service nginx restart
echo -e "\e[32mSETUP PROCESS >>>\e[0m Waiting for DNS deploy to be completed..."
sleep 60
NGINX_SETUP_RESULT=$(curl https://workflow.$DOMAIN/setup | \
    grep "n8n")
if [[ -n "$NGINX_SETUP_RESULT" ]]; then
    echo -e "\e[32mSETUP PROCESS >>>\e[0m N8N DNS deploy completed"
else
    echo -e "\e[31mSETUP ERROR >>>\e[0m N8N DNS deploy not completed"
    exit 1
fi
echo -e "\e[32mSETUP COMPLETED >>>\e[0m All is set! Go ahead and visit https://workflow.$DOMAIN"