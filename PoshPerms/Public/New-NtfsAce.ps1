<#
    .SYNOPSIS
        Streamlines creation of an ACE for NTFS ACLs

    .DESCRIPTION
        NTFS Permissions are applied as an Access Control List (ACL). They are composed of one or more
        Access Control Entries (ACE). This function creates a single ACE for use in an ACL.

        One of the challenges is the Explorer GUI doesn't translate easily. This function translates the
        language of the GUI in to the appropriate Inherit and Propagation flags.

        This function also presents the System.Security.AccessControl.FileSystemRights enumeration to allow
        granular permissions to be selected.

    .PARAMETER AccessControlType
        Specifies whether to create an Allow or Deny ACE

    .PARAMETER Identity
        The user or group the ACE applies to

    .PARAMETER Rights
        A comma delimited list of rights to include in the ACE.

        The listed number is the integer representation of each right.
        These can be combinined with a binary OR to create a single int value comprising multiple rights.
        Pre-defined combinations are denoted with an asterisk.

        AppendData                         4 Specifies the right to append data to the end of a file.

        ChangePermissions             262144 Specifies the right to change the security and audit rules associated with a file or folder.

        CreateDirectories                  4 Specifies the right to create a folder.

        CreateFiles                        2 Specifies the right to create a file.

        Delete                         65536 Specifies the right to delete a folder or file.

        DeleteSubdirectoriesAndFiles      64 Specifies the right to delete a folder and any files contained within that folder.

        ExecuteFile                       32 Specifies the right to run an application file.

        FullControl                  2032127 Specifies the right to exert full control over a folder or file, and to modify access control and audit rules.
        *                                    This value represents the right to do anything with a file and is the combination of all rights in this enumeration.

        ListDirectory                      1 Specifies the right to read the contents of a directory.

        Modify                        197055 Specifies the right to read, write, list folder contents, delete folders and files, and run application files.
        *                                    This right includes the ReadAndExecute right, the Write right, and the Delete right.

        Read                          131209 Specifies the right to open and copy folders or files as read-only.
        *                                    This right includes the ReadData right, ReadExtendedAttributes right, ReadAttributes right, and ReadPermissions right.

        ReadAndExecute                131241 Specifies the right to open and copy folders or files as read-only, and to run application files.
        *                                    This right includes the Read right and the ExecuteFile right.

        ReadAttributes                   128 Specifies the right to open and copy file system attributes from a folder or file.
                                             For example, this value specifies the right to view the file creation or modified date.
                                             This does not include the right to read data, extended file system attributes, or access and audit rules.

        ReadData                           1 Specifies the right to open and copy a file or folder.
                                             This does not include the right to read file system attributes, extended file system attributes, or access and audit rules.

        ReadExtendedAttributes             8 Specifies the right to open and copy extended file system attributes from a folder or file.
                                             For example, this value specifies the right to view author and content information.
                                             This does not include the right to read data, file system attributes, or access and audit rules.

        ReadPermissions               131072 Specifies the right to open and copy access and audit rules from a folder or file.
                                             This does not include the right to read data, file system attributes, and extended file system attributes.

        Synchronize                  1048576 Specifies whether the application can wait for a file handle to synchronize with the completion of an I/O operation.

        TakeOwnership                 524288 Specifies the right to change the owner of a folder or file.
                                             Note that owners of a resource have full access to that resource.

        Traverse                          32 Specifies the right to list the contents of a folder and to run applications contained within that folder.

        Write                            278 Specifies the right to create folders and files, and to add or remove data from files.
        *                                    This right includes the WriteData right, AppendData right, WriteExtendedAttributes right, and WriteAttributes right.

        WriteAttributes                  256 Specifies the right to open and write file system attributes to a folder or file.
                                             This does not include the ability to write data, extended attributes, or access and audit rules.

        WriteData                          2 Specifies the right to open and write to a file or folder.
                                             This does not include the right to open and write file system attributes, extended file system attributes, or access and audit rules.

        WriteExtendedAttributes           16 Specifies the right to open and write extended file system attributes to a folder or file.
                                             This does not include the ability to write data, attributes, or access and audit rules.

        Source:
        https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights

        # This script lists the enumeration and integer values.
        $FilePermNames = [System.Enum]::GetNames([System.Security.AccessControl.FileSystemRights]) | Sort-Object
        foreach ($FilePermName in $FilePermNames) {
            $FilePermNum = ([int]([System.Security.AccessControl.FileSystemRights])::$FilePermName)
            $FilePermName + '    ' + $FilePermNum
        }

    .PARAMETER ApplyTo
        Presents the options available in the GUI Applies to field.

        Available options are:
        Files_only
        This_folder_only          This_folder_and_subfolders
        Subfolders_only           Subfolders_and_files_only
        This_folder_and_files     This_folder_subfolders_and_files

    .PARAMETER ThisContainerOnly
        Equates to checking the GUI box labled:
        'Only apply these permissions to objects and/or containers within this container'

        Note: This has no effect when applying to This_folder_only

    .EXAMPLE
        Create an Allow ACE for Everyone to Read Data and Write Extended Attributes on one level of subfolders

        New-NtfsAce -AccessControlType Allow -Identity Everyone -Rights ReadData, WriteExtendedAttributes -ApplyTo Subfolders_only -ThisContainerOnly 1

    .NOTES
        Author: Scott Crawford
        Reviewer: Rich Kusak
        Created: 2017-10-22

    TODO: Add support for GENERIC access rights
    https://docs.microsoft.com/en-us/windows/win32/secauthz/access-mask-format
    https://docs.microsoft.com/en-us/windows/win32/fileio/file-security-and-access-rights?redirectedfrom=MSDN
#>

function New-NtfsAce {

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Security.AccessControl.AccessControlType]$AccessControlType = 'Allow',

        # The double tanslation ensures a valid identity in a 'pretty' format.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                try {
                    if ($script:IdentityReference = $_.Translate([System.Security.Principal.SecurityIdentifier]).Translate([System.Security.Principal.NTAccount])) {$true}
                } catch {throw 'Failure: Invalid identity reference. Specify a built-in, local, or domain identity. Valid domain account formats are: DOMAIN\Username or Username@Domain.'}
            })]
        [System.Security.Principal.NTAccount]$Identity,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Security.AccessControl.FileSystemRights[]]$Rights,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet(
            'This_folder_only',
            'This_folder_and_subfolders',
            'Subfolders_only',
            'This_folder_and_files',
            'Files_only',
            'This_folder_subfolders_and_files',
            'Subfolders_and_files_only')]
        [string]$ApplyTo = 'This_folder_subfolders_and_files',

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet(0, 1)]
        [int]$ThisContainerOnly = 0
    )

    begin {
        New-Variable -Name const_Inherit_None                 -Option Constant -Value ([int]0)
        New-Variable -Name const_Inherit_ContainerInherit     -Option Constant -Value ([int]1)
        New-Variable -Name const_Inherit_ObjectInherit        -Option Constant -Value ([int]2)
        New-Variable -Name const_Propagate_None               -Option Constant -Value ([int]0)
        New-Variable -Name const_Propagate_NoPropagateInherit -Option Constant -Value ([int]1)
        New-Variable -Name const_Propagate_InheritOnly        -Option Constant -Value ([int]2)
    }

    process {
        try {
            [int]$InheritanceFlags = 0
            [int]$PropagationFlags = 0
            [int]$FileSystemRights = 0

            # Combine each right that's specified by taking the binary OR of all values.
            $Rights.ForEach( {$FileSystemRights = $FileSystemRights -bor [int]$_} )

            # Convert the ApplyTo variable to the appropriate inheritance and propagation flags.
            switch ($ApplyTo) {
                'This_folder_only'                 {$InheritanceFlags = $const_Inherit_None                                              ; $PropagationFlags = $const_Propagate_None       ; break}
                'This_folder_and_subfolders'       {$InheritanceFlags = $const_Inherit_ContainerInherit                                  ; $PropagationFlags = $const_Propagate_None       ; break}
                'Subfolders_only'                  {$InheritanceFlags = $const_Inherit_ContainerInherit                                  ; $PropagationFlags = $const_Propagate_InheritOnly; break}
                'This_folder_and_files'            {$InheritanceFlags =                                      $const_Inherit_ObjectInherit; $PropagationFlags = $const_Propagate_None       ; break}
                'Files_only'                       {$InheritanceFlags =                                      $const_Inherit_ObjectInherit; $PropagationFlags = $const_Propagate_InheritOnly; break}
                'This_folder_subfolders_and_files' {$InheritanceFlags = $const_Inherit_ContainerInherit -bor $const_Inherit_ObjectInherit; $PropagationFlags = $const_Propagate_None       ; break}
                'Subfolders_and_files_only'        {$InheritanceFlags = $const_Inherit_ContainerInherit -bor $const_Inherit_ObjectInherit; $PropagationFlags = $const_Propagate_InheritOnly; break}
            }

            # When ThisContainerOnly is specifed, the propagation flags need to include NoPropagateInherit
            if ($ThisContainerOnly) {$PropagationFlags = $PropagationFlags -bor $const_Propagate_NoPropagateInherit}

            # Create a new ace
            $ace = [System.Security.AccessControl.FileSystemAccessRule]::new(
                [System.Security.Principal.IdentityReference    ]$IdentityReference,
                [System.Security.AccessControl.FileSystemRights ]$FileSystemRights,
                [System.Security.AccessControl.InheritanceFlags ]$InheritanceFlags,
                [System.Security.AccessControl.PropagationFlags ]$PropagationFlags,
                [System.Security.AccessControl.AccessControlType]$AccessControlType
            )

            Write-Output $ace

        } catch {
            Write-Error -ErrorRecord $Error[0]
        }
    }
}
