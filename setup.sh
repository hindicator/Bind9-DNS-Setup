#!/usr/bin/env bash

printf "Updating packages\n"
sudo apt update && apt upgrade -y
State=0
printf "The following packages are going to install : bind9, bind9utils, bind9-doc, dnsutils\n"
printf "Do You agree ? (y/N)"
read Answer



if [ "$Answer" == "y" ]; then
    sudo apt install bind9 bind9utils bind9-doc dnsutils -y
    printf "Everything installed successfully and up to date\n"
    $State=1
else
    printf "Creating files on /etc/bind directory, if dir not exist,\nCreating a new one automatically\n"
    mkdir -p /etc/bind/
fi

printf "Please enter your domain name : \n"
read -r DOMAIN
printf "Please enter you local ip :\nExample : 192.168.1 or 10.0.0\n"
read -r LOCALNET
rLocalnet=$(echo $LOCALNET | rev)
cat > /etc/bind/db.$DOMAIN << EOF
$TTL 3600
@       IN      SOA     hostmaster.$DOMAIN. admin.$DOMAIN. (
                    20          ; Serial
                    3600        ; Refresh
                    600         ; Retry
                    1209600     ; Expire
                    3600 )      ; Negative Cache TTL
;
;       Name server
;
@                   IN      NS      hostmaster.$DOMAIN.
hostmaster		    IN	A	$LOCALNET.254
;
;       Host addresses
;
router              IN	A	$LOCALNET.1
nas                 IN	A	$LOCALNET.100
website             IN	A	$LOCALNET.101
vmware              IN	A	$LOCALNET.150
;
; CNAMEs
;
www		            IN	CNAME	website
mongo               IN  CNAME   website
EOF
printf "db.$DOMAIN was created at /etc/bind/~.\n"

cat > /etc/bind/db.$LOCALNET << EOF
$TTL 3600
@       IN      SOA     hostmaster.$DOMAIN. admin.$DOMAIN. (
                        21          ; Serial
                        3600        ; Refresh
                        600         ; Retry
                        1209600     ; Expire
                        3600 )      ; Negative Cache TTL
;
;       Name server
;
;       You can add another DNS here for segmentation
; Example :     blackhole   IN  NS  192.168.2.254
; Note : you may want to use astrix or 
; create a new db file for 192.168.2.x and configure it as a slave zone in named.conf.local file
@		        IN      NS      hostmaster.$DOMAIN.
hostmaster		IN      A       $LOCALNET.254
;
;       Addresses point to canonical name
;
1               IN      PTR     router.$DOMAIN.
100             IN      PTR     nas.$DOMAIN.
150             IN      PTR     vmware.$DOMAIN.
254             IN      PTR     hostmaster.$DOMAIN.
; CNAMES CAN BE ADDED HERE TOO
EOF
printf "db.$LOCALNET was created at /etc/bind/~\n"
printf "Would you like to replace the current configuration for named.conf.local ?(y/N)"
read Answer
if [ "$Answer" == "y" ]; then
    cat > /etc/bind/named.conf.local << EOF
    //
    // Do any local configuration here
    //

    // Consider adding the 1918 zones here, if they are not used in your
    // organization
    //include "/etc/bind/zones.rfc1918";

    acl my_localnets {
        127.0.0.0/8;        // localhost (RFC 3330) - Loopback-Device addresses    127.0.0.0 - 127.255.255.255  
        $LOCALNET.0/24;     // Private Network (RFC 1918) - e. e. LAN              192.168.0.0 - 192.168.255.255 
    //     10.0.0.0/8;         // Private Network (RFC 1918) - e. g. VPN              10.0.0.0 - 10.255.255.255
    };

    zone "$DOMAIN" {
        type master;
        file "/etc/bind/db.$DOMAIN";
        // Possible option are :
        // allow-update { my_localnets; };      // Since this is the primary DNS, it should be none.
        // allow-transfer { my_localnets; };    //Allow Transfer of zone from the master server
        // allow-notify { my_localnets; };      //Notify slave for zone changes
    };
    zone "$rLocalnet.in-addr.arpa" {
        type master;
        file "/etc/bind/db.$LOCALNET";
    };
    //  zone "sub.example.com" {
        //  type slave; //Secondary Slave DNS
        //  file "/etc/bind/db.sub.example.com";    //Forward Zone Cache file
        //  masters { $LOCALNET.254; }; //Master Server IP
    //  };
EOF
fi
printf "Would you like to replace to current named.conf.options file ?"
read Answer
if [ "$Answer" == "y" ]; then
    cat << EOF > /etc/bind/named.conf.options
    /*
    * You might put in here some ips which are allowed to use the cache or
    * recursive queries
    */
    acl my_localnets {
        127.0.0.0/8;        // localhost (RFC 3330) - Loopback-Device addresses    127.0.0.0 - 127.255.255.255  
        $LOCALNET.0/24;     // Private Network (RFC 1918) - e. e. LAN              192.168.0.0 - 192.168.255.255 
    //     10.0.0.0/8;         // Private Network (RFC 1918) - e. g. VPN              10.0.0.0 - 10.255.255.255
    };


    //********************************************************************************
    options {
            /*
            * Is a quoted string defining the absolute path for the server e.g. "/var/named".
            * All subsequent relative paths use this base directory. If no directory options 
            * is specified the directory from which BIND was loaded is used.
            */
            directory "/var/cache/bind";

            /*
            * Is a quoted string and allows you to define where the pid (Process Identifier)
            * used by BIND is written. If not present it is distribution or OS specific 
            * typically /var/run/named.pid or /etc/named.pid. It may be defined using an 
            * absolute path or relative to the directory parameter.
            */
            pid-file "/var/run/named/named.pid";

            /*
            * Specifies the string that will be returned to a version.bind query when using 
            * the chaos class only. version_string is a quoted string, for example, "get lost"
            * or something equally to the point. We tend to use it in all named.conf files to
            * avoid giving out a version number such that an attacker can exploit known 
            * version-specific weaknesses.
            */
            version "not currently available"; 

            /* 
            * Turns on BIND to listen for IPv6 queries. If this statement is not present and the 
            * server supports IPv6 (only or in dual stack mode) the server will listen for IPv6 on
            * port 53 on all server interfaces. If the OS supports RFC 3493 and RFC 3542 compliant
            * IPv6 sockets and the address_match_list uses the special any name then a single listen
            * is issued to the wildcard address. If the OS does not support this feature a socket is
            * opened for every required address and port. The port default is 53.
            * Multiple listen-on-v6 statements are allowed.
            */
            listen-on-v6 { none; };

            /* Defines the port and IP address(es) on which BIND will listen for incoming queries.
            * The default is port 53 on all server interfaces.
            * Multiple listen-on statements are allowed.
            */
            listen-on { my_localnets; };

            /* Notify behaviour is applicable to both master zones (with 'type master;')
            * and slave zones (with 'type slave;') and if set to 'yes' (the default) then,
            * when a zone is loaded or changed, for example, after a zone transfer, NOTIFY
            * messages are sent to the name servers defined in the NS records for the zone
            * (except itself and the 'Primary Master' name server defined in the SOA record)
            * and to any IPs listed in any also-notify statement.
            * If set to 'no' NOTIFY messages are not sent.
            * If set to 'explicit' NOTIFY is only sent to those IP(s) listed in an also-notify statement.
            */
            notify yes;

            /*
            * Defines an match list of IP address(es) which are allowed 
            * to issue queries to the server.
            * Only trusted addresses are allowed to perform queries.
            * We will allow anyone to query our master zones below.
            * This prevent becoming a public free DNS server.
            */
            allow-query {
                    my_localnets;
            };

            /*
            * Defines an match list of IP address(es) which are allowed to
            * issue queries that access the local query cache.
            * Only trusted addresses are allowed to use query cache.
            */
            allow-query-cache {
                    my_localnets;
            };

            /* 
            * Defines a match list of IP address(es) which are allowed to
            * issue recursive queries to the server.
            * Only trusted addresses are allowed to use recursion. 
            */
            allow-recursion {
                    my_localnets;
            };

            /* 
            * Dfines a match list e.g. IP address(es) that are allowed to transfer
            * the zone information from the server (master or slave for the zone).
            * The default behaviour is to allow zone transfers to any host.
            */
            allow-transfer {
                    my_localnets;
            };

            /* 
            * Defines an match list of host IP address(es) that are allowed
            * to submit dynamic updates for master zones, and thus this 
            * statement enables Dynamic DNS.
            */
            allow-update {
                    my_localnets;
            };

            /*
            * Indicates that a resolver (a caching or caching-only name server) will attempt
            * to validate replies from DNSSEC enabled (signed) zones. To perform this task 
            * the server alos needs either a valid trusted-keys clause (containing one or more
            * trusted-anchors or a managed-keys clause.
            * Since 9.5 the default value is dnssec-validation yes;
            */
            dnssec-validation yes;

            /*
            * If auth-nxdomain is 'yes' allows the server to answer authoritatively
            * (the AA bit is set) when returning NXDOMAIN (domain does not exist) answers,
            * if 'no' (the default) the server will not answer authoritatively.
            */
            auth-nxdomain no; # conform to RFC1035

            /*
            * By default empty-zones-enable is set to 'yes' which means that 
            * reverse queries for IPv4 and IPv6 addresses covered by RFCs 1918,
            * 4193, 5737 and 6598 (as well as IPv6 local address (locally assigned),
            * IPv6 link local addresses, the IPv6 loopback address and the IPv6 unknown address)
            * but which is not not covered by a locally defined zone clause will automatically 
            * return an NXDOMAIN response from the local name server. This prevents reverse map queries
            * to such addresses escaping to the DNS hierarchy where they are simply noise and increase 
            * the already high level of query pollution caused by mis-configuration.
            */
            empty-zones-enable yes;

            /* 
            * If recursion is set to 'yes' (the default) the server will always provide
            * recursive query behaviour if requested by the client (resolver).
            * If set to 'no' the server will only provide iterative query behaviour -
            * normally resulting in a referral. If the answer to the query already
            * exists in the cache it will be returned irrespective of the value of this statement.
            * This statement essentially controls caching behaviour in the server.
            */
            recursion yes;
            
            /* 
            * additional-from-auth and additional-from-cache control the behaviour when
            * zones have additional (out-of-zone) data or when following CNAME or DNAME records.
            * These options are for used for configuring authoritative-only (non-caching) servers
            * and are only effective if recursion no is specified in a global options clause or
            * in a view clause. The default in both cases is yes.
            */ 
            //additional-from-auth no;
            //additional-from-cache no;

            /* 
            * Defines a list of IP address(es) and optional port numbers
            * to which queries will be forwarded. 
            */        
            forwarders {
                    // Router DNS
                    // 192.168.2.1

                    // Google Public DNS
                    // 8.8.8.8;
                    // 8.8.4.4;
    
                    // OpenDNS
                    // 208.67.222.222;
                    // 208.67.220.220;

                    1.1.1.1;
                    1.0.0.1;
            };
    };
EOF
fi

printf "All configuration are successfully deployed with\nDomain as $DOMAIN\nLocalnet as $LOCALNET.x\n"
printf "You can look at the configuration files for more information on subnet tunneling, etc..\n"

if [ $STATE == 1 ]; then
    sudo systemctl enable bind9
else
    printf "please run the following command to automatically run bind9 on boot\nsystemctl enable bind9"
fi

clear
printf "Reboot is needed to apply the configuration.\nWould you like to reboot now ? (y/N)"

read Answer
if [ "$Answer" == "y" ]; then 
    sudo reboot
fi