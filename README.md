# deploit 💾

A collection of one-click setup scripts to easily self-host your favorite open-source projects using Docker, Nginx, and Let's Encrypt. Deploy with a single command!

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## 🤔 About The Project

Manually setting up self-hosted applications can be a chore. You have to configure the application, set up a database, manage a reverse proxy, and secure it with SSL certificates. **deploit** automates this entire process.

This repository provides simple Bash scripts that handle everything for you:
* Asks for your domain and email.
* Creates a `docker-compose.yml` file for the application.
* Generates an Nginx configuration as a reverse proxy.
* Uses Certbot to get a free SSL certificate from Let's Encrypt.
* Launches your project as a set of Docker containers.

The goal is to get you from a fresh server to a running, secure application in under a minute. 🚀

## ✨ Features

* **Simple & Fast**: Deploy complex applications with a single shell script.
* **Containerized**: Uses **Docker** and **Docker Compose** for clean, isolated, and reproducible environments. 🐳
* **Secure by Default**: Automatically provisions and renews **Let's Encrypt** SSL certificates for HTTPS. 🔒
* **High-Performance**: Uses **Nginx** as a powerful and efficient reverse proxy.
* **Extensible**: Easily add new scripts for any Docker-based application.

## 📋 Prerequisites

Before you begin, ensure you have the following:

1.  **A server** (VPS or dedicated) running a modern Linux distribution (like Ubuntu 22.04).
2.  **A domain name** (`example.com`) with an A record pointing to your server's public IP address.
3.  **Root or `sudo` access** to the server.

## 🚀 Getting Started

Deploying an application is as simple as running one command.

1. **Clone the Repository**

Clone this repository to your server:

```bash
git clone https://github.com/nikdelvin/deploit.git
cd deploit
```

2. **Run the Setup Script**

Navigate to the directory of the project you want to deploy and execute the setup.sh script with sudo.

The script will ask for necessary information, such as:
- Password for your current terminal user if you not a `root` user
- The domain name you want to use (e.g. `app.yourdomain.com`).
- An email address for Let's Encrypt SSL notifications.

```bash
cd directus
bash setup.sh -p password -d domain -e email
```

The script will then configure `Nginx`, get your `SSL` certificate, and launch the application using `Docker Compose`. Once it's done, your application will be live and accessible via HTTPS!

## 📦 Supported Projects

This is a growing collection. Pull requests for new project scripts are welcome!

1. **Directus** - The flexible backend for all your projects 🐰 Turn your DB into a headless CMS, admin panels, or apps with a custom UI, instant APIs, auth & more.
2. **N8N** - Fair-code workflow automation platform with native AI capabilities. Combine visual building with custom code, self-host or cloud, 400+ integrations.

## 🛠️ How It Works

Each project directory contains a `setup.sh` script that acts as the orchestrator.

Here's the typical workflow:
* **User Input:** The script prompts the user for a domain and email address.
* **Configuration:** It uses these variables to create two main configuration files from templates:
    * **`docker-compose.yml`:** Defines the application services, database, and networks.
    * **`nginx.conf`:** An Nginx server block that reverse-proxies traffic from the domain to the application's Docker container.
* **SSL Certificate:** The script uses Dockerized Certbot to request a Let's Encrypt certificate for the specified domain, saving it in a shared volume.
* **Deployment:** Finally, `docker-compose up -d` is called to pull the necessary images and start the application containers in the background.

This approach keeps each application and its configuration neatly isolated.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

If you have a script for a new application you'd like to add, please fork the repo and create a pull request.

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.