---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-DevicetoOpRule

## SYNOPSIS
Add a device to an OpRule

## SYNTAX

```
Add-DevicetoOpRule [-Device] <Device[]> [-OpRule] <OpRule> [-Active] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Add-DevicetoOpRule -Device 'VDPKG0010' -OpRule 'OPRULE_JET_JETTools_R1'
```

### EXAMPLE 2
```
Add-DevicetoOpRule -Device 'VDPKG0011' -OpRule 'OPRULE_JTS_CStools_R4' -Active
```

## PARAMETERS

### -Device
The device to use

```yaml
Type: Device[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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
This adds the device to the OpRule in an active state, elsewise the device is assigned in a paused state.
If this is chosen and the device is already assigned to the OpRule, the OpRule will be reassigned to the device

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

## OUTPUTS

## NOTES

## RELATED LINKS
