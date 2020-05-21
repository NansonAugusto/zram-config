#!/bin/bash

cores=$(nproc --all)

echo $cores

echo "zram" > /etc/modules-load.d/zram.conf

echo "options zram num_devices=$cores" > /etc/modprobe.d/zram.conf

totalmem=`free | grep -e "^Mem:" | awk '{print $2}'`
mem=$(( ($totalmem / 2 / $cores)* 1024 ))

core=0
while [ $core -lt $cores ]; do
    echo "KERNEL==\"zram$core\", ATTR{comp_algorithm}=\"lz4\", ATTR{disksize}=\"$mem\",TAG+=\"systemd\"" >> /etc/udev/rules.d/99-zram.rules
    echo "mkswap /dev/zram$core" >> /usr/bin/zram-init
    echo "swapon /dev/zram$core" >> /usr/bin/zram-on
    echo "swapoff /dev/zram$core" >> /usr/bin/zram-off
    let core=core+1
done

function write_service {
    echo $1 >> /etc/systemd/system/zram-config.service
}

write_service "[Unit]"
write_service "Description=Swap with zram"
write_service "After=multi-user.target"
write_service ""
write_service "[Service]"
write_service "Type=oneshot"
write_service "RemainAfterExit=true"
write_service "ExecStartPre=/bin/bash /usr/bin/zram-init"
write_service "ExecStart=/bin/bash /usr/bin/zram-on"
write_service "ExecStop=/bin/bash /usr/bin/zram-off"
write_service ""
write_service "[Install]"
write_service "WantedBy=multi-user.target"

systemctl enable zram-config

reboot