function Get-AdSchemaGuids {
    param(
        [string]$Class
        ,
        [string]$Attribute
    )

    $classGUID = $script:schema.Where( { $_.lDAPDisplayName -eq $Class }).schemaIDGUIDComparable
    $attributeGUID = $script:schema.Where( { $_.lDAPDisplayName -eq $Attribute }).schemaIDGUIDComparable
    Write-Host "You picked the $attributeGUID attribute on the $classGUID class, you sly dog."
}