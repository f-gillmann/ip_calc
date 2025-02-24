#!/bin/bash

RANDOM_COLOR=$((31 + RANDOM % 6))
COLOR="\e[${RANDOM_COLOR}m"
LIGHT_COLOR="\e[$(($RANDOM_COLOR + 60))m"
RESET_COLOR="\e[0m"
NEWLINE="\n"
PREFIX="${COLOR}\$${RESET_COLOR}/${LIGHT_COLOR}>${RESET_COLOR}"

ip_to_bin() {
    local ip=$1
    local bin_ip=""
    local IFS='.'
    read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        bin_ip="${bin_ip}$(printf "%08d" "$(echo "obase=2; $octet" | bc)")."
    done
    echo "${bin_ip%?}"
}

wildcard_mask() {
    local snm=$1
    local wildcard_ip=""
    local IFS='.'
    read -ra octets <<< "$snm"
    for octet in "${octets[@]}"; do
        wildcard_ip="${wildcard_ip}$((255 - octet))."
    done
    echo "${wildcard_ip%?}"
}

network_address() {
    local ip=$1
    local snm=$2
    local network_ip=""
    local IFS='.'
    read -ra ip_octets <<< "$ip"
    read -ra snm_octets <<< "$snm"
    for i in {0..3}; do
        network_ip="${network_ip}$((${ip_octets[i]} & ${snm_octets[i]}))."
    done
    echo "${network_ip%?}"
}

broadcast_address() {
    local net_addr=$1
    local wildcard=$2
    local broadcast_ip=""
    local IFS='.'
    read -ra net_octets <<< "$net_addr"
    read -ra wildcard_octets <<< "$wildcard"
    for i in {0..3}; do
        broadcast_ip="${broadcast_ip}$((${net_octets[i]} | ${wildcard_octets[i]}))."
    done
    echo "${broadcast_ip%?}"
}

num_hosts() {
    local snm_bits=$1
    echo "$((2**(32 - snm_bits) - 2))"
}

network_class() {
    local first_octet=$1
    if ((first_octet >= 0 && first_octet <= 127)); then
        printf "Class ${LIGHT_COLOR}A${RESET_COLOR}"
    elif ((first_octet >= 128 && first_octet <= 191)); then
        printf "Class ${LIGHT_COLOR}B${RESET_COLOR}"
    elif ((first_octet >= 192 && first_octet <= 223)); then
        printf "Class ${LIGHT_COLOR}C${RESET_COLOR}"
    elif ((first_octet >= 224 && first_octet <= 239)); then
        pritnf "Class ${LIGHT_COLOR}D${RESET_COLOR} - ${COLOR}Multicast${RESET_COLOR}"
    else
        printf "Class ${LIGHT_COLOR}E${RESET_COLOR} - ${COLOR}Research/Reserved/Experimental${RESET_COLOR}"
    fi
}

calculate_and_print() {
    local ip_input="$1"
    local ip="${ip_input%/*}"
    local snm_bits="${ip_input#*/}"

    local mask=$((0xFFFFFFFF << (32 - snm_bits)))
    local snm=$(printf "%d.%d.%d.%d" \
        $(( (mask >> 24) & 0xFF )) \
        $(( (mask >> 16) & 0xFF )) \
        $(( (mask >> 8)  & 0xFF )) \
        $(( mask & 0xFF )))


    local wildcard=$(wildcard_mask "$snm")
    local net_addr=$(network_address "$ip" "$snm")
    local broadcast=$(broadcast_address "$net_addr" "$wildcard")
    local first_octet="${ip%%.*}"
    local class=$(network_class "$first_octet")
    local num_of_hosts=$(num_hosts "$snm_bits")

    local IFS='.'
    read -ra net_octets <<< "$net_addr"
    read -ra bc_octets <<< "$broadcast"


    if [ "${net_octets[3]}" -lt 255 ]; then
        net_octets[3]=$((net_octets[3] + 1))
    fi
    host_min="${net_octets[0]}.${net_octets[1]}.${net_octets[2]}.${net_octets[3]}"


    if [ "${bc_octets[3]}" -gt 0 ]; then
        bc_octets[3]=$((bc_octets[3] - 1))
    fi
    host_max="${bc_octets[0]}.${bc_octets[1]}.${bc_octets[2]}.${bc_octets[3]}"

    # Print the result
    printf "${PREFIX} Address    ➜  %-20s %-35s${NEWLINE}" "$ip" "$(ip_to_bin "$ip")"
    printf "${PREFIX} Netmask    ➜  %-20s %-35s${NEWLINE}" "$snm = $snm_bits" "$(ip_to_bin "$snm")"
    printf "${PREFIX} Wildcard   ➜  %-20s %-35s${NEWLINE}" "$wildcard" "$(ip_to_bin "$wildcard")"
    printf "${NEWLINE}"
    printf "${PREFIX} Network    ➜  %-20s %-35s (%s)${NEWLINE}" "$net_addr/$snm_bits" "$(ip_to_bin "$net_addr")" "$class"
    printf "${PREFIX} Broadcast  ➜  %-20s %-35s${NEWLINE}" "$broadcast" "$(ip_to_bin "$broadcast")"
    printf "${PREFIX} HostMin    ➜  %-20s %-35s${NEWLINE}" "$host_min" "$(ip_to_bin "$host_min")"
    printf "${PREFIX} HostMax    ➜  %-20s %-35s${NEWLINE}" "$host_max" "$(ip_to_bin "$host_max")"
    printf "${PREFIX} Hosts/Net  ➜  %s${NEWLINE}" "$num_of_hosts"
}

# Validate input and call the function
if [[ $# -eq 1 ]]; then
    ip_input="$1"
    if [[ $ip_input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        calculate_and_print "$ip_input"
    else
        printf "${PREFIX}Invalid input. Please use the format Address/Netmask${NEWLINE}"
    fi
else
    printf "${PREFIX}Usage: $0 Address/Netmask${NEWLINE}"
fi