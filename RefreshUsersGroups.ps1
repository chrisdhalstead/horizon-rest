<#
.SYNOPSIS
Refresh Horizon Users and Groups for Workspace ONE Access
	
.NOTES
  Version:        1.0
  Author:         Chris Halstead - chalstead@vmware.com
  Creation Date:  10/6/2020
  Purpose/Change: Initial script development
  **This script is NOT supported by VMware**
 
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#Log File Info
$sLogPath = $env:TEMP 
$sDomain = $env:USERDOMAIN
$sUser = $env:USERNAME
$sComputer = $env:COMPUTERNAME
$sLogName = "Horizon.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName
$sLogTitle = "Starting Script as $sdomain\$sUser from $scomputer***************"
Add-Content $sLogFile -Value $sLogTitle
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Write-Log {
    [CmdletBinding()]
    Param(
    
    [Parameter(Mandatory=$True)]
    [System.Object]
    $Message

    )
    $Stamp = (Get-Date).toString("MM/dd/yyyy HH:mm:ss")
    $Line = "$Stamp $Level $Message"
    Add-Content $sLogFile -Value $Line
   
    }

Function LogintoHorizon {

#Capture Login Information
$script:HorizonServer = Read-Host -Prompt 'Enter the Horizon Server Name'
$Username = Read-Host -Prompt 'Enter the Username'
$Password = Read-Host -Prompt 'Enter the Password' -AsSecureString
$domain = read-host -Prompt 'Enter the Horizon Domain'

#Convert Password for JSON
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$Credentials = '{"name":' + $username + ',"passwd":' + $UnsecurePassword +',"domain":' + $domain +'}' 

try {
    
    $sresult = Invoke-WebRequest -Method Post -Uri "https://$HorizonServer/view-vlsi/rest/v1/login" -Body $Credentials -ContentType "application/json" -SessionVariable session
}

catch {
  Write-Host "An error occurred when logging on $_"
  Write-Log -Message "Error when logging on to AppVolumes Manager: $_"
  Write-Log -Message "Finishing Script*************************************"
  break
}

write-host "Successfully Logged In"

$script:HorizonCSRF = $sresult.headers.CSRFToken
$script:HorizonSession = $session

} 

Function RefreshUsersGroups {
    
    if ([string]::IsNullOrEmpty($HorizonCSRF))
    {
       write-host "You are not logged into Horizon"
       break   
       
    }
 
    $headers = @{CSRFToken = $HorizonCSRF}
     
    try {
        
        $sresult = Invoke-RestMethod -Method Post -Uri "https://$horizonserver/view-vlsi/rest/v1/ADUserorGroup/RefreshUsersOrGroups" -Headers $headers -ContentType "application/json" -WebSession $HorizonSession 
    }
    
    catch {
      Write-Host "An error occurred when refreshing users and groups $_"
     break 
    }

     
write-host "Results will be logged to: "$sLogPath"\"$sLogName
write-log -Message $sresult

    
} 
 
function Show-Menu
  {
    param (
          [string]$Title = 'VMware Horizon API Menu'
          )
       Clear-Host
       Write-Host "================ $Title ================"
             
       Write-Host "Press '1' to Login to Horizon"
       Write-Host "Press '2' Refresh Users and Groups"
       Write-Host "Press 'Q' to quit."
         }

do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    
    '1' {  

         LogintoHorizon
    } 
    
    '2' {
   
        RefreshUsersGroups

    }
    
       
    }
    pause
 }
 
 until ($selection -eq 'q')


Write-Log -Message "Finishing Script******************************************************"
Write-Host "Finished"