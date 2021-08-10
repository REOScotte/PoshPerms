$scriptBlock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if (-not $script:schema) {
        Update-AdSchemaCache
    }

    $script:schema.where( { $_.objectClass     -eq   'classSchema' } ).
                   where( { $_.lDAPDisplayName -like "*$wordToComplete*" -or
                            $_.DisplayName     -like "*$wordToComplete*" } ) |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.lDAPDisplayName,
            $_.ldapDisplayName,
            'ParameterValue',
            ('Name: ' + $_.DisplayName)
        )
    }
}
Register-ArgumentCompleter -CommandName Get-AdSchemaGuids -ParameterName Class -ScriptBlock $scriptBlock

$scriptBlock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    if (-not $script:schema) {
        Update-AdSchemaCache
    }

    $TypeFilter = $fakeBoundParameters.Class
        
    # Call the methods on the selected class to populate classes and attributes on the selected class
    $script:schema.where( {  $_.lDAPDisplayName -eq  $TypeFilter }, 'First')[0].PopulateClassList()
    $script:schema.where( {  $_.lDAPDisplayName -eq  $TypeFilter }, 'First')[0].PopulateAttributeList()

    $script:schema.where( { $_.lDAPDisplayName -eq   $TypeFilter }, 'First')[0].AttributeList.
                   where( { $_.lDAPDisplayName -like "*$wordToComplete*" -or
                            $_.DisplayName     -like "*$wordToComplete*" } ) |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.lDAPDisplayName,
            $_.ldapDisplayName,
            'ParameterValue',
            ('Name: ' + $_.DisplayName)
        )
    }
}
Register-ArgumentCompleter -CommandName Get-AdSchemaGuids -ParameterName Attribute -ScriptBlock $scriptBlock
