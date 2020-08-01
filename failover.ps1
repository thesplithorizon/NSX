#	Powershell PowerNSX script to automate the configuration of 
#	NSX Edge during failover from Bangi to Bangsar
#	
#	
#       Connect to NSX Manager
#       Connect-NsxServer -vCenterServer  <vCenter IP/DNS>
#
#
#
#
#
#
#
#
#




#Change the ESG name accordingly 
$edges = ("esg-test-1", "esg-test-2")

#For each ESG in the list of Edges 
foreach ( $esg in $edges)
{ 

Write-Host "Working on ESG: "$esg
Write-Host "Disabling Uplink connect to VLAN 215"
Write-Host "Enabling Uplink connect to VLAN 216"

#Get the Edge and interface you want to modify
$edge = Get-NsxEdge $esg

#Input the vNIC interface Index number for uplink connect to VLAN 215
$uplink215 = $edge | Get-NsxEdgeInterface -Index 0

#Input the vNIC interface Index number for uplink connect to VLAN 216
$uplink216 = $edge | Get-NsxEdgeInterface -Index 3

#Get the edgeid child elem that powernsx adds to aid pipeline operations...
$edgeid1 = $uplink215.SelectSingleNode("child::edgeId")
$edgeid3 = $uplink216.SelectSingleNode("child::edgeId")

#...and remove it from the xml we send to the api, otherwise it will error.
[void]$uplink215.RemoveChild($edgeid1)
[void]$uplink216.RemoveChild($edgeid3)

#Connect uplink215 to VLAN 215
$uplink215.isConnected = "false"

#Disconnect uplink216 from VLAN 216
$uplink216.isConnected = "true"

#Call the API.  Using Invoke-NsxRestMethod means we dont need server name, protocol, port, content-type header or authentication header. 
#This all comes from the PowerNSX $defaultnsxconnection object created when we run Connect-NsxServer
Invoke-NsxRestMethod -method put -URI "/api/4.0/edges/$($edge.id)/vnics/$($uplink215.index)" -body $uplink215.OuterXml
Invoke-NsxRestMethod -method put -URI "/api/4.0/edges/$($edge.id)/vnics/$($uplink216.index)" -body $uplink216.OuterXml
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
$uplink216IpAddr = $uplink216.addressGroups.addressGroup.primaryAddress

#Refresh NSX Edge Routing Object 
$edge = Get-NsxEdge $esg
$edgerouting = Get-NsxEdgeRouting $edge

#Change Router ID
$edgerouting.routingGlobalConfig.routerId = $uplink216IpAddr
Set-NsxEdgeRouting -EdgeRouting $edgerouting -Confirm:$false
Write-Host "`nComplete`n"

#Enable OSPF
Write-Host "Enable OSPF"
$edge = Get-NsxEdge $esg
$edgerouting = Get-NsxEdgeRouting $edge
$edgerouting.ospf.enabled = "true"
Set-NsxEdgeRouting -EdgeRouting $edgerouting -Confirm:$false
Write-Host "`nComplete`n"

}