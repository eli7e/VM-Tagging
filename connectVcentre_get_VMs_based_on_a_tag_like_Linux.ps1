# Set environment variables from .env file
Get-Content .env | ForEach-Object {
    # Split by '=' and ensure correct parsing
    $name, $value = $_.split('=')
    $name = $name.Trim()
    $value = $value.Trim()
    
    # Skip comments and empty lines
    if ([string]::IsNullOrWhiteSpace($name) -or $name.StartsWith('#')) {
        continue
    }
    
    # Set the environment variable
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
    Write-Host ("{0} is {1}" -f $name, $value)
}

# Define variables from environment
$vUser = $env:vUser
$vUservc = $env:vUservc
$ppath = $env:ppath
$vCenter = $env:vCenter
$uidPattern = "*/VIServer=${vUservc}@${vCenter}:*"
$tagNamePattern = "*Linux**"
$csvPath = "J:\scripts_imported_from_dceu1jbox2k19\scripts\kernel-panic\owners.csv"
$vmList = "J:\scripts_imported_from_dceu1jbox2k19\scripts\kernel-panic\linuxList.txt"

# Check if variables are correctly set
if (-not $vUser) { throw "Environment variable 'vUser' not found or is empty." }
if (-not $ppath) { throw "Environment variable 'ppath' not found or is empty." }
if (-not $vCenter) { throw "Environment variable 'vCenter' not found or is empty." }

# Get password and create credentials
$vPass = Get-Content $ppath | ConvertTo-SecureString
$creds = New-Object System.Management.Automation.PSCredential($vUser, $vPass)

# Connect to vCenter server
Connect-VIServer -Server $vCenter -Credential $creds

# read the owner's VM list
$vms = Get-Content $vmList | foreach {Get-VM $_}

# tag the VMs by the owner
######## Add TAGS:
Get-VM | Where-Object {
    $_.PowerState -notlike 'PoweredOff' -and 
    (Get-TagAssignment -Entity $_ -Category "Operating System" | Where-Object { $_.Tag.Name -like "*Linux**" })
} | Select-Object Name, 
    @{Name="Location";Expression={ 
        $locationTag = (Get-TagAssignment -Entity $_ -Category "location").Tag.Name
        if ($locationTag) { $locationTag } else { "Not Assigned" }
    }}, 
    @{Name="Owner";Expression={ 
        $ownerTag = (Get-TagAssignment -Entity $_ -Category "owner").Tag.Name
        if ($ownerTag) { $ownerTag } else { "Not Assigned" }
    }}

# disconnect from vcentre
Disconnect-VIServer $vCenter -Confirm:$false