$TTL 3600
@       IN      SOA     hostmaster.example.com. gal.example.com. (
                    20          ; Serial
                    3600        ; Refresh
                    600         ; Retry
                    1209600     ; Expire
                    3600 )      ; Negative Cache TTL
;
;       Name server
;
@                   IN      NS      hostmaster.example.com.
hostmaster		    IN	A	192.168.1.254
;
;       Host addresses
;
router              IN	A	192.168.1.1
nas                 IN	A	192.168.1.100
website             IN	A	192.168.1.101
vmware              IN	A	192.168.1.150
;
; CNAMEs
;
www		            IN	CNAME	website
mongo               IN  CNAME   website
