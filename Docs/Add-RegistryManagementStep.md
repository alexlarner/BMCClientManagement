---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-RegistryManagementStep

## SYNOPSIS

Adds a registry management step

PARAMETER OpRule
The OpRule to add the step to

## SYNTAX

```text
Add-RegistryManagementStep -OpRule <OpRule> -Key <String> [-Operation <String>] [-ValueName <String>]
 [-Value <String>] [-ValueType <String>] [-BinaryValueInHexFormat] [-OnFail <String>] [-OnSuccess <String>]
 [-Notes <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test'
```

### Example 2

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -Operation Delete
```

### Example 3

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -OnFail Continue
```

### Example 4

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -OnSuccess Fail
```

### Example 5

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -Notes 'This step made by the API'
```

### Example 6

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'DisplayName'
```

### Example 7

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'UninstallString' -Value 'cmd.exe /c'
```

### Example 8

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'UninstallString' -Value '12345' -ValueType 'DWORD'
```

### Example 9

```PowerShell
Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'UninstallString' -Value '0' -ValueType 'Binary' -BinaryValueInHexFormat
```

## PARAMETERS

### -OpRule

{{ Fill OpRule Description }}

```yaml
Type: OpRule
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key

The full registry key path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Operation

The registry key operation to do
Allowable values are: 'Add/Modify', 'Delete'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Add/Modify
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValueName

The value name for the registry key property
If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Open this step and delete this text
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value

The value for the registry key property
If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Open this step and delete this text
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValueType

The type of the registry key value.
Allowable values are: 'String', 'Binary', 'DWORD', 'ExpandableString', 'Multi-String', 'QWORD'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: String
Accept pipeline input: False
Accept wildcard characters: False
```

### -BinaryValueInHexFormat

Formats the binary value in hex notation

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnFail

What to do if the step fails
Allowable values are: 'Continue', 'Fail', 'Succeed'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Fail
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnSuccess

What to do if the step succeeds
Allowable values are: 'Continue', 'Fail', 'Succeed'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Continue
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes

The notes to add to the step

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction

{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRule

### String

## OUTPUTS

### StepAssignment

## NOTES

## RELATED LINKS
