---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-DeviceGroupAssignedtoOpRule

## SYNOPSIS

Gathers the assignments of Device Groups to OpRules

## SYNTAX

```text
Get-DeviceGroupAssignedtoOpRule [-OpRule] <OpRule[]> [-DeviceGroupOnly] [-DeviceGroupIDOnly]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

A detailed description of the Get-DeviceGroupAssignedtoOpRule function.

## EXAMPLES

### Example 1

```PowerShell
Get-DeviceGroupAssignedtoOpRule -OpRule 'OPRULE_Google_Chrome-Enterprise_R15'
```

## PARAMETERS

### -OpRule

The OpRule to use

```yaml
Type: OpRule[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DeviceGroupOnly

Use this if you want an DeviceGroup object returned instead of a OpRuleDeviceGroupAssignment object

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

### -DeviceGroupIDOnly

Use this if you want the device group IDs returned instead of a OpRuleDeviceGroupAssignment object

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRule

## OUTPUTS

### OpRuleDeviceGroupAssignment

### DeviceGroup

### System.Int32

## NOTES

## RELATED LINKS
