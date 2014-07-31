#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

echo "Expanding directories..."
for f in `find ./ -type d -exec echo {} \;`; do
    directory=`echo "$f" | sed -r 's/^.{2}//'`
    sudo mkdir -p -m 755 "/$directory"
    echo "/$directory"
done
echo ""

echo "Installing files..."
for f in `find ./ -type f \( ! -iname "install.sh" \) -exec echo {} \;`; do
    file=`echo "$f" | sed -r 's/^.{2}//'`
    sudo install -m 0755 "./$file" "/$file"
    echo "/$file"
done
echo ""

if [ -f /etc/debian_version ]; then
	if command -v apt-get >/dev/null 2>&1; then
		echo "Installing debian packages..."
		for i in conky-all p7zip-full imagemagick rsync libgee2 libjson-glib-1.0-0; do
		  sudo apt-get -y install $i
		done
	fi
elif [ -f /etc/redhat-release ]; then
	if command -v yum >/dev/null 2>&1; then
		echo "Installing redhat packages..."
		for i in conky p7zip ImageMagick rsync libgee json-glib; do
		  sudo yum -y install $i
		done
	fi
fi
echo ""

if [ $? -eq 0 ]; then
	echo "Installed successfully."
	echo ""
	echo "Start the application by running the command: conky-manager"	
	echo "If it fails to start, check and install following packages:"
	echo "> conky rsync p7zip imagemagick libgtk-3 libgee2 libjson-glib"
else
	echo "Installation failed!"
	exit 1
fi

cd "$backup"
