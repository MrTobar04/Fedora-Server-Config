$TTL 86400
@   IN  SOA     ns1.semita.sv. admin.semita.sv. (
        2024012001  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)

; Servidores de nombres
        IN  NS      ns1.semita.sv.
        IN  NS      ns2.semita.sv.

; Registros A (IPv4)
ns1     IN  A       172.16.0.2
ns2     IN  A       172.16.0.3
www     IN  A       172.16.0.2
mail    IN  A       172.16.0.20
@       IN  A       172.16.0.10

; Registros AAAA (IPv6)
ns1     IN  AAAA    2001:db7:dea:a::2
ns2     IN  AAAA    2001:db7:dea:a::3
www     IN  AAAA    2001:db7:dea:a::2
mail    IN  AAAA    2001:db7:dea:a::20
@       IN  AAAA    2001:db7:dea:a::10

; Registros MX
        IN  MX  10  mail.semita.sv.

; Registros TXT
        IN  TXT     "v=spf1 mx -all"

; Registros CNAME
ftp     IN  CNAME   www.semita.sv.

