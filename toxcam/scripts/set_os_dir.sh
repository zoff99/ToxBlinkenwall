#! /bin/bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
        _OS_DIR_="/linux/"
elif [[ "$OSTYPE" == "linux-gnueabihf" ]]; then
        _OS_DIR_="/raspi/"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        _OS_DIR_="/osx/"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        _OS_DIR_="/cygwin/"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        _OS_DIR_="/win32/"
elif [[ "$OSTYPE" == "win32" ]]; then
        _OS_DIR_="/win32/"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        _OS_DIR_="/freebsd/"
else
        # Unknown.
        _OS_DIR_="/default/"
fi

export _OS_DIR_
