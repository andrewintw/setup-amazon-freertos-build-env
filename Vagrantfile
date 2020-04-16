Vagrant.configure("2") do |config|

  # ubuntu 14.04
  #config.vm.box = "ubuntu/trusty64"

  # ubuntu 16.04  
  config.vm.box = "ubuntu/xenial64"

  # Enable USB Controller on VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--usb", "on"]
    vb.customize ["modifyvm", :id, "--usbehci", "on"]
  end
  
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  # SHELL

end