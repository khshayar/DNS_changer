DNS Changer Script for Linux
A lightweight Bash script to manage DNS servers on Linux systems, such as CentOS 7. It allows users to switch between multiple DNS providers, test DNS response times, and restore original network settings (e.g., DHCP-provided DNS). The script is designed for minimal systems and includes anti-censorship DNS servers (e.g., 403.online, Radar) to bypass internet restrictions, particularly in Iran.
Features

Switch DNS Easily: Choose from 13 DNS providers using a simple number-based menu (1-13).
Test DNS Speed: Measure response times for each DNS server (requires dig from bind-utils).
Restore Original Settings: Revert to the initial network configuration (e.g., DHCP DNS like 10.0.2.3) at any time, even after restarting the script.
Persistent Backup: Saves network settings (/etc/resolv.conf, ifcfg-* files) in /root/dns_backup for reliable restoration.
Minimal Dependencies: Runs with basic Bash and Linux commands; optional dig for speed tests.
Anti-Censorship DNS: Includes providers like 403.online and Radar to access restricted repositories in censored environments.

Prerequisites

Operating System: Linux (tested on CentOS 7, compatible with other distributions).
Required Tools: Bash, standard Linux commands (cat, sed, cp, ip).
Optional: dig (part of bind-utils) for DNS speed testing. The script can automatically install it if yum is available.
Permissions: Root access (run with sudo or as the root user).

Installation

Clone the Repository:
git clone https://github.com/khshayar/DNS_changer.git
cd DNS_changer


Make the Script Executable:
chmod +x dns_changer.sh



Usage

Run the Script:
./dns_changer.sh


Menu Options:

1. Display DNS list and test speed: Lists all DNS providers with their response times (requires dig). If dig is missing, the script prompts to install bind-utils.
2. Change DNS: Select a DNS provider by entering its number (1-13). The script updates the network settings and creates a backup.
3. Restore original DNS: Reverts to the network settings before the first DNS change (e.g., DHCP-provided DNS). Works across script restarts.
4. Exit: Closes the script without making changes.


Example: Change DNS:
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
Network service restarted.


Example: Restore Original Settings:
Choose an option (1-4): 3
Restoring original network settings from /root/dns_backup...
Restored network-scripts from /root/dns_backup/network-scripts.
Do you want to restart the network to apply restored settings? (y/n): y
Network service restarted.
Backup removed.



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

Installing Packages: If yum fails to install bind-utils due to sanctions, use 403.online (number 9) or Radar (number 10) to access repositories:./dns_changer.sh
# Choose option 2, enter 9
sudo yum update


Local Repositories: Add local mirrors if needed:sudo yum install epel-release


Proxy: If DNS changes are insufficient, configure a proxy:export http_proxy="http://YOUR_PROXY:PORT"
sudo yum update



Troubleshooting

DNS Not Changing:

Verify /etc/resolv.conf:cat /etc/resolv.conf


Check the network interface configuration:cat /etc/sysconfig/network-scripts/ifcfg-enp0s3


Restart the network:sudo systemctl restart network




DHCP Overriding DNS:

If 10.0.2.3 persists (common in VirtualBox NAT), ensure PEERDNS=no in ifcfg-enp0s3:echo "PEERDNS=no" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-enp0s3
sudo systemctl restart network




Restore Not Working:

Check the backup directory:ls -l /root/dns_backup
cat /root/dns_backup/resolv.conf.bak


Manually restore if needed:sudo cp /root/dns_backup/resolv.conf.bak /etc/resolv.conf
sudo cp /root/dns_backup/network-scripts/ifcfg-* /etc/sysconfig/network-scripts/
sudo systemctl restart network




Package Installation Issues:

Inspect yum errors:sudo yum install bind-utils -v


Use 403.online or Radar DNS to resolve repository access issues.



VirtualBox Notes
If running in a VirtualBox VM with NAT networking:

The default DNS (10.0.2.3) is provided by DHCP. Option 3 restores this setting by enabling PEERDNS=yes.
If issues persist, switch to Bridged networking or disable DHCP:echo "PEERDNS=no" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-enp0s3
sudo systemctl restart network



Contributing
Contributions are welcome! To add new DNS providers, improve functionality, or fix bugs:

Fork the repository.
Create a new branch (git checkout -b feature-name).
Commit your changes (git commit -m "Add feature").
Push to the branch (git push origin feature-name).
Open a pull request.

License
This project is licensed under the MIT License. See the LICENSE file for details.
Contact
For questions, suggestions, or support, open an issue on GitHub or contact the maintainer at [YOUR_EMAIL] (optional).

Built with ❤️ by khshayar
