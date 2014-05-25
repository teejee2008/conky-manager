#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

echo "Installing files..."

sudo cp -dpr --no-preserve=ownership -t / ./*

if [ $? -eq 0 ]; then
	echo "Installed successfully."
	echo ""
	echo "Start Conky Manager using the shortcut in the application menu"
	echo "or by running the command: conky-manager"	
	echo ""
	echo "Following packages are required for this application to function correctly:"
	echo "- libgtk-3 libgee2 realpath rsync p7zip-full feh imagemagick"
	echo "Please ensure that these packages are installed and up-to-date"
else
	echo "Installation failed!"
	exit 1
fi

cd "$backup"
