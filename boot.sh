#! /bin/sh
set -e

. libs/common.sh
. libs/net-vars.sh

Q_VMNAME=$1

Q_ARCH=${ARCH-'x86_64'}
Q_CPUS=${CPUS-$half_cores}
Q_THREADS=${THREAD-$threads}
Q_MEMS=${MEMS-$default_mems'G'}


primary_hardriver="$Q_VMNAME/hardriver.cow"
pflash="$Q_VMNAME/pflash.fd"
socket_s0="$Q_VMNAME/s0.sock"
if0="$Q_VMNAME"0

create_vm() {
  [ ! -d "$Q_VMNAME/" ] && mkdir "$Q_VMNAME/"
  if [ ! -f "$primary_hardriver" ] && [ -f "$Q_VMNAME.cow" ]; then
    mv "$Q_VMNAME.cow" "$Q_VMNAME/base.cow"
    inc_img "$Q_VMNAME" 'hardriver.cow' 'base.cow'
  elif [ ! -f "$primary_hardriver" ]; then
    [ -f "$Q_VMNAME/base.cow" ] || qemu-img create -f qcow2 "$Q_VMNAME/base.cow" 114514M
    inc_img "$Q_VMNAME" 'hardriver.cow' 'base.cow'
  fi

  [ -f "$pflash" ] || cp "$OVMF_VARS_PATH" "$pflash"
}
create_metainfo() {
  cur_pwd=$(pwd)

  cd "$Q_VMNAME/"
  echo 'creating metainfo.iso'
  echo "VMNAME=$Q_VMNAME
CPUS=$Q_CPUS
THREADS=$Q_THREADS
MEMS=$Q_MEMS
DEFAULT_MEMS=$default_mems"'G'"
" > 'vm_detail' &&\
  xorriso -outdev "metainfo.iso" -blank as_needed\
    -joliet on \
    -volid 'metainfo' \
    -add 'vm_detail' \
    2> /dev/null
  rm -f 'vm_detail'

  cd "$cur_pwd"
}
create_if() {
  ip link show "$bridge" 2> /dev/null > /dev/null || sudo ./setup-net.sh
  ip link show "$if0" 2> /dev/null > /dev/null || ./ifup.sh "$if0"
}

create_vm
if [ ! -d "$Q_VMNAME/" ]; then
  echo "cann't find '$Q_VMNAME.cow' or '$primary_hardriver'"
  exit 1
fi
create_metainfo || exit 1
create_if || (echo 'failed to create network interface' && exit 1)

shift
qemu-system-"$Q_ARCH" -accel kvm -cpu host \
  -smp cores="$Q_CPUS",threads="$Q_THREADS" -m "$Q_MEMS" \
  -monitor stdio \
  -serial "unix:$socket_s0,server,nowait" \
  -drive file="$primary_hardriver",if=virtio \
  -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE_PATH \
  -drive if=pflash,format=raw,file="$pflash" \
  -netdev tap,id="$if0",ifname="$if0",script=no,downscript=no,vhost=on \
  -device virtio-net,netdev="$if0" \
  $@ \
  -drive file="$Q_VMNAME/metainfo.iso",id=metainfo,media=cdrom

./ifdown.sh "$if0"
