---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-DeviceGrouptoOpRule

## SYNOPSIS
Adds a device group to an operational rule

## SYNTAX

```
Add-DeviceGrouptoOpRule [-DeviceGroup] <DeviceGroup[]> [-OpRule] <OpRule> [-Active]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Add-DeviceGrouptoOpRule -DeviceGroup "APPGRP_$ShortCompanyName_WindowsPathEnumerate_CUR" -OpRule "OPRULE_$ShortCompanyName_WindowsPathEnumerate_R1"
```

### EXAMPLE 2
```
Add-DeviceGrouptoOpRule -DeviceGroup 'APPGRP_JTS_UnquotedPathsFix_CUR' -OpRule 'OPRULE_JTS_UnquotedPathsFix_R1' -Active
```

## PARAMETERS

### -DeviceGroup
The device group to use

```yaml
Type: DeviceGroup[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OpRule
The operational rule to use

```yaml
Type: OpRule
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Active
This adds the device group to the OpRule in an active state, elsewise the device group is assigned in a paused state.

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

### BCMAPI.Object.DeviceGroup
### BCMAPI.Object.OpRule
## OUTPUTS

## NOTES
01.20.2021 - Alex Larner - Updated to set new assignment to upload status after every execution

## RELATED LINKS
