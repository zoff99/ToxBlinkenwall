#! /bin/bash


is_pitwo() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_pizero() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

# ...while tests for Pi 3 and 4 just test processor type, so will also find CM3, CM4, Zero 2 etc.

is_pithree() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]2[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_pifour() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]3[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_pifive() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]4[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_any_pi() {
  if is_pitwo; then
    echo 2
  elif is_pithree; then
    echo 3
  elif is_pifour; then
    echo 4
  elif is_pifive; then
    echo 5
  elif is_pizero; then
    echo 0
  else
    echo -1
  fi
}

is_any_pi=$(is_any_pi)

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if [[ "$is_any_pi""x" == "-1x" ]]; then
        _OS_DIR_="/linux/"
    else
        # default RPI dir
        _OS_DIR_="/raspi/"
        # check for other models of the RPI
        pi_model=$(tr -d '\0' </proc/device-tree/model)
        echo $pi_model|grep 'Raspberry Pi Zero W' >/dev/null 2> /dev/null
        pizero_w=$?
        if [ $pizero_w == 0 ]; then
            _OS_DIR_="/rpi_zerow/"
        fi
    fi
elif [[ "$OSTYPE" == "linux-gnueabihf" ]]; then
    # default RPI dir
    _OS_DIR_="/raspi/"
    # check for other models of the RPI
    pi_model=$(tr -d '\0' </proc/device-tree/model)
    echo $pi_model|grep 'Raspberry Pi Zero W' >/dev/null 2> /dev/null
    pizero_w=$?
    if [ $pizero_w == 0 ]; then
        _OS_DIR_="/rpi_zerow/"
    fi
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
