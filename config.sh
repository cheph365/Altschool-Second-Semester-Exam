#!/bin/bash
# variables
mysql_root_password="Altschool2023"
laravel_db="laravel_db"
# Update and upgrade the server
sudo apt-get update
sudo apt-get upgrade -y
# Install Apache and SSH pass
sudo apt-get install apache2 -y
sudo apt-get install sshpass -y
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
# Allow Apache through firewall
sudo ufw allow in "Apache Full"
# Install MySQL Server and provide a password for the root user
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get install mysql-server -y
# Secure MySQL
# sudo mysql_secure_installation
# Set the MySQL root password and create database
sudo mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_root_password';
CREATE DATABASE $laravel_db;
EOF
# Install PHP 8.2 and some common extensions
sudo apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common
echo | sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install php8.2 php8.2-common php8.2-mysql php8.2-xml php8.2-xmlrpc php8.2-curl php8.2-gd php8.2-imagick php8.2-cli php8.2-dev php8.2-imap php8.2-mbstring php8.2-opcache php8.2-soap php8.2-zip php8.0-intl -y
sudo echo "<?php phpinfo(); ?>" > /var/www/html/info.php
# install composer for Laravel
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
# Increase PHP memory limit for the duration of the composer install
sudo sed -i 's/memory_limit = .*/memory_limit = -1/' /etc/php/8.2/apache2/php.ini
# Start and enable Apache
sudo systemctl start apache2
sudo systemctl enable apache2
composer clearcache 
composer selfupdate

# Create and Change the ownership of the Laravel directory
sudo mkdir -p /var/www/laravel
sudo chown -R www-data:www-data /var/www/laravel
# Clone the Laravel application from GitHub
sudo -u www-data git clone https://github.com/laravel/laravel.git /var/www/laravel
# Navigate to the Laravel app directory
sudo chown -R "$USER" /var/www/laravel
cd /var/www/laravel || exit
# Install Composer dependencies with increased memory limit
php -d memory_limit=-1 /usr/bin/composer install
# Restore the original PHP memory limit
sudo sed -i 's/memory_limit = -1/memory_limit = 128M/' /etc/php/8.2/apache2/php.ini
# Create a .env file
cp .env.example .env
# Update the .env file with the database connection settings
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$laravel_db/g" /var/www/laravel/.env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$mysql_root_password/g" /var/www/laravel/.env
# Generate an application key
php artisan key:generate
# Create a virtual host configuration for Apache
sudo tee /etc/apache2/sites-available/laravel.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/laravel/public
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/laravel/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
# Enable the Laravel site and disable the default Apache site
sudo a2ensite laravel
sudo a2dissite 000-default
# Reload Apache to apply changes
sudo systemctl reload apache2
# migrate database and tables
php artisan migrate
# Display installation completed message
echo "Laravel application has been deployed and configured successfully!"

# Install Ansible
sudo apt-get update
sudo apt-get install -y ansible

# Switch to Vagrant user to Create the ansible folder containing the host inventory and playbook
sudo -iu vagrant bash << 'EOF'
mkdir -p ansible && cd ansible
cat > host-inventory << 'EOL'
[slave]
192.168.56.12
EOL

export ANSIBLE_INVENTORY=/root/host-inventory

cat > playbook.yml << 'EOL'
---
- name: Deploy LAMP Stack on Slave
  hosts: slave
  become: yes
  tasks:
    - name: Copy the bash script to the Slave
      copy:
        src: /home/vagrant/config.sh
        dest: /home/vagrant/config.sh
        mode: '0744'

    - name: Execute the bash script
      shell: "bash /home/vagrant/config.sh"
EOL
EOF
cd /home/vagrant/ansible || exit
cat > config.sh << 'EOL'
#!/bin/bash
# variables
mysql_root_password="Altschool2023"
laravel_db="laravel_db"
# Update and upgrade the server
sudo apt-get update
sudo apt-get upgrade -y
# Install Apache and SSH pass
sudo apt-get install apache2 -y
sudo apt-get install sshpass -y
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
# Allow Apache through firewall
sudo ufw allow in "Apache Full"
# Install MySQL Server and provide a password for the root user
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get install mysql-server -y
# Secure MySQL
# sudo mysql_secure_installation
# Set the MySQL root password and create database
sudo mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_root_password';
CREATE DATABASE $laravel_db;
EOF
# Install PHP 8.2 and some common extensions
sudo apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common
echo | sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install php8.2 php8.2-common php8.2-mysql php8.2-xml php8.2-xmlrpc php8.2-curl php8.2-gd php8.2-imagick php8.2-cli php8.2-dev php8.2-imap php8.2-mbstring php8.2-opcache php8.2-soap php8.2-zip php8.0-intl -y
sudo echo "<?php phpinfo(); ?>" > /var/www/html/info.php
# install composer for Laravel
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/bin --filename=composer
# Increase PHP memory limit for the duration of the composer install
sudo sed -i 's/memory_limit = .*/memory_limit = -1/' /etc/php/8.2/apache2/php.ini
# Start and enable Apache
sudo systemctl start apache2
sudo systemctl enable apache2
composer clearcache 
composer selfupdate

# Create and Change the ownership of the Laravel directory
sudo mkdir -p /var/www/laravel
sudo chown -R www-data:www-data /var/www/laravel
# Clone the Laravel application from GitHub
sudo -u www-data git clone https://github.com/laravel/laravel.git /var/www/laravel
# Navigate to the Laravel app directory
sudo chown -R "$USER" /var/www/laravel
cd /var/www/laravel || exit
# Install Composer dependencies with increased memory limit
php -d memory_limit=-1 /usr/bin/composer install
# Restore the original PHP memory limit
sudo sed -i 's/memory_limit = -1/memory_limit = 128M/' /etc/php/8.2/apache2/php.ini
# Create a .env file
cp .env.example .env
# Update the .env file with the database connection settings
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$laravel_db/g" /var/www/laravel/.env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$mysql_root_password/g" /var/www/laravel/.env
# Generate an application key
php artisan key:generate
# Create a virtual host configuration for Apache
sudo tee /etc/apache2/sites-available/laravel.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/laravel/public
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/laravel/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
# Enable the Laravel site and disable the default Apache site
sudo a2ensite laravel
sudo a2dissite 000-default
# Reload Apache to apply changes
sudo systemctl reload apache2
# migrate database and tables
php artisan migrate
# Display installation completed message
echo "Laravel application has been deployed and configured successfully!"
EOL
