function Update-AdSchemaCache {
    # These are the attributes we want to build our schema collection
    $properties_ADObject = @(
        'Name'
        'subClassOf'
        'adminDisplayName'
        'lDAPDisplayName'
        'schemaIDGUID'
        'objectClass'
        'mayContain'
        'mustContain'
        'systemMayContain'
        'systemMustContain'
        'auxiliaryclass'
        'systemauxiliaryclass'
    )
    
    $configPath = (Get-ADRootDSE).configurationNamingContext
    $specifierPath = "CN=409,CN=DisplaySpecifiers,$configPath"
    $displaySpecifiers = Get-ADObject -Filter * -SearchBase $specifierPath -SearchScope OneLevel -Properties classDisplayName, attributeDisplayNames
    
    # Gets a copy of the schema
    $schemaPath = (Get-ADRootDSE).schemaNamingContext
    $script:schema = Get-ADObject -Filter "ObjectClass -ne 'subSchema'" -SearchBase $schemaPath -SearchScope OneLevel -Properties $properties_ADObject
    
    # Adds a schemaIDGUID Comparable property since this GUID comes out as an array of bytes.
    $script:schema | Add-Member -MemberType ScriptProperty -Name schemaIDGUIDComparable -Value { $this.SchemaIDGUID -as [guid] } -Force
    
    # Add a couple attributes to store DisplaySpecifiers and populate them
    $script:schema | Add-Member -MemberType NoteProperty -Name DisplayName -Value '' -Force
    $script:schema | Add-Member -MemberType NoteProperty -Name attributeDisplayNames -Value @() -Force
    
    $script:schema.Where( { $_.ObjectClass -eq 'classSchema' } ) | ForEach-Object {
        $lDAPDisplayName = $_.lDAPDisplayName
        $specifiers = $displaySpecifiers.Where( { $_.name -eq "$($lDAPDisplayName)-Display" } ) | Select-Object -Property classDisplayName, attributeDisplayNames
        $displayName = $specifiers.classDisplayName
        $attributeDisplayNames = $specifiers.attributeDisplayNames
    
        if ($displayName) {
            $_.DisplayName = $displayName[0]
        } else {
            $_.DisplayName = $_.Name
        }
    
        if ($attributeDisplayNames) {
            foreach ($attributeDisplayName in $attributeDisplayNames) {
                $parts = $attributeDisplayName.Split(',')
                $_.attributeDisplayNames += [pscustomobject]@{'Name' = $parts[0]; 'DisplayName' = $parts[1] }
            }
        }
    }
    
    # Add a couple more attributes for enumerating all the attributes a class can have
    $script:schema | Add-Member -MemberType NoteProperty -Name classList -Value @() -Force
    $script:schema | Add-Member -MemberType NoteProperty -Name attributeList -Value @() -Force
    
    # Recursive method to populate parent classes
    $script:schema | Add-Member -MemberType ScriptMethod -Name PopulateClassList -Value {
        if ($this.classlist.count -eq 0) {
            # Get the list of immediate parent classes
            $parentClasses = @($this.subclassof) + @($this.auxiliaryclass) + @($this.systemauxiliaryclass)
            # Do the recursion on each immediate parent
            foreach ($parentClass in $parentClasses) {
                $schema.where( { $_.lDAPDisplayName -eq $parentClass }, 'First' )[0].PopulateClassList()
                $this.classList += $schema.where( { $_.lDAPDisplayName -eq $parentClass }, 'First' )[0].classList
            }
            $this.classlist = @(@($this.classList) + @($this.lDAPDisplayName) | Sort-Object -Unique)
        }
    } -Force
    
    # Method to get all the classes in classList and add their attributes to this class's attributeList
    $script:schema | Add-Member -MemberType ScriptMethod -Name PopulateAttributeList -Value {
        if ($this.attributeList.Count -eq 0) {
            foreach ($class in $this.classList) {
                $attributes += ($schema.where( { $_.lDAPDisplayName -eq $class }, 'First' )[0] |
                    Select-Object @{name = 'AttributeList'; expression = { @($_.mayContain) + @($_.mustContain) + @($_.systemMayContain) + @($_.systemMustContain) } }).AttributeList
            }
        
            $attributes = @(@($attributes) | Sort-Object -Unique)
        
            $this.attributeList = $schema.where( { $_.lDAPDisplayName -in $attributes } ) | Sort-Object -Property lDAPDisplayName
        
            foreach ($fullAttribute in $this.attributeList) {
                $displayName = ($this.attributeDisplayNames.where( { $_.Name -eq $fullAttribute.lDAPDisplayName })).DisplayName
                if ($displayName) {
                    $fullAttribute.DisplayName = $displayName
                } else {
                    $fullAttribute.DisplayName = $fullAttribute.Name
                }
            }
        }
    } -Force
    
    # "Seed" the Top class so that recursion has a base case
    $script:schema.where( { $_.lDAPDisplayName -eq 'top' }, 'First')[0].classList = @('top')
}