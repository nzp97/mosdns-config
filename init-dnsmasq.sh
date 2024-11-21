# Get the first IPv4 and IPv6 Address of router and store them in following variables for use during the script.
NET_ADDR=$(/sbin/ip -o -4 addr list br-lan | awk 'NR==1{ split($4, ip_addr, "/"); print ip_addr[1] }')
 
echo "Router IPv4 : ""${NET_ADDR}"
 
# 1. Enable dnsmasq to do PTR requests.
# 2. Reduce dnsmasq cache size as it will only provide PTR/rDNS info.
# 3. Disable rebind protection. Filtered DNS service responses from blocked domains are 0.0.0.0 which causes dnsmasq to fill the system log with possible DNS-rebind attack detected messages.
# 4. Move dnsmasq to port 54.
# 5. Set Ipv4 DNS advertised by option 6 DHCP 
# 6. Set Ipv6 DNS advertised by DHCP
uci set dhcp.@dnsmasq[0].noresolv="0"
uci set dhcp.@dnsmasq[0].cachesize="1000"
uci set dhcp.@dnsmasq[0].rebind_protection='0'
uci set dhcp.@dnsmasq[0].port="54"
# uci -q delete dhcp.@dnsmasq[0].server
# uci add_list dhcp.@dnsmasq[0].server="${NET_ADDR}"
 
#Delete existing config ready to install new options.
uci -q delete dhcp.lan.dhcp_option
uci -q delete dhcp.lan.dns
 
# DHCP option 6: which DNS (Domain Name Server) to include in the IP configuration for name resolution
uci add_list dhcp.lan.dhcp_option='6,'"${NET_ADDR}" 
 
#DHCP option 3: default router or last resort gateway for this interface
uci add_list dhcp.lan.dhcp_option='3,'"${NET_ADDR}"

# uci commit dhcp
# /etc/init.d/dnsmasq restart

# forward from dnsmasq
uci set dhcp.@dnsmasq[0].logfacility='/val/log/dnsmasq.log'
uci set dhcp.@dnsmasq[0].noresolv='1'
uci -q delete dhcp.@dnsmasq[0].resolvfile
uci commit dhcp
/etc/init.d/dnsmasq restart