#!/bin/bash

RANDOM_COLOR=$((31 + RANDOM % 6))
COLOR="\e[${RANDOM_COLOR}m"
LIGHT_COLOR="\e[$(($RANDOM_COLOR + 60))m"
RESET_COLOR="\e[0m"
NEWLINE="\n"
PREFIX="${COLOR}\$${RESET_COLOR}/${LIGHT_COLOR}>${RESET_COLOR}"

# ---
# Assuming our input IP is 192.168.1.0 and our input subnet is 24 for all comments.
# ---

if [[ $# -eq 1 ]]; then
    ip_input="$1"
    # I found this regex god knows where, how it even works? Who knows?
    if [[ $ip_input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then 
        # Seperate subnet mask from IP
        ip="${ip_input%/*}"  # (e.g., "192.168.1.0")
        snm="${ip_input#*/}" # (e.g., "24")
    else
        printf "${PREFIX}Invalid input. Please use the format Address/Netmask${NEWLINE}"
    fi
else
    printf "${PREFIX}Usage: $0 Address/Netmask${NEWLINE}"
fi

# ---
# Now we need to convert the IP into binary for further calculation.
# ---

# Split the IP into 4 octets by using '.' as a seperator.
IFS='.' read -r ip_o1 ip_o2 ip_o3 ip_o4 <<< "$ip"

# Convert every octet into binary.
bin_ip_o1=$(printf "%08d" $(bc <<< "obase=2; $ip_o1")) # 11000000
bin_ip_o2=$(printf "%08d" $(bc <<< "obase=2; $ip_o2")) # 10101000
bin_ip_o3=$(printf "%08d" $(bc <<< "obase=2; $ip_o3")) # 00000001
bin_ip_o4=$(printf "%08d" $(bc <<< "obase=2; $ip_o4")) # 00001010

# Put them back together.
bin_ip="${bin_ip_o1}${bin_ip_o2}${bin_ip_o3}${bin_ip_o4}"           # 11000000 10101000 00000001 00001010
bin_ip_result="${bin_ip_o1}.${bin_ip_o2}.${bin_ip_o3}.${bin_ip_o4}" # 11000000.10101000.00000001.00001010

# ---
# Also convert the subnet mask to binary.
# ---

# Add 1's for all the subnet mark bits.
ones=$(printf '%*s' "$snm" | tr ' ' '1')         # 11111111 11111111 11111111

# Add additional 0's for the rest of the missing bits.
zeros=$(printf '%*s' $((32 - snm)) | tr ' ' '0') # 00000000

# Put them together and Insert a dot after every 8 bits.
bin_snm="${ones}${zeros}"                                                      # 11111111 11111111 11111111 00000000 
bin_snm_result="${bin_snm:0:8}.${bin_snm:8:8}.${bin_snm:16:8}.${bin_snm:24:8}" # 11111111.11111111.11111111.00000000 

# ---
# Invert the binary subnet mask to get the wildcard.
# ---

# Swap 0's with 1's and vice versa.
bin_wc_snm=$(echo "$bin_snm" | tr '10' '01')                                                  # 00000000 00000000 00000000 11111111
bin_wc_snm_result="${bin_wc_snm:0:8}.${bin_wc_snm:8:8}.${bin_wc_snm:16:8}.${bin_wc_snm:24:8}" # 00000000.00000000.00000000.11111111

# ---
# Perform a bitwise OR on each bit of the wildcard subnet mask and binary ip address.
# ---

# Bitwise OR.
bin_bc_ip=""

# Loop through each bit position (0 to 31).
for (( i=0; i<32; i++ )); do
    # Extract the i'th bit from both binary strings.
    bit_ip=${bin_ip:$i:1}
    bit_wc=${bin_wc_snm:$i:1}
    # Perform the OR operation and add the result to the broadcast ip.
    if [[ "$bit_ip" == "1" || "$bit_wc" == "1" ]]; then
        bin_bc_ip+="1"
    else
        bin_bc_ip+="0"
    fi
done

# Add dots after every 8 bits.
bin_bc_ip_result="${bin_bc_ip:0:8}.${bin_bc_ip:8:8}.${bin_bc_ip:16:8}.${bin_bc_ip:24:8}"

# Convert binary broadcast IP back to decimal.
bc_ip_o1=$((2#${bin_bc_ip:0:8}))
bc_ip_o2=$((2#${bin_bc_ip:8:8}))
bc_ip_o3=$((2#${bin_bc_ip:16:8}))
bc_ip_o4=$((2#${bin_bc_ip:24:8}))

bc_ip_result="${bc_ip_o1}.${bc_ip_o2}.${bc_ip_o3}.${bc_ip_o4}"

# ---
# Print out all our results.
# ---

printf "${PREFIX} IP Address        : %-20s %-35s${NEWLINE}" "$ip" "$bin_ip_result"
printf "${PREFIX} Subnet Mask       : %-20s %-35s${NEWLINE}" "$snm" "$bin_snm_result"
printf "${PREFIX} Wildcard          : %-20s %-35s${NEWLINE}" "" "$bin_wc_snm_result"
printf "${PREFIX} Broadcast Address : %-20s %-35s${NEWLINE}" "$bc_ip_result" "$bin_bc_ip_result"
