function Get-MetadataValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [int]$MaxAttempts = 5,
        [int]$RetryDelaySeconds = 2
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $value = [string](& "C:\smartdc\bin\mdata-get.exe" $Key)
        $metadataExitCode = $LASTEXITCODE
        $value = $value.Trim()
        $missing = [string]::IsNullOrWhiteSpace($value) -or
            $value.StartsWith(
                "No metadata for",
                [System.StringComparison]::OrdinalIgnoreCase
            )

        if ($metadataExitCode -eq 0 -and -not $missing) {
            Write-Host "Retrieved metadata key '$Key' on attempt $attempt."
            return $value
        }

        if ($metadataExitCode -ne 0) {
            Write-Host "Metadata key '$Key' lookup failed on attempt $attempt of $MaxAttempts (exit code $metadataExitCode)."
        } else {
            Write-Host "Metadata key '$Key' was unavailable on attempt $attempt of $MaxAttempts."
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    Write-Host "Giving up on metadata key '$Key' after $MaxAttempts attempts."
    return $null
}

Write-Host "Starting Triton per-instance setup."

$vmAlias = Get-MetadataValue -Key "sdc:alias"
$administratorPassword = Get-MetadataValue -Key "administrator_pw"
if ($null -eq $administratorPassword) {
    # Older Windows manifests may have generated root_pw instead.
    Write-Host "Falling back from 'administrator_pw' to compatibility key 'root_pw'."
    $administratorPassword = Get-MetadataValue -Key "root_pw"
}

$changed = $false
$exitCode = 0

if ($null -eq $administratorPassword) {
    Write-Host "ERROR: Neither 'administrator_pw' nor 'root_pw' was available. The Administrator account was not changed; the baked-in password remains in place."
    $exitCode = 1
} else {
    try {
        $securePassword = ConvertTo-SecureString -AsPlainText -Force -String $administratorPassword
        $adminAccount = Get-LocalUser -Name "Administrator" -ErrorAction Stop
        $adminAccount | Set-LocalUser -Password $securePassword -ErrorAction Stop
        $changed = $true
        Write-Host "Updated the Administrator password from Triton metadata."
    } catch {
        Write-Host "ERROR: Failed to update the Administrator password: $($_.Exception.Message)"
        $exitCode = 1
    }
}

if ($null -eq $vmAlias) {
    Write-Host "Metadata key 'sdc:alias' was unavailable. The computer name was left unchanged."
} elseif ($vmAlias -ieq $env:COMPUTERNAME) {
    Write-Host "Computer name already matches metadata alias '$vmAlias'; no rename is needed."
} else {
    try {
        Rename-Computer -NewName $vmAlias -Force -ErrorAction Stop
        $changed = $true
        Write-Host "Changed the computer name from '$env:COMPUTERNAME' to '$vmAlias'."
    } catch {
        Write-Host "ERROR: Failed to rename the computer to '$vmAlias': $($_.Exception.Message)"
        $exitCode = 1
    }
}

if ($changed) {
    Write-Host "Provisioning changed the instance; scheduling a reboot in 5 seconds."
    & shutdown.exe /r /t 5 /c "Triton per-instance setup applied changes."
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to schedule the reboot (exit code $LASTEXITCODE)."
        $exitCode = 1
    }
} else {
    Write-Host "Provisioning made no changes; no reboot will be scheduled."
}

Write-Host "Triton per-instance setup finished with exit code $exitCode."
exit $exitCode
