# PowerNSX Script to automate tasks
PowerNSX script to automate NSX vSphere configuration in DR failover and failback scenario. 

During failover, the script will automate the following tasks, 
1) Disconnect the ESG interface to DC LAN
2) Connect the ESG itnerface to DR LAN 
3) Change ESG Router ID (to use the newly connected interface) 
4) Change ESG OSPF Router Area (from DC Area ID to DR Area ID)
5) Repeat the same steps for the remaining 3 ESG 

During failover, the script will automate the following tasks, 
1) Disconnect the ESG interface to DR LAN
2) Connect the ESG itnerface to DC LAN 
3) Change ESG Router ID (to use the newly connected interface) 
4) Change ESG OSPF Router Area (from DR Area ID to DC Area ID)
5) Repeat the same steps for the remaining 3 ESG 

