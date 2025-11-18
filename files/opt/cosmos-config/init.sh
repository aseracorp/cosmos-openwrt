#!/bin/bash
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>init.plain.log 2>&1
# Everything below will go to the file 'init.log':

# should the docker volumes be copy on write? This enables compression but accelerates writes onto disk which is harmful for the disk with f.e. database-files. You then need to disable it manually (for databases) on a subfolder basis with 'chattr +C <path-to-subfolder>'. !! Only applies to new files created !!
# cow=true

cd /opt/cosmos-config
source .env
if [ -f /boot/.env  ]; then source /boot/.env; fi
touch init.conf
touch /tmp/cosmos.log
touch /tmp/cosmos.plain.log

readdisk () {
    #read-out disk infos
    root_partition=$(basename $(readlink -f /sys/dev/block/"$(awk -e '$9=="/dev/root"{print $3}' /proc/self/mountinfo)"))
    disk=$(echo $(lsblk --list --noheadings --paths --output PKNAME /dev/${root_partition}) | sed "s@/dev/@@")
    new_part_id=$( echo $(( $(echo $root_partition | sed "s@${disk}p@@") + 1 )) )
}

#flash image to eMMC
if [ -n $EMMC ]; then
    readdisk
    if [ $disk != "mmcblk0" ]; then
        echo "$(date +"%F_%H%M%S") Found EMMC-key, writing image to eMMC..." >> init.log
        wget $EMMC -O emmc/firmware.img.gz
        gunzip -c emmc/firmware.img.gz | dd of=/dev/mmcblk0 bs=4M conv=fsync
        echo "$(date +"%F_%H%M%S") written successfully, power down..." >> init.log
        poweroff && exit 0
    else
        echo "$(date +"%F_%H%M%S") root disk is mmcblk0, I won't flash onto myself, abort..." >> init.log
    fi
fi

# workaround for raspberry pi retaining settings after reflash (https://forum.openwrt.org/t/pi-remembers-my-mistakes/164450/14)
if [[ $(cat init.conf) = "commissioned successfully with btrfs-storage" ]]; then
    if [ "$STORAGE" = true ]; then
        readdisk
        if [ ! -e /dev/"${disk}p${new_part_id}" ]; then
            # missing partition despite state "commission successfully", force re-init
            firstboot -y && reboot && exit 0
        fi
    fi
fi

#add symlink for config
if [ ! -L /var/lib/cosmos ]; then
    if [ -d /var/lib/cosmos ]; then rm -R /var/lib/cosmos; fi
    ln -s /opt/cosmos-config/ /var/lib/cosmos
    echo "$(date +"%F_%H%M%S") var/lib/cosmos: create symlink to persist storage..." >> /tmp/init.log
fi
if [ ! -L cosmos.log  ]; then
    if [ -f cosmos.log  ]; then rm cosmos.log; fi
    ln -s /tmp/cosmos.log /opt/cosmos-config/cosmos.log
    echo "$(date +"%F_%H%M%S") cosmos.log: create symlink to tmp..." >> /tmp/init.log
fi
if [ ! -L cosmos.plain.log  ]; then
    if [ -f cosmos.plain.log  ]; then rm cosmos.plain.log; fi
    ln -s /tmp/cosmos.plain.log /opt/cosmos-config/cosmos.plain.log
    echo "$(date +"%F_%H%M%S") cosmos.plain.log: create symlink to tmp..." >> /tmp/init.log
fi

if [[ $(cat init.conf | cut -c 0-25) != "commissioned successfully" ]]; then
    echo "$(date +"%F_%H%M%S") start init..." >> init.log
    #mount eMMC (btrfs) filesystem (used for cosmos)
    if [ "$STORAGE" = true ]; then

        readdisk
        start_sector=$(( $(cat /sys/block/${disk}/${root_partition}/start) + $(cat /sys/block/${disk}/${root_partition}/size) ))

        if [ ! -e /dev/"${disk}p${new_part_id}" ]; then
            echo "$(date +"%F_%H%M%S") add 3rd partition (btrfs) on empty space (start-sector: ${start_sector})..." >> init.log
            # add & format storage partition (use all empty space after root partition)
            echo "n
            p
            $new_part_id
            $start_sector

            w" | fdisk -W always /dev/"${disk}"
            echo "$(date +"%F_%H%M%S") format 3rd partition (btrfs)..." >> init.log
            sleep 5
            partx -u /dev/"${disk}"
            mkfs.btrfs /dev/"${disk}p${new_part_id}"
            sleep 5
        fi
        if [[ $(findmnt /opt/docker/ -no SOURCE) != "/dev/${disk}p${new_part_id}" ]]; then
            partx -u /dev/"${disk}"
            #stop docker service
            service dockerd stop
            # clear docker dir
            rm -R /opt/docker/*
            # mount btrfs partition to docker dir
            echo "$(date +"%F_%H%M%S") mount 3rd partition (btrfs)..." >> init.log
            sleep 5 && block detect | uci import fstab
            uci set fstab.@mount[-1].target='/opt/docker'
            uci set fstab.@mount[-1].enabled='1'
            uci set fstab.@mount[-1].options='compress=zstd:10'
            uci commit fstab
            #set btrfs dockerd storage driver
            echo "$(date +"%F_%H%M%S") switch docker storage driver to btrfs..." >> init.log
            uci set dockerd.globals.storage_driver="btrfs"
            uci commit dockerd
            service dockerd start
        fi
        if [[ $(findmnt /opt/docker/ -no SOURCE) = "/dev/${disk}p${new_part_id}" ]]; then
            if [ -z ${cow+x} ]; then
                echo "$(date +"%F_%H%M%S") disable copy on write on docker volumes..." >> init.log
                mkdir -p /opt/docker/volumes
                chattr +C /opt/docker/volumes
            elif [ $cow = 1 ]; then
                echo "$(date +"%F_%H%M%S") enable copy on write on docker volumes... (! Danger)" >> init.log
                mkdir -p /opt/docker/volumes
                chattr -C /opt/docker/volumes
            fi
            echo "$(date +"%F_%H%M%S") partition successfully mounted, store state as commissioned in init.conf. Delete the file to check partition-setup again" >> init.log
            echo "commissioned successfully with btrfs-storage" > init.conf
        else
            echo "$(date +"%F_%H%M%S") failed to mount, reboot now and try again..." >> init.log
            reboot && exit 0 #reboot, because all other commands like partx -u... weren't reliable
        fi
    else
        echo "$(date +"%F_%H%M%S") init finished without btrfs-storage" >> init.log
        echo "commissioned successfully without btrfs-storage" > init.conf
    fi
    #enable mdns with reflector
    echo "$(date +"%F_%H%M%S") enable mdns with reflector..." >> init.log
    sed -i 's/enable-reflector=no/enable-reflector=yes/g' /etc/avahi/avahi-daemon.conf
    service avahi-daemon restart
    # pull mongodb image
    if ping -i 5 -c 5 -A hub.docker.com; then
        count=1
        while [[ ! $(docker ps) && count -le 19 ]]; do
            sleep 1
            ((count++))
        done
        if [[ $(docker ps) ]]; then
            echo "$(date +"%F_%H%M%S") dockerd & network up, pull mongodb..." >> init.log
            docker pull arm64v8/mongo:4.4.18
        else
            echo "$(date +"%F_%H%M%S") docker still not ready, give up an continue without mongodb pulled..." >> init.log
        fi
    fi
fi

#add licence from file (if file exists)
if [ -z "$(yq '.Licence' /opt/cosmos-config/cosmos.config.json -o x)" ]; then
    if [ -n "${LICENCE}" ]; then
        echo "$(date +"%F_%H%M%S") found licence, add to config..." >> init.log
        yq -i '.Licence = strenv(LICENCE)' /opt/cosmos-config/cosmos.config.json
    elif [ -f "/boot/licence" ]; then
        echo "$(date +"%F_%H%M%S") found licence, add to config..." >> init.log
        Licence=$(cat /boot/licence)
        yq -i '.Licence = strenv(Licence)' /opt/cosmos-config/cosmos.config.json
    fi
fi

hostname=$(yq '.HTTPConfig.Hostname' /opt/cosmos-config/cosmos.config.json -o x)

#on change of hostname, do this:
if [ -n "${hostname}" ]; then
    if [ "${hostname}" != "${HOSTNAME}" ]; then

        #disable luci login
        if [ "${HOSTNAME}" == "0.0.0.0" ]; then
            echo "$(date +"%F_%H%M%S") disable luci login..." >> init.log
            sed -i "s/let user = http.getenv('HTTP_AUTH_USER');/let user = 'root';/g" /usr/share/ucode/luci/dispatcher.uc
            sed -i "s/let pass = http.getenv('HTTP_AUTH_PASS')/let pass = '${PASSWD}'/g" /usr/share/ucode/luci/dispatcher.uc
            sed -i "s@http.redirect(url);@http.redirect('https://${hostname}/cosmos-ui/');@g" /usr/share/ucode/luci/controller/admin/index.uc
        else
            echo "$(date +"%F_%H%M%S") update logout-URL..." >> init.log
            sed -i "s@http.redirect('https://${HOSTNAME}/cosmos-ui/');@http.redirect('https://${hostname}/cosmos-ui/');@g" /usr/share/ucode/luci/controller/admin/index.uc
        fi

        #save new hostname
        sed -i "s/HOSTNAME=.*;/HOSTNAME=${hostname}/g" ./.env

        #add OpenWRT GUI as App
        echo "$(date +"%F_%H%M%S") add OpenWRT to GUI as App..." >> init.log
        if [[ "${hostname}" == *".local" ]]; then
                owrt_hostname="openwrt.local"
        elif [[ "${hostname}" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
                owrt_hostname="${hostname}:4443"
        else
                owrt_hostname="openwrt.${hostname}"
        fi

        owrt_hostname="${owrt_hostname}" yq -i 'with(.HTTPConfig.ProxyConfig.Routes; select(all_c(.Name != "OpenWrt")) | . += {
                "Disabled": false,
                "Name": "OpenWrt",
                "Description": "OpenWrt Router-Management",
                "UseHost": true,
                "Host": "${owrt_hostname}",
                "UsePathPrefix": false,
                "PathPrefix": "",
                "Timeout": 14400000,
                "ThrottlePerMinute": 10000,
                "CORSOrigin": "",
                "StripPathPrefix": true,
                "MaxBandwith": 0,
                "AuthEnabled": true,
                "AdminOnly": true,
                "Target": "http://localhost:8080",
                "SmartShield": {
                    "Enabled": true,
                    "PolicyStrictness": 0,
                    "PerUserTimeBudget": 0,
                    "PerUserRequestLimit": 0,
                    "PerUserByteLimit": 0,
                    "PerUserSimultaneous": 0,
                    "MaxGlobalSimultaneous": 0,
                    "PrivilegedGroups": 0
                },
                "Mode": "PROXY",
                "BlockCommonBots": true,
                "BlockAPIAbuse": false,
                "AcceptInsecureHTTPSTarget": true,
                "HideFromDashboard": false,
                "DisableHeaderHardening": false,
                "SpoofHostname": false,
                "AddionalFilters": null,
                "RestrictToConstellation": false,
                "OverwriteHostHeader": "",
                "WhitelistInboundIPs": [],
                "Icon": "",
                "TunnelVia": "",
                "TunneledHost": "",
                "ExtraHeaders": null
                } ) | with(.HTTPConfig.ProxyConfig.Routes[]; select(.Name == "OpenWrt") | .Host |= envsubst)' /opt/cosmos-config/cosmos.config.json

    fi
fi