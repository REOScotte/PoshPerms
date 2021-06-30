<#
    .SYNOPSIS
        Streamlines creation of an ACL from NTFS ACEs

    .DESCRIPTION
        NTFS Permissions are applied as an Access Control List (ACL). They are composed of one or more
        Access Control Entries (ACE). This function creates an ACL from its various parts and allows
        setting inheritance properties.

    .PARAMETER Owner
        The owner of the object being secured. This can only be set to the current user unless running as
        an Administrator or a user with the SeTakeOwnershipPrivilege right.

    .PARAMETER Group
        This can usually be ignored. Its for compatibility with Services for Unix or Mac. By default, it will
        be set to the same value as Owner

    .PARAMETER Dacl
        A collection of ACEs to allow or deny permissions

    .PARAMETER Sacl
        A collection of ACEs to define the audit rules

    .PARAMETER DisableAccessRuleInheritance
        Don't inherit access rules from the parent object

    .PARAMETER ConvertExistingAccessRules
        Convert any existing inherited access rules on the object to non-inherited

    .PARAMETER DisableAuditRuleInheritance
        Don't inherit audit rules from the parent object

    .PARAMETER ConvertExistingAuditRules
        Convert any existing inherited audit rules on the object to non-inherited

    .EXAMPLE
        Create two ACEs - one for granting Everyone Full Control to files, and a second to audit it.
        Then create an ACL using those ACEs, granting Scott as the owner and protect from inheriting rules.
        Finally, apply the new ACL to C:\Test

        $Access1 = New-NtfsAce -AccessControlType Allow -Identity Everyone -Rights FullControl -ApplyTo Files_only
        $Audit1  = New-NtfsAce -Audit -AuditFlags Success -Identity Everyone -Rights FullControl -ApplyTo Files_only

        $acl = New-NtfsAcl -Owner Scott -Dacl $Access1 -Sacl $Audit1 -DisableAccessRuleInheritance

        $acl | Set-Acl -Path C:\Test  

    .NOTES
        Author: Scott Crawford
        Created: 2021-06-29
#>
function New-NtfsAcl {
    [CmdletBinding()]
    param(
        # The double tanslation ensures a valid identity in a 'pretty' format.
        [ValidateScript( {
                try {
                    if ($script:IdentityReference = $_.Translate([System.Security.Principal.SecurityIdentifier]).Translate([System.Security.Principal.NTAccount])) { $true }
                } catch { throw 'Failure: Invalid identity reference. Specify a built-in, local, or domain identity. Valid domain account formats are: DOMAIN\Username or Username@Domain.' }
            })]
        [System.Security.Principal.NTAccount]$Owner
        ,
        # The double tanslation ensures a valid identity in a 'pretty' format.
        [ValidateScript( {
                try {
                    if ($script:IdentityReference = $_.Translate([System.Security.Principal.SecurityIdentifier]).Translate([System.Security.Principal.NTAccount])) { $true }
                } catch { throw 'Failure: Invalid identity reference. Specify a built-in, local, or domain identity. Valid domain account formats are: DOMAIN\Username or Username@Domain.' }
            })]
        [System.Security.Principal.NTAccount]$Group
        ,
        [System.Security.AccessControl.FileSystemAccessRule[]]$Dacl
        ,
        [System.Security.AccessControl.FileSystemAuditRule[]]$Sacl
        ,
        [switch]$DisableAccessRuleInheritance
        ,
        [switch]$ConvertExistingAccessRules
        ,
        [switch]$DisableAuditRuleInheritance
        ,
        [switch]$ConvertExistingAuditRules
    )

    try {
        # Create an empty ACL
        $acl = [System.Security.AccessControl.DirectorySecurity]::new()

        # Set the owner
        if ($Owner) {
            $acl.SetOwner($Owner)
        }

        # Set the primary group associated with the ACL
        if ($Group) {
            $acl.SetGroup($Group)
        } else {
            $acl.SetGroup($Owner)
        }
    
        # Add each access ACE to the DACL
        foreach ($ace in $Dacl) {
            $acl.AddAccessRule($ace)
        }

        # Add each Audit ACE to the SACL
        foreach ($ace in $Sacl) {
            $acl.AddAuditRule($ace)
        }

        # Set the flags to protect the ACL and optionally convert existing inherited ACEs
        $acl.SetAccessRuleProtection($DisableAccessRuleInheritance, $ConvertExistingAccessRules)
        $acl.SetAuditRuleProtection($DisableAuditRuleInheritance, $ConvertExistingAuditRules)
 
        Write-Output $acl
    } catch {
        throw $_
    }
}