# create an encrypted password for the service account
$password = Read-Host -Prompt "Please enter the password" -AsSecureString
$encPass = ConvertFrom-SecureString $password
$encPass | out-file c:kirpass.txt