#!/bin/bash
# Flash Player Bitcoin Miner
#
# This script sets up the Flex & Alchemy development environment on Ubuntu.
# Warning: This script is not suitable for use with other operating systems.
# Note: On Windows make sure to install 32-bit (!) JDK and JRE (version < 7)
#
# This code is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This code is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for
# more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with code. If not, see <http://www.gnu.org/licenses/>.

# Create a directory for Flex & Alchemy if necessary
echo "Checking if you have ~/Programs directory"
cd ~
if [ ! -e Programs ]
then
  echo "Creating ~/Programs directory"
  mkdir ~/Programs 2> /dev/null
fi
cd ~/Programs

# Download and unzip Flex & Alchemy if necessary
echo "Checking if Flex and Alchemy are in place"
if [ ! -e flex_sdk_4.6.zip ]
then
  echo "Downloading Flex"
  wget http://download.macromedia.com/pub/flex/sdk/flex_sdk_4.6.zip
fi

if [ ! -e flex ]
then
  echo "Unzipping Flex"
  unzip flex_sdk_4.6.zip -d flex
fi

if [ ! -e alchemy_sdk_ubuntu_p1_121008.zip ]
then
  echo "Downloading Alchemy"
  wget http://download.macromedia.com/pub/labs/alchemy/alchemy_sdk_ubuntu_p1_121008.zip
fi

if [ ! -e alchemy ]
then
  echo "Unzipping Alchemy"
  unzip alchemy_sdk_ubuntu_p1_121008.zip
  mv alchemy-ubuntu-v0.5a alchemy
fi

# Clean up the ~/.bashrc file
echo "Clean up the ~/.bashrc file from previous installations"
cat ~/.bashrc | grep -Ev 'FLEX|ALCHEMY|alchemy' > ~/.bashrc.clean
cp ~/.bashrc ~/.bashrc.old
cp ~/.bashrc.clean ~/.bashrc

# Setup the environment variables for Flex
echo "Setting up the environment variables for Flex in ~/.bashrc"
echo "FLEX_HOME=~/Programs/flex" >> ~/.bashrc
echo "PATH=\$PATH:\$FLEX_HOME/bin" >> ~/.bashrc
FLEX_HOME=~/Programs/flex
PATH=$PATH:$FLEX_HOME/bin

# Patch gcc of Alchemy
echo "Patching gcc of Alchemy"
chmod +w alchemy/achacks/gcc
sed -i 's/(ARGV)/(@ARGV)/' alchemy/achacks/gcc

# Run configuration script for Alchemy
echo "Running configuration script for Alchemy"
cd alchemy/
./config

# Setup the environment variables for Alchemy
echo "Setting up the environment variables for Alchemy in ~/.bashrc"
echo "ALCHEMY_HOME=~/Programs/alchemy" >> ~/.bashrc
echo "PATH=\$PATH:\$ALCHEMY_HOME/achacks" >> ~/.bashrc
ALCHEMY_HOME=~/Programs/alchemy
PATH=$PATH:$ALCHEMY_HOME/achacks

# Setup the environment for Alchemy
echo "Setting up the environment for Alchemy in ~/.bashrc"
echo "source ~/Programs/alchemy/alchemy-setup" >> ~/.bashrc

# Done
echo "Done. Make sure to run alc-on before running make!"
