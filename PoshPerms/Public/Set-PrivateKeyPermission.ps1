function Set-PrivateKeyPermission {
    [CmdletBinding()]
    param (
        [string]$CertStoreLocation = 'Cert:\LocalMachine\My'
        ,
        [Parameter(Mandatory)]
        [string]$Thumbprint
        ,
        [Parameter(Mandatory)]
        [ValidateSet('Read', 'FullControl')]
        [string]$Permission = 'Read'
        ,
        [Parameter(Mandatory)]
        [string]$Username
    )
        
    $certificate = Get-ChildItem $CertStoreLocation | Where-Object thumbprint -EQ $Thumbprint

    if ($certificate) {
        $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)
        $fileName = $rsaCert.key.UniqueName
        #TODO: Sometimes certs are in $env:ALLUSERSPROFILE\Microsoft\Crypto\Keys - figure out how to tell
        $path = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$fileName"
        $acl = Get-Acl -Path $path

        $ace = New-NtfsAce -AccessControlType Allow -Identity $Username -Rights $Permission -ApplyTo This_folder_only
        $acl.AddAccessRule($ace)
        Set-Acl -Path $path -AclObject $acl
    } else {
        Write-Warning "Certificate with thumbprint: $Thumbprint does not exist at $CertStoreLocation"
    }
}
