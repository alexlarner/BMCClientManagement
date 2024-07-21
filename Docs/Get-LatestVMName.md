---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-LatestVMName

## SYNOPSIS

Gets the highest numbered VMName matching a specified regex pattern

## SYNTAX

```text
Get-LatestVMName [-RegexPattern] <Regex> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Gathers all the devices in BMC & vSphere
Filters them down by the regex
If the latest VM names don't match between BCM & vSphere, a warning is generated and a factory alert is sent, then the highest VM name of the two is chosen

## EXAMPLES

### Example 1

```PowerShell
Get-LatestVMName -RegexPattern $FactoryVMNameRegex
```

## PARAMETERS

### -RegexPattern

The regex to filter the machine names with

```yaml
Type: Regex
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

### Regex

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS
