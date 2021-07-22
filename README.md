# Bind9 - DNS Server Setup

# About Bind9
* Bind9 is an official package by ISC organization,
* This package rule is to convert hostnames to IP addresses and IP to hostname.
** I'm using Debian

### Install Bind9:
```
apt install bind9 bind9utils bind9-doc dnsutils -y
cd /etc/bind/
```




* Add the db.example.com file and db.192.168.1 file 
    * Incase your local net is 10.0.0.x make sure to change IP's in all files.
    * And in my_localnets VAR on named.conf.options
    * db.192.168.1 also refer as reverse dns aka rDNS
* Change the example.com for your local domain
* Make sure to set Manual IPv4 for the machine(192.168.1.254 in our example) and even disable IPv6.

* and that's it.

# Enviroments settings
```
sudo echo "nameserver 127.0.0.1" >> /etc/resolv.conf
sudo echo "nameserver 192.168.1.254" >> /etc/resolv.conf
sudo echo "search example.com" >> /etc/resolv.conf
```

## Worth to mention that sometimes you need to flush your dns cache history
* In windows just run :
```
ipconfig /flushdns
```

* In linux run:
```
sudo /etc/init.d/dns-clean restart
sudo /etc/init.d/dnsmasq restart
```
```
sudo systemctl reload networking
sudo systemctl reload named
sudo rndc restart
```

## Script option :
```
git clone https://github.com/hindicator/Bind9-DNS-Server-Setup.git
cd Bind9-DNS-Server-Setup
sudo bash setup.sh
You'll be promped to enter - Domain & localnet values
Example -
Enter domain : google.com
Enter local net : 192.168.1
```

## Debug :
```
dig example.com
dig router.example.com
nslookup example.com
sudo named-checkzone example.com /etc/bind/db.example.com
```

# Not finished!!!
## only for educational purposes at the moment.