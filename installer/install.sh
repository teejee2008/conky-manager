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

if [ $? -eq 0 ]; then
	echo "Installed successfully."
	echo ""
	echo "Start Conky Manager by running the command: conky-manager"	
	echo ""
	echo "Following packages are required by Conky Manager:"
	echo "- conky rsync p7zip imagemagick libgtk-3 libgee2 libjson-glib"
	echo "Please ensure that these packages are installed and up-to-date"
else
	echo "Installation failed!"
	exit 1
fi

cd "$backup"
