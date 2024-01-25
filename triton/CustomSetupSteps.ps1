$vmalias = & "C:\smartdc\bin\mdata-get.exe" "sdc:alias"
$administrator_pw = & "C:\smartdc\bin\mdata-get.exe" "root_pw"

if (
  [string]::IsNullOrEmpty($vmalias) -or
  $vmalias.StartsWith("No metadata for") -or
  [string]::IsNullOrEmpty($administrator_pw) -or 
  $administrator_pw.StartsWith("No metadata for")
) {
  Write-Host "Failed to retrieve metadata"
  Start-Sleep -s 15

  $vmalias = & "C:\smartdc\bin\mdata-get.exe" "sdc:alias"
  $administrator_pw = & "C:\smartdc\bin\mdata-get.exe" "root_pw"
}

$securePassword = ConvertTo-SecureString -AsPlainText -Force -String $administrator_pw
$adminAccount = Get-LocalUser -Name "Administrator"
$adminAccount | Set-LocalUser -Password $securePassword

Rename-Computer -NewName $vmalias -restart
