#! /bin/sh

toolchain_pkg_URL='https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz'
cmake_pkg_URL='https://github.com/Kitware/CMake/releases/download/v3.17.0/cmake-3.17.0-Linux-x86_64.tar.gz'
set_PATH_file="$HOME/set_esp-idf_PATH.sh"

awscli_pkg_URL='https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'

aws_access_key_id='BKIAVG7B7SOU3Q5AMUYE'
aws_secret_access_key='aEHzR4maofRRzqxqVZdHrs/hkWyzxZeX2yyJ95r+'
aws_default_region='us-east-1'
aws_default_output='json'

pip_requirements_URL='https://raw.githubusercontent.com/browanofficial/minihub-pro/master/vendors/browan/esp-idf/requirements.txt'
src_repo='https://github.com/browanofficial/minihub-pro.git'

cp210x_vcp_URL='https://www.silabs.com/documents/login/software/Linux_3.x.x_4.x.x_VCP_Driver_Source.zip'


use_bash () {
	# sudo dpkg-reconfigure dash
	# (select No)
	echo "dash dash/sh boolean false" | sudo debconf-set-selections
	sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
}

install_pkgs () {
	local py_pkgs="python-cryptography python-future"

	sudo apt-get update
	sudo apt-get install -y git wget libncurses-dev flex bison gperf \
				python python-pip python-setuptools python-serial python-pyparsing \
				cmake ninja-build ccache build-essential libffi-dev libssl-dev python-dev jq
	sudo apt-get install -y unzip tree apt-file
	sudo apt-get install -y linux-image-extra-virtual linux-modules-extra-`uname -r`

	if [ `lsb_release -r | awk '{print $2}'` != '14.04' ]; then
		sudo apt-get install -y $py_pkgs
	fi
}

install_toolchain () {
	mkdir -p $HOME/toolchain
	rm -rf $HOME/toolchain/xtensa-esp32-elf
	wget $toolchain_pkg_URL
	tar -zxvf `basename $toolchain_pkg_URL` -C $HOME/toolchain
	rm -rf `basename $toolchain_pkg_URL`
}

install_cmake () {
	mkdir -p $HOME/toolchain
	rm -rf $HOME/toolchain/cmake-3.17.0-Linux-x86_64
	wget $cmake_pkg_URL
	tar -zxvf `basename $cmake_pkg_URL` -C $HOME/toolchain
	rm -rf `basename $cmake_pkg_URL`
}

set_path_env () {
	cat <<EOF > $set_PATH_file
ESP32_TOOLCHAIN_DIR=$HOME/toolchain/xtensa-esp32-elf
CMAKE_DIR=$HOME/toolchain/cmake-3.17.0-Linux-x86_64
export PATH=\$ESP32_TOOLCHAIN_DIR/bin:\$CMAKE_DIR/bin:\${PATH}
EOF
	chmod a+x $set_PATH_file
}

join_dialout_grp () {
	sudo usermod -a -G dialout $USER
}

install_awscli () {
	wget $awscli_pkg_URL
	unzip `basename $awscli_pkg_URL`
	sudo ./aws/install
	rm -rf aws `basename $awscli_pkg_URL`
}

config_awscli () {
	aws configure set aws_access_key_id     $aws_access_key_id
	aws configure set aws_secret_access_key $aws_secret_access_key
	aws configure set default.region        $aws_default_region
	aws configure set default.output        $aws_default_output

	# test
	aws sts get-caller-identity
}

instal_py_pkgs () {
	python -m pip install --user tornado nose
	python -m pip install --user boto3

	python -m pip install --user launchpadlib
	python -m pip install --user --upgrade pip
	python -m pip install --user --upgrade 'setuptools<45.0.0'


	wget $pip_requirements_URL
	python -m pip install --user -r requirements.txt
	rm requirements.txt
}

update_cp201x_driver () {
	rm -rf CP210x_VCP
	wget $cp210x_vcp_URL
	mkdir -p CP210x_VCP
	unzip `basename $cp210x_vcp_URL` -d CP210x_VCP/

	(lsmod | grep cp210x) && sudo rmmod cp210x
	cd CP210x_VCP/
	make
	sudo cp -v cp210x.ko /lib/modules/`uname -r`/kernel/drivers/usb/serial/
	cd ../
	rm -rf CP210x_VCP/ Linux_3.x.x_4.x.x_VCP_Driver_Source.zip
	sudo modprobe cp210x
	lsmod | grep cp210x
}

clone_source () {
	rm -rf minihub-pro
	git clone $src_repo --recurse-submodules minihub-pro
}

do_main () {
	use_bash
	install_pkgs
	install_toolchain
	install_cmake
	set_path_env
	join_dialout_grp
	install_awscli
	config_awscli
	instal_py_pkgs
	update_cp201x_driver
	clone_source
}

do_main
