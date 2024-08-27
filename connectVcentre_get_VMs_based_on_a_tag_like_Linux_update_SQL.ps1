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
$csvPath = $env:csvPath
$vmList = $env:vmList
$csvDelimiter = $env:csvDelimiter
$serverName = $env:serverName
$databaseName = $env:databaseName
$tableSchema = $env:tableSchema
$tableName = $env:tableName

# Check if variables are correctly set
if (-not $vUser) { throw "Environment variable 'vUser' not found or is empty." }
if (-not $ppath) { throw "Environment variable 'ppath' not found or is empty." }
if (-not $vCenter) { throw "Environment variable 'vCenter' not found or is empty." }

# Get password and create credentials
$vPass = Get-Content $ppath | ConvertTo-SecureString
$creds = New-Object System.Management.Automation.PSCredential($vUser, $vPass)

# Connect to vCenter server
Connect-VIServer -Server $vCenter -Credential $creds

# get the user and location tags for all the powered on VMs
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
    }} | Export-CSV $csvPath -NoTypeInformation

Start-Sleep -s 10

## Truncate Table for the 1st write only
Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query "TRUNCATE TABLE $tableSchema.$tableName" -TrustServerCertificate

## Import CSV into SQL
$Bamboo = Import-Csv -Path $csvPath -Delimiter $csvDelimiter
Write-SqlTableData -InputData $Bamboo -ServerInstance $serverName -DatabaseName $databaseName -SchemaName $tableSchema -TableName $tableName
# disconnect from vcentre
Disconnect-VIServer $vCenter -Confirm:$false