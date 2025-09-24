
# Guía Básica de Configuración de Fedora

Esta guía cubre la configuración de servicios esenciales en Fedora: SSH, DHCP y DNS.

---

## 1. Configuración del Servicio SSH

### Actualizar el sistema
```bash
sudo dnf check-update
sudo dnf upgrade
```

### Verificar estado del firewall
```bash
sudo firewall-cmd --state
sudo firewall-cmd --reload
```

### Habilitar e iniciar el servicio SSH
```bash
sudo systemctl enable sshd
sudo systemctl start sshd
systemctl status sshd
```

### Agregar regla de firewall para SSH
```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.2.2" port port="22" protocol="tcp" accept'
```

### Configurar redirección de puertos en VirtualBox
- Puerto `2223` del host → Puerto `22` del guest (Fedora)

### Conectar desde el host
```bash
ssh -p 2223 fedora@localhost
```

---

## 2. Configuración del Servicio DHCP

### Configurar interfaz de red (`enp0s8`)
Archivo: `/etc/NetworkManager/system-connections/enp0s8.nmconnection`

```ini
[connection]
id=enp0s8
type=ethernet
interface-name=enp0s8
zone=internal

[ipv4]
address1=172.16.0.2/24
dns=172.16.0.2;
dns-search=semita.sv;
gateway=172.16.0.1
method=manual

[ipv6]
address1=2001:db7:dea:a::2/64
dns=2001:db7:dea:a::2;
dns-search=semita.sv;
gateway=2001:db7:dea:a::1
method=manual
```

### Instalar y configurar `radvd` (Router Advertisements)
```bash
sudo dnf install radvd -y
```

Archivo: `/etc/radvd.conf`
```conf
interface enp0s8 {
    AdvSendAdvert on;
    MinRtrAdvInterval 30;
    MaxRtrAdvInterval 100;
    prefix 2001:db7:dea:a::/64 {
        AdvOnLink on;
        AdvAutonomous on;
    };
    AdvManagedFlag off;
    AdvOtherConfigFlag on;
};
```

### Instalar y configurar Kea DHCP
```bash
sudo dnf install kea
```

#### Configuración DHCPv4: `/etc/kea/kea-dhcp4.conf`
```json
{
  "Dhcp4": {
    "interfaces-config": { "interfaces": ["enp0s8"] },
    "lease-database": { "type": "memfile", "lfc-interval": 3600 },
    "subnet4": [{
      "id": 1,
      "subnet": "172.16.0.0/24",
      "pools": [{ "pool": "172.16.0.51 - 172.16.0.100" }],
      "option-data": [
        { "name": "domain-name-servers", "data": "172.16.0.2" },
        { "name": "domain-name", "data": "semita.sv" }
      ]
    }],
    "valid-lifetime": 4000,
    "renew-timer": 1000,
    "rebind-timer": 2000
  }
}
```

#### Configuración DHCPv6: `/etc/kea/kea-dhcp6.conf`
```json
{
  "Dhcp6": {
    "interfaces-config": { "interfaces": ["enp0s8"] },
    "lease-database": { "type": "memfile", "lfc-interval": 3600 },
    "subnet6": [{
      "id": 1,
      "subnet": "2001:db7:dea:a::/64",
      "pools": [{ "pool": "2001:db7:dea:a::100-2001:db7:dea:a::200" }],
      "option-data": [
        { "name": "dns-servers", "data": "2001:db7:dea:a::2" },
        { "name": "domain-search", "data": "semita.sv" }
      ]
    }],
    "preferred-lifetime": 3000,
    "valid-lifetime": 4000,
    "renew-timer": 1000,
    "rebind-timer": 2000
  }
}
```

### Reiniciar servicios
```bash
systemctl restart kea-dhcp4.service
systemctl restart kea-dhcp6.service
systemctl status kea-dhcp4.service
systemctl status kea-dhcp6.service
```

### Reglas de firewall para DHCP
```bash
sudo firewall-cmd --permanent --zone=internal --add-interface=enp0s8
sudo firewall-cmd --permanent --zone=internal --add-rich-rule='rule family="ipv4" source address="172.16.0.0/24" destination address="172.16.0.2" port port="67" protocol="udp" accept'
sudo firewall-cmd --permanent --zone=internal --add-port=547/udp
sudo firewall-cmd --reload
```

### Probar desde el cliente
```bash
sudo dhclient -6 -v enp0s8
sudo journalctl -u kea-dhcp6 -f
```

---

## 3. Configuración del Servicio DNS

### Instalar BIND9
```bash
sudo dnf install bind bind-utils
```

### Configurar `/etc/named.conf`
```conf
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory "/var/named";
    allow-query { any; };
    recursion no;
    dnssec-validation yes;
};

zone "semita.sv" {
    type master;
    file "/var/named/db.semita.sv";
};

zone "16.172.in-addr.arpa" {
    type master;
    file "/var/named/db.inversav4";
};

zone "a.0.0.0.a.e.d.0.7.b.d.0.1.0.0.2.ip6.arpa" {
    type master;
    file "/var/named/db.inversav6";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```

### Zona directa: `/var/named/db.semita.sv`
```bind
$TTL 86400
@ IN SOA ns1.semita.sv. admin.semita.sv. (
    2024012001 ; Serial
    3600       ; Refresh
    1800       ; Retry
    604800     ; Expire
    86400      ; Minimum TTL
)

; NS Records
IN NS ns1.semita.sv.
IN NS ns2.semita.sv.

; A Records
ns1  IN A 172.16.0.2
ns2  IN A 172.16.0.3
www  IN A 172.16.0.10
mail IN A 172.16.0.20
@    IN A 172.16.0.10

; AAAA Records
ns1  IN AAAA 2001:db7:dea:a::2
ns2  IN AAAA 2001:db7:dea:a::3
www  IN AAAA 2001:db7:dea:a::10
mail IN AAAA 2001:db7:dea:a::20
@    IN AAAA 2001:db7:dea:a::10

; MX Record
IN MX 10 mail.semita.sv.

; TXT Record
IN TXT "v=spf1 mx -all"

; CNAME
ftp IN CNAME www.semita.sv.
```

### Zona inversa IPv4: `/var/named/db.inversav4`
```bind
$TTL 86400
@ IN SOA ns1.semita.sv. admin.semita.sv. (
    2024012001 ; Serial
    3600       ; Refresh
    1800       ; Retry
    604800     ; Expire
    86400      ; Minimum TTL
)

; NS Records
IN NS ns1.semita.sv.
IN NS ns2.semita.sv.

; PTR Records
2.0  IN PTR ns1.semita.sv.
3.0  IN PTR ns2.semita.sv.
10.0 IN PTR www.semita.sv.
20.0 IN PTR mail.semita.sv.
```

### Zona inversa IPv6: `/var/named/db.inversav6`
```bind
$TTL 86400
@ IN SOA ns1.semita.sv. admin.semita.sv. (
    2024012001 ; Serial
    3600       ; Refresh
    1800       ; Retry
    604800     ; Expire
    86400      ; Minimum TTL
)

; NS Records
IN NS ns1.semita.sv.
IN NS ns2.semita.sv.

; PTR Records
2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.0.0.0.a.e.d.0.7.b.d.0.1.0.0.2.ip6.arpa. IN PTR ns1.semita.sv.
3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.0.0.0.a.e.d.0.7.b.d.0.1.0.0.2.ip6.arpa. IN PTR ns2.semita.sv.
0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.0.0.0.a.e.d.0.7.b.d.0.1.0.0.2.ip6.arpa. IN PTR www.semita.sv.
0.2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.a.0.0.0.a.e.d.0.7.b.d.0.1.0.0.2.ip6.arpa. IN PTR mail.semita.sv.
```

### Permisos de archivos de zona
```bash
sudo chown root:named /var/named/db.semita.sv
sudo chown root:named /var/named/db.inversav4
sudo chown root:named /var/named/db.inversav6
sudo chmod 640 /var/named/db.semita.sv
sudo chmod 640 /var/named/db.inversav4
sudo chmod 640 /var/named/db.inversav6
```

### Iniciar y habilitar BIND
```bash
sudo systemctl start named
sudo systemctl enable named
sudo systemctl status named
```

### Configurar DNS en NetworkManager
```bash
sudo nmcli connection modify enp0s8 ipv4.dns-search "semita.sv"
sudo nmcli connection modify enp0s8 ipv6.dns-search "semita.sv"
sudo nmcli connection modify enp0s8 ipv4.dns "172.16.0.2"
sudo nmcli connection modify enp0s8 ipv6.dns "2001:DB7:DEA:A::2"
```

### Reglas de firewall para DNS
```bash
sudo firewall-cmd --zone=internal --add-rich-rule='rule family="ipv4" source address="172.16.0.0/24" service name="dns" accept' --permanent
sudo firewall-cmd --zone=internal --add-rich-rule='rule family="ipv6" source address="2001:db7:dea:a::/64" service name="dns" accept' --permanent
sudo firewall-cmd --reload
```

### Probar DNS
```bash
nslookup www.semita.sv
nslookup 2001:db7:dea:a::10
nslookup 172.16.0.10
```


