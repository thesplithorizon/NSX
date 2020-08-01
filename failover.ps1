#	    Powershell PowerNSX script to automate the configuration of 
#	    NSX Edge during failover from Bangi to Bangsar
#	    
#	     
#.    To install PowerNSX,follow the instruction below,
#.    https://github.com/vmware/powernsx
#.     
#.    Before running the script, you need to connect to NSX Manager
#.    
#.    Also you need to verify the following variable accordingly, 
#.    ESG name in $edge 
#.    Index number in $coreUplink, $transitInternal and  $coreUplinkDr
#
#     To connect to NSX Manager, use the following cmdlet
#     Connect-NsxServer -vCenterServer  <vCenter IP/DNS>
#
#.    
#
#
#
#


#Replace the ESG name accordingly 
$edges = ("esg-test-1", "esg-test-2")

#For each ESG in the list of Edges 
foreach ( $esg in $edges)
{ 

Write-Host "Working on ESG: "$esg
Write-Host "Disabling Uplink connect to VLAN 215"
Write-Host "Enabling Uplink connect to VLAN 216"

#Get the Edge and interface you want to modify
$edge = Get-NsxEdge $esg

#Replace the ESG vNIC interface Index number accordingly
$coreUplink = $edge | Get-NsxEdgeInterface -Index 0
$transitInternal = $edge | Get-NsxEdgeInterface -Index 1
$coreUplinkDr = $edge | Get-NsxEdgeInterface -Index 2

#Get the edgeid child elem that powernsx adds to aid pipeline operations...
$edgeid1 = $coreUplink.SelectSingleNode("child::edgeId")
$edgeid2 = $coreUplinkDr.SelectSingleNode("child::edgeId")

#...and remove it from the xml we send to the api, otherwise it will error.
[void]$coreUplink.RemoveChild($edgeid1)
[void]$coreUplinkDr.RemoveChild($edgeid2)

#Disconnect Core-Uplink from VLAN 216
$coreUplink.isConnected = "false"

#Connect Core-Uplink-Dr to VLAN 215
$coreUplinkDr.isConnected = "true"

#Call the API.  Using Invoke-NsxRestMethod means we dont need server name, protocol, port, content-type header or authentication header. 
#This all comes from the PowerNSX $defaultnsxconnection object created when we run Connect-NsxServer
Invoke-NsxRestMethod -method put -URI "/api/4.0/edges/$($edge.id)/vnics/$($coreUplink.index)" -body $coreUplink.OuterXml
Invoke-NsxRestMethod -method put -URI "/api/4.0/edges/$($edge.id)/vnics/$($coreUplinkDr.index)" -body $coreUplinkDr.OuterXml
Write-Host "`nCompleted`n"


#Disable OSPF
Write-Host "Disable OSPF"
$edge = Get-NsxEdge $esg
$edgerouting = Get-NsxEdgeRouting $edge
$edgerouting.ospf.enabled = "false"
Set-NsxEdgeRouting -EdgeRouting $edgerouting -Confirm:$false
Write-Host "`nComplete`n"

#Change ESG Router ID"
Write-Host "Changing Router ID"

#Collect the Primary IP address of uplink216
$coreUplinkDrIpAddr = $coreUplinkDr.addressGroups.addressGroup.primaryAddress

#Refresh NSX Edge Routing Object 
$edge = Get-NsxEdge $esg
$edgerouting = Get-NsxEdgeRouting $edge

#Change Router ID
$edgerouting.routingGlobalConfig.routerId = $coreUplinkDrIpAddr
Set-NsxEdgeRouting -EdgeRouting $edgerouting -Confirm:$false
Write-Host "`nComplete`n"

#Enable OSPF Back
Write-Host "Enable OSPF"
$edge = Get-NsxEdge $esg
$edgerouting = Get-NsxEdgeRouting $edge
$edgerouting.ospf.enabled = "true"
Set-NsxEdgeRouting -EdgeRouting $edgerouting -Confirm:$false
Write-Host "`nComplete`n"

}
