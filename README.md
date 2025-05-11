DNS Changer Script for Linux
A simple Bash script to change DNS servers on Linux systems (e.g., CentOS 7), test DNS speed, and restore original network settings. Designed to work on minimal systems with basic tools, it supports anti-censorship DNS servers (e.g., 403.online, Radar) for environments with restricted internet access, such as Iran.
Features

Change DNS: Select from a list of 13 DNS providers (e.g., Cloudflare, Google, 403.online) using a number-based menu.
Test DNS Speed: Measure response time for each DNS server (requires dig from bind-utils).
Restore Original Settings: Revert to the initial network configuration (e.g., DHCP-provided DNS) with a single command, even after restarting the script.
Backup System: Automatically backs up network settings (/etc/resolv.conf, ifcfg-* files) before changes.
Minimal Dependencies: Works with basic Bash and Linux commands; optional dig for speed tests.
Anti-Censorship Support: Includes DNS servers optimized for bypassing restrictions in censored environments.

Prerequisites

Operating System: Linux (tested on CentOS 7, compatible with other distributions).
Required Tools: Bash, standard Linux commands (cat, sed, cp, ip).
Optional: dig (part of bind-utils) for DNS speed testing. The script can install it automatically if yum is available.
Permissions: Root access (use sudo or run as root).

Installation

Clone or Download the Repository:
git clone https://github.com/khshayar/DNS_changer.git
cd YOUR_REPOSITORY

Replace YOUR_USERNAME and YOUR_REPOSITORY with your GitHub username and repository name.

Make the Script Executable:
chmod +x dns_changer.sh



Usage

Run the Script:
./dns_changer.sh


Menu Options:

1. Display DNS list and test speed: Shows all available DNS servers with response times (requires dig). If dig is not installed, the script offers to install bind-utils.
2. Change DNS: Select a DNS provider by entering its number (1-13). The script updates the network configuration and creates a backup.
3. Restore original DNS: Reverts all changes to the original network settings (e.g., DHCP-provided DNS like 10.0.2.3). Works even after exiting and rerunning the script.
4. Exit: Closes the script without changes.


Example:
DNS Changer Script
Current system DNS servers:
nameserver 10.0.2.3

1. Display DNS list and test speed
2. Change DNS
3. Restore original DNS
4. Exit
Choose an option (1-4): 2
Select a DNS by number:
1. Shecan: 178.22.122.100 185.51.200.2
...
9. 403.online: 10.202.10.10 10.202.10.11
...
Enter the number (1-13): 9
Creating backup of network settings in /root/dns_backup...
DNS set to 403.online in /etc/sysconfig/network-scripts/ifcfg-enp0s3.
Do you want to restart the network to apply changes? (y/n): y


Restore Original Settings:
Choose an option (1-4): 3
Restoring original network settings from /root/dns_backup...
Restored /etc/resolv.conf.
Do you want to restart the network to apply restored settings? (y/n): y



Supported DNS Providers

Shecan: 178.22.122.100 185.51.200.2
Electro: 78.157.42.100 78.157.42.101
Cloudflare: 1.1.1.1 1.0.0.1
Google: 8.8.8.8 8.8.4.4
AdGuard: 94.140.14.14 94.140.15.15
Quad9: 9.9.9.9 149.112.112.112
OpenDNS: 208.67.222.222 208.67.220.220
NextDNS: 45.90.28.0 45.90.30.0
403.online: 10.202.10.10 10.202.10.11 (Anti-censorship, Iran)
Radar: 10.10.34.35 10.10.34.36 (Anti-censorship, Iran)
Comodo: 8.26.56.26 8.20.247.20
CleanBrowsing: 185.228.168.9 185.228.169.9
DNS.WATCH: 84.200.69.80 84.200.70.40

Notes for Restricted Environments (e.g., Iran)

Package Installation: If yum fails to install bind-utils due to sanctions, select DNS providers like 403.online (number 9) or Radar (number 10) to access repositories:./dns_changer.sh
# Choose option 2, enter 9
sudo yum update


Local Repositories: Add local mirrors or repositories if needed:sudo yum install epel-release



Troubleshooting

DNS Not Changing:

Check /etc/resolv.conf:cat /etc/resolv.conf


Ensure the correct interface is updated:cat /etc/sysconfig/network-scripts/ifcfg-enp0s3


Restart the network:sudo systemctl restart network




DHCP Overriding DNS:

If 10.0.2.3 persists (common in VirtualBox NAT), ensure PEERDNS=no in ifcfg-*:echo "PEERDNS=no" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-enp0s3
sudo systemctl restart network




Restore Not Working:

Verify the backup:ls -l /root/dns_backup
cat /root/dns_backup/resolv.conf.bak


Manually restore if needed:sudo cp /root/dns_backup/resolv.conf.bak /etc/resolv.conf
sudo cp /root/dns_backup/network-scripts/ifcfg-* /etc/sysconfig/network-scripts/
sudo systemctl restart network




Package Installation Issues:

Check yum errors:sudo yum install bind-utils -v


Use 403.online or Radar DNS to resolve repository access issues.



Contributing
Feel free to fork this repository, submit issues, or create pull requests to add new DNS providers or improve functionality.
License
This project is licensed under the MIT License. See the LICENSE file for details.
Contact
For questions or support, open an issue on GitHub or contact [YOUR_EMAIL] (optional).
