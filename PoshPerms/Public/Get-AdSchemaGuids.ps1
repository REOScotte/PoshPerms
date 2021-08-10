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
$displaySpecifiers = Get-ADObject -Filter * -SearchBase $specifierPath -SearchScope OneLevel -Properties classDisplayName , attributeDisplayNames

# Gets a copy of the schema
$schemaPath = (Get-ADRootDSE).schemaNamingContext
$schema = Get-ADObject -Filter "ObjectClass -ne 'subSchema'" -SearchBase $schemaPath -SearchScope OneLevel -Properties $properties_ADObject

# Adds a schemaIDGUID Comparable property since this GUID comes out as an array of bytes.
$schema | Add-Member -MemberType ScriptProperty -Name schemaIDGUIDComparable -Value { $this.SchemaIDGUID -as [guid] } -Force

# Add a couple attributes to store DisplaySpecifiers and populate them
$schema | Add-Member -MemberType NoteProperty -Name DisplayName -Value '' -Force
$schema | Add-Member -MemberType NoteProperty -Name attributeDisplayNames -Value @() -Force

$schema.Where( { $_.ObjectClass -eq 'classSchema' }) | ForEach-Object {
    $lDAPDisplayName = $_.lDAPDisplayName
    $specifiers = $displaySpecifiers.Where( { $_.name -eq "$($lDAPDisplayName)-Display" }) | Select-Object -Property classDisplayName, attributeDisplayNames
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
$schema | Add-Member -MemberType NoteProperty -Name classList -Value @() -Force
$schema | Add-Member -MemberType NoteProperty -Name attributeList -Value @() -Force

# Recursive method to populate parent classes
$schema | Add-Member -MemberType ScriptMethod -Name PopulateClassList -Value {
    if ($this.classlist.count -eq 0) {
        # Get the list of immediate parent classes
        $parentClasses = @($this.subclassof) + @($this.auxiliaryclass) + @($this.systemauxiliaryclass)
        # Do the recursion on each immediate parent
        foreach ($parentClass in $parentClasses) {
            $schema.where( { $_.lDAPDisplayName -eq $parentClass }, 'First')[0].PopulateClassList()
            $this.classList += $schema.where( { $_.lDAPDisplayName -eq $parentClass }, 'First')[0].classList
        }
        $this.classlist = @(@($this.classList) + @($this.lDAPDisplayName) | Sort-Object -Unique)
    }
} -Force

# Method to get all the classes in classList and add their attributes to this class's attributeList
$schema | Add-Member -MemberType ScriptMethod -Name PopulateAttributeList -Value {
    if ($this.attributeList.Count -eq 0) {
        foreach ($class in $this.classList) {
            $attributes += ($schema.where( { $_.lDAPDisplayName -eq $class }, 'First')[0] |
                    Select-Object @{name = 'AttributeList'; expression = { @($_.mayContain) + @($_.mustContain) + @($_.systemMayContain) + @($_.systemMustContain) } }).AttributeList
            }

            $attributes = @(@($attributes) | Sort-Object -Unique)

            $this.attributeList = $schema.Where( { $_.lDAPDisplayName -in $attributes }) | Sort-Object -Property lDAPDisplayName
        
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
    $schema.where( { $_.lDAPDisplayName -eq 'top' }, 'First')[0].classList = @('top')


    function Get-AdSchemaGuids {
        param(
            [ArgumentCompleter( {
                    $wordToComplete = $args[2]
                    $schema.where( { $_.objectClass -eq 'classSchema' }).
                    where( { ($_.lDAPDisplayName -like "*$wordToComplete*") -or
                            ($_.DisplayName -like "*$wordToComplete*") }) |
                        ForEach-Object {
                            [System.Management.Automation.CompletionResult]::new($_.lDAPDisplayName, $_.ldapDisplayName, 'ParameterValue', ('Name: ' + $_.DisplayName))
                        }
            } ) ]
        [string]$Class,

        [ArgumentCompleter( {
                $wordToComplete = $args[2]
                $fakeBoundParameter = $args[4]
                $TypeFilter = $fakeBoundParameter.Class
        
                # Call the methods on the selected class to populate classes and attributes on the selected class
                $schema.where( { $_.lDAPDisplayName -eq $TypeFilter }, 'First')[0].PopulateClassList()
                $schema.where( { $_.lDAPDisplayName -eq $TypeFilter }, 'First')[0].PopulateAttributeList()
                $schema.where( { $_.lDAPDisplayName -eq $TypeFilter }, 'First')[0].AttributeList.where( { ($_.lDAPDisplayName -like "*$wordToComplete*") -or
                        $_.DisplayName -like "*$wordToComplete*" }) |
                    ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_.lDAPDisplayName, $_.ldapDisplayName, 'ParameterValue', ('Name: ' + $_.DisplayName))
                    }
            } ) ]
        [string]$Attribute
    )

    $classGUID = $schema.Where( { $_.lDAPDisplayName -eq $Class }).schemaIDGUIDComparable
    $attributeGUID = $schema.Where( { $_.lDAPDisplayName -eq $Attribute }).schemaIDGUIDComparable
    Write-Host "You picked the $attributeGUID attribute on the $classGUID class, you sly dog."
}