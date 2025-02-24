# ip_calc

This repository is the result of a task I received in school.<br>
The goal was to create a script that calculates the broadcast address from an IP address and subnet mask.


### Two scripts?
The first script, `bc_calc.sh`, is the original script I wrote for the task.<br>
The second script, `ip_calc.sh`, is an extended version I made out of boredom. (And no, it doesn't have comments. :D)

## bc_calc.sh example output:
```bash
❯ ./bc_calc.sh 192.168.0.1/24
$/> IP Address        : 192.168.1.0          11000000.10101000.00000001.00000000
$/> Subnet Mask       : 24                   11111111.11111111.11111111.00000000
$/> Wildcard          :                      00000000.00000000.00000000.11111111
$/> Broadcast Address : 192.168.1.255        11000000.10101000.00000001.11111111
```

## ip_calc.sh example output:
```bash
❯ ./ip_calc.sh 192.168.0.1/24
$/> Address    ➜  192.168.1.0          11000000.10101000.00000001.00000000
$/> Netmask    ➜  255.255.255.0 = 24   11111111.11111111.11111111.00000000
$/> Wildcard   ➜  0.0.0.255            00000000.00000000.00000000.11111111

$/> Network    ➜  192.168.1.0/24       11000000.10101000.00000001.00000000 (Class C)
$/> Broadcast  ➜  192.168.1.255        11000000.10101000.00000001.11111111
$/> HostMin    ➜  192.168.1.1          11000000.10101000.00000001.00000001
$/> HostMax    ➜  192.168.1.254        11000000.10101000.00000001.11111110
$/> Hosts/Net  ➜  254
```
