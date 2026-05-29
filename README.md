This repo lets you builds an [OpenWrt](https://openwrt.org/)-image with [Cosmos Cloud](https://cosmos-cloud.io/) included and a compressing [BTRFS](https://btrfs.readthedocs.io/en/latest/Introduction.html)-partition for app-data/storage.

Download the finished Image or Clone the repo and run the action in your fork. Tested with a Raspberry Pi 4 and on amd64 (experimental).

# What is Cosmos OpenWrt?

Cosmos-OpenWrt is a wrapper / gh-action around the OpenWrt Image-builder that creates an [OpenWrt](https://openwrt.org/)-Image with [Cosmos Cloud](https://cosmos-cloud.io/) and it's dependencies preinstalled. On first boot, the image looks for free space on the root disk, creates an additional [BTRFS](https://btrfs.readthedocs.io/en/latest/Introduction.html)-partition and uses this partition for your app storage. Per default, the partition is compressed so you could run cosmos on very low disk space. Like even an 8GB SD-Card. Though I recommend at least 32GB.

# additional Features vs plain [Cosmos Cloud](https://cosmos-cloud.io/)

Differences vs. Cosmos on a conventional Linux like Debian/Ubuntu etc.:
You get all the advantages of Cosmos +  OpenWrt + BTRFS in a single box:
- Low Disk wear / support for controller-less Storage like SD-Cards or eMMC
- simple, easy install. Flashable like f.e. Home Assistant OS
- Lightweight. The system image is below 256MB
- flashable aio system upgrades. Rerun the gh-action and flash the new sysupgrade via Luci OR use owut integrated in OpenWrt
- Full Router-, Firewall- and Wireless-Accesspoint
- BTRFS: Automatic compression & Snapshot Support
- ZRAM: zram RAM-Compression is enabled per default. This means Home Assistant and other RAM-Hungry apps should run on low RAM (f.e. 1GB) despite min recommendation of 2GB.

OpenWrt is preconfigured to work right out of the box with cosmos. But you still have full control, so you can break it in probably unlimited ways I cannot imagine 😉 Don't forget to backup your known working configuration in Luci.

# How to use

Fork the repo and run the gh action "Build OpenWrt Image" with your desired parameters. Download and unzip your image from the artifacts uploaded by the action. Flash the image per your device instructions.

### How to add your public SSH-Key

SSH-Access is disabled per default. Key-based access can be enabled initially via **/boot/.env** (if a boot partition exists like on RPI's), **gh-secret** or via **Luci Webinterface**.

- **/boot/.env**: If you want to access your machine via ssh, put a file called .env into the boot partition with the following content `SSH_KEY="<public SSH-key>"`
Example: `SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoVc1iQIp8Rdk5NhZ2WNMeBS2kCpI8OaGQre5qnpJ9h user"`
- **gh-secret**: Add a secret in your gh-repo or account called **SSH_KEY** containing your public ssh-key (f.e. `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoVc1iQIp8Rdk5NhZ2WNMeBS2kCpI8OaGQre5qnpJ9h user`).
- **Luci Webinterface**: Navigate to System->Administration->SSH-Keys and enter your public SSH-Key

On Debian, you can create an ssh-key with `ssh-keygen -t ed25519`

## first boot, initial config

Per Default, OpenWrt is configured as a DHCP-Client with static failover 192.168.0.11. mdns is enabled. If there is no existing DHCP-Server, Cosmos will serve DHCP-Addresses per default (Non Authorative, so any other DHCP-Server can take over at anytime).

Per default, Luci is accessible via Port 8080 until you set up Cosmos. When Cosmos Initial setup is Done, Luci (OpenWrt Webinterface) is no longer exposed directly and integrated into cosmos (after setup).

If you want to use a static IP for cosmos and you want to change this static IP, you need to Allow insecure access via local IP. Follow this guide:

https://github.com/user-attachments/assets/dfc6395c-c357-4ec6-81b0-c6af8734885b

# Looking for a Plug & Play Solution?
You can buy our prebuilt devices and lots of accessories at our webshop: [Cosmos Cloud T4, C4, R3S at Asera AG](https://www.asera.ch/produkt/cosmos-cloud/)

For the time being, we're shipping only to Switzerland. International buyers, please send us a message via Form: [Contact Form](/https://www.asera.ch/kontakt/)

![Cosmos OpenWrt Features](./docs/Cosmos-Features.png)