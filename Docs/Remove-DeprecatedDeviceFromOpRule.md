---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Remove-DeprecatedDeviceFromOpRule

## SYNOPSIS
Removes ALL deprecated devices from ALL OpRules

## SYNTAX

```
Remove-DeprecatedDeviceFromOpRule [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gathers all the devices in the 'All Deprecated Devices' compliance group
Gathers all the OpRule assignments from ALL OpRules (This will take a long time)
Filters down the assignments to those just for the deprecated devices, and removes them

## EXAMPLES

### EXAMPLE 1
```
Remove-DeprecatedDeviceFromOpRule
```

## PARAMETERS

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

## OUTPUTS

## NOTES

## RELATED LINKS
