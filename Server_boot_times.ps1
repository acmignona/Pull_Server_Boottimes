###################################################
# This Script pulls servers from a referenced     #
# .csv file. It will attempt to pull the data     #
# through the most efficient methods first,       #
# but if one method fails, it will continue down  #
# a series of methods until it's successful.      #
# Eventually, it will even resort to cmd prompt.  # 
# See $export_location variable below for the     #
# export path.                                    #
#                   -Anthony Mignona, 02/07/2022  # 
###################################################

$referencefile = "c:\users\JSmith\list_of_servers.csv" # Save list of servers into csv, update the variable to reflect that file path.
$export_location = "c:\users\JSmith\server_bootimes.csv"
$Array = @()
$servers = get-content $referencefile
$boottime = ""
$method = ""


foreach ($server in $servers){
    $ErrorActionPreference = 'stop'
    # Get-CimInstance Attempt (doesn't use Powershell to communicate, it uses WMI)
    try{
        Get-CimInstance -ComputerName $server -ClassName Win32_OperatingSystem -ErrorAction Stop
        $boottime = (Get-CimInstance -ComputerName $server -ClassName Win32_OperatingSystem).LastBootUpTime
        $boottime = [datetime] $boottime
        $status = "success"
        $method = "Get-CimInstance"
        } catch {
            write-warning "Error conneting to $server with PS: Get-CimInstance" 
            $boottime = "Didn't return"
            $status = "fail"
        }
    # PowerShell Get-ComputerInfo Attempt
    if($status -eq "fail"){
        try{
            $boottime = invoke-command -ComputerName $server -ScriptBlock {Get-ComputerInfo -Property OsLastBootUpTime} -ErrorAction Stop
            $boottime = "success" 
            $status = "success"
            $method = "Invoke"        
        } catch{
            write-warning "Error conneting to $server with PS: Get-ComputerInfo" 
            $boottime = "Didn't return"
            $status = "fail"
        }
    }
    # CMD Prompt Attempt
    if($status -eq "fail"){
        try{
            $boottime = invoke-command -ComputerName $server -ScriptBlock {systeminfo | find "System Boot Time:"} # this returns a string that represents the datetime of reboot
            $boottime = $boottime.replace('OS Name: ', '') # Remove the leading text
            $boottime = $boottime.replace('  ','') # Remove leading spaces 
            $boottime = $boottime.replace('Microsoft ','') # Removes Microsoft for data standardization 
            $method = "CMD: Systeminfo"
            write-host $method
            $boottime = "success" 
            $status = "success"      
        } catch{
            write-warning "Error using CMD on $server" 
            $boottime = "Didn't return. Likely server is offline or non-existent. Consider removing it from the reference file located here: $referencefile"
            $status = "fail"
            $method = "NOT FOUND" 
        }

    }
    # Calculate Validation Status
    if ($boottime.Date -ge (Get-Date).Date.AddDays(-1)){$validation_status = "READY" } Else{ $validation_status = "NOT READY"}
    
    # Output each iteration of the loop into an array
    $Row = "" | Select ServerName, Boottime, ValidationStatus
    $Row.ServerName = $Server
    $Row.Boottime = $boottime
    $Row.ValidationStatus = $validation_status
    $Array += $Row
}

$Array | Select-Object -Property ServerName, Boottime, ValidationStatus  | Export-Csv -Path $export_location -Force -NoTypeInformation
$date = Get-Date -format "yyyy-MM-dd HH:mm"
$timestamp = "This csv file was last updated on "+$date+"." 
Add-Content $export_location -Value $timestamp
$final_message = "NOTE: AFTER CHECKING THIS FILE BE SURE TO CLOSE IT OUT! THE SPREADSHEET WILL NOT UPDATE IF YOU LEAVE THIS FILE OPEN!"
Add-Content $export_location -Value $final_message