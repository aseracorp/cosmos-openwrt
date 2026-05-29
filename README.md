This repo lets you builds an [OpenWrt](https://openwrt.org/)-Image (arm64/aarch64) with [Cosmos Cloud](https://cosmos-cloud.io/) included and a compressing BTRFS-Partition for App-Data/Storage.

Download the finished Image Clone it and run the action in your fork. Tested with a Raspberry Pi 4, NanoPi R3S-LTS and on amd64 (experimental).

Cosmos-OpenWrt is a wrapper / gh-action around the OpenWrt Image builder that creates an [OpenWrt](https://openwrt.org/)-Image with [Cosmos Cloud](https://cosmos-cloud.io/) and it's dependencies preinstalled. On first boot, the image looks for free space on the root disk, creates an additional [BTRFS](https://btrfs.readthedocs.io/en/latest/Introduction.html) partition and uses this partition for your app storage. Per default, the partition is compressed so you could run cosmos on very low disk space. Like even an 8GB SD-Card. Though I recommend at least 32GB.

Differences vs. Cosmos on a conventional Linux like Debian/Ubuntu etc.:
You get all the advantages of Cosmos +  OpenWrt + BTRFS in a single box:
-- Low Disk wear / support for controller-less Storage like SD-Cards or eMMC
-- simple, easy install. Flashable like f.e. Home Assistant OS
-- Lightweight. The system image is below 256MB
-- flashable aio system upgrades. Rerun the gh-action and flash the new sysupgrade via Luci OR use owut integrated in OpenWrt
-- Full Router-, Firewall- and Wireless-Accesspoint
-- BTRFS: Automatic compression & Snapshot Support

OpenWrt is preconfigured to work right out of the box with cosmos. But you still have full control, so you can break it in probably unlimited ways I cannot imagine 😉 Don't forget to backup your known working configuration in Luci.

**How to use:** Fork the repo and run the gh action "Build OpenWrt Image" with your desired parameters. Download and unzip your image from the artifacts uploaded by the action. Flash the image per your device instructions.

Per Default, OpenWrt is configured as a DHCP-Client with static failover 192.168.0.11. mdns is enabled. If there is no existing DHCP-Server, Cosmos will serve DHCP-Addresses per default (Non Authorative, so any other DHCP-Server can take over at anytime).

Per default, Luci is accessible via Port 8080 until you set up Cosmos. When Cosmos Initial setup is Done, Luci (OpenWrt Webinterface) is no longer exposed directly and integrated into cosmos (after setup).

SSH-Access is disabled and key-based access can be enabled initially via **/boot/.env** (if a boot partition exists like on RPI's), **gh-secret** or via **Luci Webinterface**.

- **/boot/.env**: If you want to access your machine via ssh, put a file called .env into the boot partition with the following content `SSH_KEY="<public SSH-key>"`
Example: `SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoVc1iQIp8Rdk5NhZ2WNMeBS2kCpI8OaGQre5qnpJ9h user"`
- **gh-secret**: Add a secret in your gh-repo or account called **SSH_KEY** containing your public ssh-key (f.e. `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoVc1iQIp8Rdk5NhZ2WNMeBS2kCpI8OaGQre5qnpJ9h user`).
- **Luci Webinterface**: Navigate to System->Administration->SSH-Keys and enter your public SSH-Key

On Debian, you can create an ssh-key with `ssh-keygen -t ed25519`