# noobuntu

## About

Enterprise Ubuntu development environment with Active Directory integration

**GitHub release is WIP, the internal code needs to be cleansed of sensitive information.**

### Features

Active Directory:

- Domain Join

Development Environment:

- Encrypted home
- OneDrive
- Network Shares
- Corporate Email
- Microsoft Teams
- CLion, PyCharm, Sublime Text, Visual Studio Code
- Vulkan
- Git, Git LFS, Git Credential Manager, GitHub Desktop
- Pageant + integration for FileZilla, Remmina
- Azure CLI, nomacs with HEIF support, PowerShell Core, and useful stock utilities
- Automatic Updates

NVIDIA:

- NVIDIA driver
- CUDA

Drivers:

- atlantic
- e1000e
- i40e
- igb
- ixgbe
- mlx4
- mlx5
- tn40xx

## Usage

### OS Install

Before installation, perform the following on physical machines:

- Update the BIOS to the latest version
- Disable CSM
- Disable Secure Boot
- Enable TPM

On virtual machines:

- Enable promiscuous mode for the virtual network interface

#### Single Boot

Create the [Ubuntu 18.04 UEFI Network Installer](https://noobient.com/2019/06/25/ubuntu-18-04-uefi-network-installer/), and copy the contents of the ubuntu folder to a FAT32 formatted pendrive.

Boot the pendrive via UEFI, and complete the installation. **Make sure to set the hostname properly!**

#### Dual Boot

It's almost the same as single boot, except for partitioning. Before installation, make sure there's enough disk space for Linux. If the Windows partition takes up all disk space, shrink it before starting the Ubuntu installer.

In the Ubuntu partitioning dialog:

- To avoid deleting the Windows partitions, select **Undo changes to partitions**.
- Delete any existing Linux partitions.
- Create a **swap** partition as big as the physical memory.
- Create an ext4 formatted **/** partition on the remaining free space.
- Do not create a 2nd EFI partition, Ubuntu will share the EFI partition with Windows.

#### Recovery Mode

If you can't boot the system due to missing NVIDIA driver, you can

- Try pressing `Esc` during boot, which should open the GRUB menu, then select the Recovery option
- Use [Super Grub2 Disk](https://www.supergrubdisk.org/super-grub2-disk/), and add `systemd unit=rescue.target` to the boot command line

Once booted, bring up networking with:

```
dhclient
systemctl start systemd-resolved
```

Then run `nvidia.yml` to install the driver, reboot, and proceed as normal.

### Ansible

Install the latest release of Ansible:

```
sudo add-apt-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

### Active Directory

**Note:** this should be performed exclusively by IT, since it requires Domain Join rights. Therefore, if regular users attempt to run it, it **will** fail.

Prepare the workstation to join the domain:

```
git clone https://github.com/noobient/noobuntu.git
sudo ansible-playbook ansible/ad.yml
```

Test if the workstation can discover AD properly:

```
realm discover
```

If yes, you can join the domain with:

```
sudo realm join --user <user.name>
```

If not, it may be laggy network, imperfect drivers, disabled promiscuous mode in virtualization etc. Try joining explicitly, i.e. `sudo realm join ad.foobar.com`.

### Development Environment

Install and configure all packages:

```
sudo ansible-playbook ansible/devenv.yml
```

#### Encrypted Home

**Warning:** this feature is still experimental. To enable home encryption:

```
noobuntu-encrypt
```

If the user changes the password, find the appropriate protector ID by running

```
fscrypt status /
```

Then change the passphrase for this protector by running:

```
fscrypt metadata change-passphrase --protector=/:ID
```

### NVIDIA

To install just the NVIDIA driver:

```
sudo ansible-playbook ansible/nvidia.yml
```

To install the NVIDIA driver and CUDA as well:

```
sudo ansible-playbook ansible/cuda.yml
```

#### Testing

`simpleVulkan` is a great sample to test GPU, compiler, and CUDA functionality, as it involves many components to be set up correctly.

```
cp -R /usr/local/cuda/samples/2_Graphics/simpleVulkan ~
cd ~/simpleVulkan
sed -Ei 's@(^INCLUDES\s*:=\s*-I).*(/common/inc$)@\1$(CUDA_PATH)/samples/\2@' Makefile
sed -i 's@.*$(EXEC).*../../bin.*@@' Makefile
make
./simpleVulkan
```

### Drivers

To replace a few stock hardware drivers with up-to-date ones from the vendor:

```
sudo ansible-playbook ansible/drivers.yml
```
