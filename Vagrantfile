Vagrant.configure("2") do |config|
  # Disable automatic key insertion
  config.ssh.insert_key = false
  # Configure the Master server
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/focal64"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048" # Set the amount of memory for the Master VM
    end
    
    # Generate SSH key for the 'vagrant' user
    master.vm.provision "shell", inline: "su - vagrant -c 'ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa'"
    
    master.vm.provision "shell", path: "config.sh" # Shell script to set up the LAMP stack
  end
  # Configure the Slave server
  config.vm.define "slave" do |slave|
    slave.vm.box = "ubuntu/focal64"
    slave.vm.hostname = "slave"
    slave.vm.network "private_network", ip: "192.168.56.12"
    slave.vm.provider "virtualbox" do |vb|
      vb.memory = "2048" # Set the amount of memory for the Slave VM
    end
    
    # Slave setup
    slave.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update -y
      sudo apt-get install -y sshpass
      # Generate SSH key, and set the necessary permissions
      sudo su - vagrant -c 'ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa'
      sudo chmod 700 /home/vagrant/.ssh && sudo chmod 600 /home/vagrant/.ssh/id_rsa
      # Fetch and add the Master's public key
      PUB_KEY=$(sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no vagrant@192.168.56.10 'cat ~/.ssh/id_rsa.pub')
      if [ ! -z "$PUB_KEY" ]; then
        echo $PUB_KEY | sudo tee -a /home/vagrant/.ssh/authorized_keys
      else
        echo "Failed to retrieve the public key from the master."
        exit 1
      fi
      # Set permissions for authorized_keys
      sudo chmod 600 /home/vagrant/.ssh/authorized_keys
      
      # Install Ansible
      sudo apt-get update
      sudo apt-get install -y ansible
    SHELL
  end
end
