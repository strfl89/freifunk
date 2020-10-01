# to enable script do the following
# 1. copy to router (scp ...)
# 2. ssh connection to router
# 3. chmod 755 <your script>
# 4. edit /etc/rc.local and add your script
# 5. edit /etc/sysupgrade.conf and add your script
# 6. uci set autoupdater.settings.enabled='1'
# 7. uci commit autoupdater
# 8. autoupdater -f

#Create Variables
LAN="$(cat /lib/gluon/core/sysconfig/lan_ifname)" #LAN="eth0"    # LAN Interface => does not work: LAN="$(cat /lib/gluon/core/sysconfig/lan_ifname)"
CMT=false   # commit
MVL=3       # mesh vlan
CVL=4       # client vlan

#Check & Set Mesh VLAN
if [ "$(uci get network.mesh_lan.ifname)" == "$LAN.$MVL" ]; then
	logger VLAN Config: Interface for Mesh LAN set correctly.
else
	oldifmesh = "$(uci get network.mesh_lan.ifname)"
	uci set network.mesh_lan.ifname="$LAN.$MVL"
	logger VLAN Config: Changing network.mesh_lan.ifname from $oldifmesh to $LAN.$MVL!
	CMT=true
fi

# activate mesh_lan interface
if [ "$(uci get network.mesh_lan.disabled)" == 0 ]; then
	logger Mesh_Lan is enabled
else
	uci set network.mesh_lan.disabled=0
	logger Set mesh_lan Interface to enable
	CMT=true
fi

#Check & Set Client VLAN
if [ "$(uci get network.client.ifname)" == "bat0 local-port $LAN.$CVL" ]; then  
    logger VLAN Config: Interface for Client LAN set correctly.
else  
	oldifclient = "$(uci get network.client.ifname)"
	uci del network.client.ifname    
	uci add_list network.client.ifname="bat0"
	uci add_list network.client.ifname="local-port"    
	uci add_list network.client.ifname="$LAN.$CVL"    
	logger VLAN Config: Changing network.client.ifname from $oldifclient to bat0 + local-port + $LAN.$CVL...    
	CMT=true
fi

#commit only if there were changes
if [ $CMT = true ]; then    
    uci commit network
    logger VLAN Config: Config was changed and saved, reboot initiated   
    sleep 300
    reboot
else    
    logger VLAN Config: no change!
fi

#you can check your Log with logread | grep VLAN