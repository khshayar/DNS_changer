#!/bin/bash

# List of DNS servers (fixed order)
dns_names=("Shecan" "Electro" "Cloudflare" "Google" "AdGuard" "Quad9" "OpenDNS" "NextDNS" "403.online" "Radar" "Comodo" "CleanBrowsing" "DNS.WATCH")
declare -A dns_list=(
    ["Shecan"]="178.22.122.100 185.51.200.2"
    ["Electro"]="78.157.42.100 78.157.42.101"
    ["Cloudflare"]="1.1.1.1 1.0.0.1"
    ["Google"]="8.8.8.8 8.8.4.4"
    ["AdGuard"]="94.140.14.14 94.140.15.15"
    ["Quad9"]="9.9.9.9 149.112.112.112"
    ["OpenDNS"]="208.67.222.222 208.67.220.220"
    ["NextDNS"]="45.90.28.0 45.90.30.0"
    ["403.online"]="10.202.10.10 10.202.10.11"
    ["Radar"]="10.10.34.35 10.10.34.36"
    ["Comodo"]="8.26.56.26 8.20.247.20"
    ["CleanBrowsing"]="185.228.168.9 185.228.169.9"
    ["DNS.WATCH"]="84.200.69.80 84.200.70.40"
)

# Fixed backup directory
BACKUP_DIR="/root/dns_backup"
BACKUP_RESOLV="$BACKUP_DIR/resolv.conf.bak"
BACKUP_NETWORK_SCRIPTS="$BACKUP_DIR/network-scripts"

# Function to create backup
create_backup() {
    # Only create backup if it doesn't already exist
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Creating backup of network settings in $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        
        # Backup /etc/resolv.conf
        if [ -f /etc/resolv.conf ]; then
            cp /etc/resolv.conf "$BACKUP_RESOLV"
            echo "Backed up /etc/resolv.conf to $BACKUP_RESOLV."
        fi
        
        # Backup network-scripts (CentOS 7)
        if [ -d /etc/sysconfig/network-scripts ]; then
            mkdir -p "$BACKUP_NETWORK_SCRIPTS"
            cp -r /etc/sysconfig/network-scripts/ifcfg-* "$BACKUP_NETWORK_SCRIPTS" 2>/dev/null
            echo "Backed up network-scripts to $BACKUP_NETWORK_SCRIPTS."
        fi
        
        # Backup systemd-resolved config
        if [ -f /etc/systemd/resolved.conf ]; then
            cp /etc/systemd/resolved.conf "$BACKUP_DIR/resolved.conf.bak"
            echo "Backed up systemd-resolved config to $BACKUP_DIR/resolved.conf.bak."
        fi
    fi
}

# Function to show current DNS
show_current_dns() {
    echo "Current system DNS servers:"
    if [ -f /etc/resolv.conf ]; then
        grep "nameserver" /etc/resolv.conf || echo "No DNS servers configured."
    else
        echo "/etc/resolv.conf does not exist."
    fi
}

# Function to test DNS speed (requires dig)
test_dns_speed() {
    local dns=$1
    local result=$(dig @${dns} google.com +time=2 +tries=1 +stats 2>/dev/null | grep "Query time" | awk '{print $4}')
    if [ -z "$result" ]; then
        echo "9999" # High time for no response
else
        echo "$result"
    fi
}

# Function to install bind-utils if dig is not available
install_dig() {
    echo "dig is not installed. This is required for DNS speed testing."
    read -p "Do you want to install bind-utils? (y/n): " install_choice
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
        if command -v yum >/dev/null 2>&1; then
            yum install bind-utils -y
            if [ $? -eq 0 ]; then
                echo "bind-utils installed successfully."
                return 0
            else
                echo "Failed to install bind-utils. You may need to fix yum or install manually."
                return 1
            fi
        else
            echo "yum not found. Please install bind-utils manually: sudo yum install bind-utils"
            return 1
        fi
    else
        echo "Skipping bind-utils installation. Speed test will not be available."
        return 1
    fi
}

# Function to display DNS list and test speed
display_and_test_dns() {
    echo "Available DNS servers:"
    local speeds=()
    
    # Check if dig is available
    if ! command -v dig >/dev/null 2>&1; then
        install_dig
        if ! command -v dig >/dev/null 2>&1; then
            # If dig is still not available, just list DNS servers
            for i in "${!dns_names[@]}"; do
                name=${dns_names[$i]}
                echo "$((i+1)). $name: ${dns_list[$name]}"
            done
            return
        fi
    fi
    
    # Perform speed test if dig is available
    for i in "${!dns_names[@]}"; do
        name=${dns_names[$i]}
        primary_dns=$(echo ${dns_list[$name]} | awk '{print $1}')
        speed=$(test_dns_speed $primary_dns)
        speeds+=("$name:$speed")
        echo "$((i+1)). $name: ${dns_list[$name]} (Response time: ${speed}ms)"
    done

    # Find fastest DNS
    fastest_dns=$(printf "%s\n" "${speeds[@]}" | sort -t: -k2 -n | head -n 1)
    fastest_name=$(echo $fastest_dns | cut -d: -f1)
    echo -e "\nFastest DNS: $fastest_name (${dns_list[$fastest_name]})"
}

# Function to detect network service
detect_network_service() {
    if [ -d /etc/sysconfig/network-scripts ]; then
        echo "NetworkScripts" # CentOS 7
    elif [ -f /etc/systemd/resolved.conf ]; then
        echo "systemd-resolved"
    else
        echo "Manual"
    fi
}

# Function to select main network interface
select_main_interface() {
    # Get the first active interface that is not lo or docker0
    local interface=$(ip link | grep "state UP" | awk -F': ' '{print $2}' | grep -v "lo" | grep -v "docker0" | head -n 1)
    if [ -n "$interface" ]; then
        # Find the corresponding ifcfg file
        local ifcfg_file=$(ls /etc/sysconfig/network-scripts/ifcfg-* | grep -v "lo$" | grep -v "docker0" | grep "$interface" | head -n 1)
        if [ -n "$ifcfg_file" ]; then
            echo "$ifcfg_file"
        else
            # Fallback to first non-lo, non-docker0 interface
            ls /etc/sysconfig/network-scripts/ifcfg-* | grep -v "lo$" | grep -v "docker0" | head -n 1
        fi
    else
        echo ""
    fi
}

# Function to apply DNS changes
change_dns() {
    local dns_index=$1
    local dns_name=${dns_names[$dns_index]}
    local dns_servers=${dns_list[$dns_name]}
    local service=$(detect_network_service)

    # Create backup if not already done
    create_backup

    case $service in
        "NetworkScripts")
            local interface=$(select_main_interface)
            if [ -n "$interface" ]; then
                # Remove previous DNS entries
                sed -i '/DNS[12]=/d' "$interface"
                sed -i '/PEERDNS=/d' "$interface"
                # Add new DNS entries and disable DHCP DNS
                echo "DNS1=${dns_servers%% *}" | tee -a "$interface" >/dev/null
                echo "DNS2=${dns_servers##* }" | tee -a "$interface" >/dev/null
                echo "PEERDNS=no" | tee -a "$interface" >/dev/null
                echo "DNS set to $dns_name in $interface."
            else
                echo "No valid network configuration file found."
                exit 1
            fi
            ;;
        "systemd-resolved")
            sed -i "/^DNS=/c\DNS=$dns_servers" /etc/systemd/resolved.conf
            echo "DNS set to $dns_name in systemd-resolved."
            ;;
        "Manual")
            chattr -i /etc/resolv.conf 2>/dev/null
            echo "nameserver ${dns_servers// /\\nnameserver }" > /etc/resolv.conf
            echo "DNS set to $dns_name in /etc/resolv.conf."
            chattr +i /etc/resolv.conf 2>/dev/null
            ;;
        *)
            echo "Unknown network service."
            exit 1
            ;;
    esac

    # Ask user if they want to restart network
    read -p "Do you want to restart the network to apply changes? (y/n): " restart_choice
    if [ "$restart_choice" = "y" ] || [ "$restart_choice" = "Y" ]; then
        case $service in
            "NetworkScripts")
                systemctl restart network 2>/dev/null
                echo "Network service restarted."
                ;;
            "systemd-resolved")
                systemctl restart systemd-resolved 2>/dev/null
                echo "systemd-resolved restarted."
                ;;
            "Manual")
                local interface=$(ip link | grep "state UP" | awk -F': ' '{print $2}' | grep -v "lo" | grep -v "docker0" | head -n 1)
                if [ -n "$interface" ]; then
                    ip link set $interface down
                    ip link set $interface up
                    echo "Network interface $interface restarted."
                else
                    echo "No active network interface found."
                fi
                ;;
        esac
    else
        echo "Network not restarted. Changes may not apply until network is restarted."
    fi
}

# Function to restore original settings
restore_dns() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "No backup found. Cannot restore."
        return 1
    fi

    local service=$(detect_network_service)
    echo "Restoring original network settings from $BACKUP_DIR..."

    case $service in
        "NetworkScripts")
            if [ -d "$BACKUP_NETWORK_SCRIPTS" ]; then
                cp -r "$BACKUP_NETWORK_SCRIPTS"/ifcfg-* /etc/sysconfig/network-scripts/ 2>/dev/null
                # Ensure PEERDNS=yes to allow DHCP DNS
                local interface=$(select_main_interface)
                if [ -n "$interface" ]; then
                    sed -i '/PEERDNS=/d' "$interface"
                    echo "PEERDNS=yes" | tee -a "$interface" >/dev/null
                fi
                echo "Restored network-scripts from $BACKUP_NETWORK_SCRIPTS."
            else
                echo "No network-scripts backup found."
            fi
            ;;
        "systemd-resolved")
            if [ -f "$BACKUP_DIR/resolved.conf.bak" ]; then
                cp "$BACKUP_DIR/resolved.conf.bak" /etc/systemd/resolved.conf
                echo "Restored systemd-resolved config."
            else
                echo "No systemd-resolved backup found."
            fi
            ;;
        "Manual")
            if [ -f "$BACKUP_RESOLV" ]; then
                chattr -i /etc/resolv.conf 2>/dev/null
                cp "$BACKUP_RESOLV" /etc/resolv.conf
                echo "Restored /etc/resolv.conf."
                chattr +i /etc/resolv.conf 2>/dev/null
            else
                echo "No resolv.conf backup found."
            fi
            ;;
    esac

    # Ask user if they want to restart network
    read -p "Do you want to restart the network to apply restored settings? (y/n): " restart_choice
    if [ "$restart_choice" = "y" ] || [ "$restart_choice" = "Y" ]; then
        case $service in
            "NetworkScripts")
                systemctl restart network 2>/dev/null
                echo "Network service restarted."
                ;;
            "systemd-resolved")
                systemctl restart systemd-resolved 2>/dev/null
                echo "systemd-resolved restarted."
                ;;
            "Manual")
                local interface=$(ip link | grep "state UP" | awk -F': ' '{print $2}' | grep -v "lo" | grep -v "docker0" | head -n 1)
                if [ -n "$interface" ]; then
                    ip link set $interface down
                    ip link set $interface up
                    echo "Network interface $interface restarted."
                else
                    echo "No active network interface found."
                fi
                ;;
        esac
    else
        echo "Network not restarted. Restored settings may not apply until network is restarted."
    fi

    # Remove backup after successful restore
    rm -rf "$BACKUP_DIR"
    echo "Backup removed."
}

# Main menu
main() {
    echo "DNS Changer Script"
    show_current_dns
    echo -e "\n1. Display DNS list and test speed"
    echo "2. Change DNS"
    echo "3. Restore original DNS"
    echo "4. Exit"
    read -p "Choose an option (1-4): " choice

    case $choice in
        1)
            display_and_test_dns
            main
            ;;
        2)
            echo "Select a DNS by number:"
            for i in "${!dns_names[@]}"; do
                echo "$((i+1)). ${dns_names[$i]}: ${dns_list[${dns_names[$i]}]}"
            done
            read -p "Enter the number (1-${#dns_names[@]}): " dns_choice
            if [[ "$dns_choice" =~ ^[0-9]+$ && "$dns_choice" -ge 1 && "$dns_choice" -le ${#dns_names[@]} ]]; then
                change_dns $((dns_choice-1))
            else
                echo "Invalid DNS number!"
            fi
            main
            ;;
        3)
            restore_dns
            main
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice!"
            main
            ;;
    esac
}

# Run the script
main