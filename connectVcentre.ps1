# Set environment variables from .env file
# Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false.
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

# Check if variables are correctly set
if (-not $vUser) { throw "Environment variable 'vUser' not found or is empty." }
if (-not $ppath) { throw "Environment variable 'ppath' not found or is empty." }
if (-not $vCenter) { throw "Environment variable 'vCenter' not found or is empty." }

# Get password and create credentials
$vPass = Get-Content $ppath | ConvertTo-SecureString
$creds = New-Object System.Management.Automation.PSCredential($vUser, $vPass)

# Connect to vCenter server
Connect-VIServer -Server $vCenter -Credential $creds

# disconnect from vcentre
Disconnect-VIServer $vCenter -Confirm:$false