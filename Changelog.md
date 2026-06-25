## 25.06.2026
BREAKING: Before upgrading from a previous version, you need to...
- ... remove or comment out the automatically added entries in /etc/sysupgrade.conf (should be empty now)
- ... stop cosmos via ssh: `kill -s SIGTERM $(pidof cosmos)`
- ... move the folder /opt/cosmos-config to /etc/cosmos `mv /opt/cosmos-config /etc/cosmos`

### Changes:
- add changelog
- new file layout: now correctly supports flashing sysupgrades
- automatic WAN/WWAN setup: automatically setups WAN or WWAN (if hardware is recognized)
- add SIM_APN and SIM_PIN to /boot/.env before first boot to automatically setup the WWAN-Connection.

### Known Issues:
- amd64: DISABLE automatic updates. Automatic updates of cosmos are breaking your install because upstream cosmos on amd64 makes use of glibc. OpenWrt uses musl-libc instead of glibc (https://github.com/azukaar/Cosmos-Server/pull/537)

## 29.05.2026
- Prebuilt Images now found under Releases: https://github.com/aseracorp/cosmos-openwrt/releases
- Update README with more infos and basic Howto
- add experimental support for amd64 (do not let COSMOS UPDATE automatically, manually download and replace cosmos folder from aseracorp/cosmos-server until some variant of musl fix gets merged into upstream)
- add automatic release push for Pi4 + amd64
- keep necessary files on sysupgrade
- improve and fix some init.sh logic
- adds DNS-Override in OpenWrt so cosmos can resolve to itself / OIDC's Discovery of .well-known always works
- add LEGO_DISABLE_CNAME_SUPPORT=true per default. Otherwise Let's Encrypt fails when subdomain is setup via CNAME
- added RAM Compression (zram). This means, f.e. Home Assistant can run on 1GB or less of RAM.

## 18.11.2025
 - Initial Release