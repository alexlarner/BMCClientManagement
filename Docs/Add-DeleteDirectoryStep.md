---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-DeleteDirectoryStep

## SYNOPSIS

Adds a delete directory step to an OpRule

## SYNTAX

```text
Add-DeleteDirectoryStep [-OpRule] <OpRule> [-TargetPath] <String> [[-DeleteReadOnly] <Boolean>]
 [[-DeleteDirectoryContentOnly] <Boolean>] [[-OnFail] <String>] [[-OnSuccess] <String>] [[-Notes] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET'
```

### Example 2

```PowerShell
Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -DeleteReadOnly $false
```

### Example 3

```PowerShell
Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -DeleteDirectoryContentOnly $true
```

### Example 4

```PowerShell
Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -OnFail 'Continue'
```

### Example 5

```PowerShell
Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -OnSuccess 'Fail'
```

### Example 6

```PowerShell
Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -Notes 'This step made by the API'
```

## PARAMETERS

### -OpRule

The OpRule to add the step to

```yaml
Type: OpRule
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetPath

The path of the directory of files to delete

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeleteReadOnly

Deletes the read only files as well

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeleteDirectoryContentOnly

Deletes just the content of the given directory

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnFail

What to do if the step fails

Allowable values are:

- Continue
- Fail
- Succeed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Fail
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnSuccess

What to do if the step succeeds

Allowable values are:

- Continue
- Fail
- Succeed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRule

### Bool

### String

## OUTPUTS

## NOTES

## RELATED LINKS
