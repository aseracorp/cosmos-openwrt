This repo lets you builds an [OpenWrt](https://openwrt.org/)-Image (arm64/aarch64) with [Cosmos Cloud](https://cosmos-cloud.io/) included and a compressing BTRFS-Partition for App-Data/Storage.

Clone it and run the action in your fork. Tested with a Raspberry Pi 4.

For Storage, the image can create a BTRFS-Partition and configures docker to use this as storage.

If you want to access your machine via ssh, put a file called .env into the boot partition with the following content:
`SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoVc1iQIp8Rdk5NhZ2WNMeBS2kCpI8OaGQre5qnpJ9h user"`

Replace the key with your actual key. On Debian, you can create one with `ssh-keygen -t ed25519`

If your machine doesn't use a boot partition like a Pi, You need to put the key in via Luci after the initial setup.
