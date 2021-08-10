[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
    [System.Security.Principal.NTAccount]'Everyone',
    [System.DirectoryServices.ActiveDirectoryRights]::Delete,
    [System.Security.AccessControl.AccessControlType]::Allow,
    [Guid]'e9a0153a-a980-11d2-a9ff-00c04f8eedd8',
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All,
    [Guid]'bf967919-0de6-11d0-a285-00aa003049e2'
)

[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
    [System.Security.Principal.NTAccount]'Everyone',
    [System.DirectoryServices.ActiveDirectoryRights]::Delete,
    [System.Security.AccessControl.AccessControlType]::Allow,
    [Guid]'e9a0153a-a980-11d2-a9ff-00c04f8eedd8',
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Children,
    [Guid]'bf967919-0de6-11d0-a285-00aa003049e2'
)

[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
    [System.Security.Principal.NTAccount]'Everyone',
    [System.DirectoryServices.ActiveDirectoryRights]::Delete,
    [System.Security.AccessControl.AccessControlType]::Allow,
    [Guid]'e9a0153a-a980-11d2-a9ff-00c04f8eedd8',
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents,
    [Guid]'bf967919-0de6-11d0-a285-00aa003049e2'
)

[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
    [System.Security.Principal.NTAccount]'Everyone',
    [System.DirectoryServices.ActiveDirectoryRights]::Delete,
    [System.Security.AccessControl.AccessControlType]::Allow,
    [Guid]'e9a0153a-a980-11d2-a9ff-00c04f8eedd8',
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::None,
    [Guid]'bf967919-0de6-11d0-a285-00aa003049e2'
)

[System.DirectoryServices.ActiveDirectoryAccessRule]::new(
    [System.Security.Principal.NTAccount]'Everyone',
    [System.DirectoryServices.ActiveDirectoryRights]::Delete,
    [System.Security.AccessControl.AccessControlType]::Allow,
    [Guid]'e9a0153a-a980-11d2-a9ff-00c04f8eedd8',
    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::SelfAndChildren,
    [Guid]'bf967919-0de6-11d0-a285-00aa003049e2'
)
