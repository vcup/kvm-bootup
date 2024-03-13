if which dpkg 2> /dev/null > /dev/null; then
  OVMF_CODE_PATH='/usr/share/OVMF/OVMF_CODE.fd'
  OVMF_VARS_PATH='/usr/share/OVMF/OVMF_VARS.fd'
elif which pacman 2> /dev/null > /dev/null; then
  OVMF_CODE_PATH='/usr/share/edk2-ovmf/x64/OVMF_CODE.fd'
  OVMF_VARS_PATH='/usr/share/edk2-ovmf/x64/OVMF_VARS.fd'
fi


cores=$(lscpu | grep "^Core(s) per socket:" | awk '{print $4}')
sockets=$(lscpu | grep "^Socket(s):" | awk '{print $2}')
total_cores=$((cores * sockets))
half_cores=$((total_cores / 2))

threads=$(lscpu | grep "^Thread(s) per core:" | awk '{print $4}')

[ $half_cores = 0 ] && half_cores=1
default_mems=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 6 / 1024 / 1024))
[ $default_mems -lt 4 ] && default_mems=4

inc_img() {
  cur_pwd=$(pwd)

  if [ -d "$1" ]; then
    cd $1 && shift
  fi
  histories=inc_history
  base=$2
  img=$1

  if [ -f "$histories" ]; then
    [ ! -f "$img" ] && echo '[inc_img] img not exist' && return 1
    inc=$(awk -F, 'NF {line=$1} END {print line}' "$histories")
    mv "$img" "$img.$inc" && base="$_" &&\
    echo $((inc + 1)),$(date +"%Y-%m-%d %H:%M:%S.%3N") >> $histories
  else
    echo 0,$(date +"%Y-%m-%d-%H-%M-%S") > $histories
  fi
  qemu-img create -f qcow2 -o backing_file=$base,backing_fmt=qcow2 $img

  cd "$cur_pwd"
}
