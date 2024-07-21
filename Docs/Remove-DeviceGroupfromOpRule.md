---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Remove-DeviceGroupfromOpRule

## SYNOPSIS

Remove a device group operational rule assignment

## SYNTAX

```text
Remove-DeviceGroupfromOpRule [-Assignment] <OpRuleDeviceGroupAssignment[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Remove-DeviceGroupfromOpRule -Assignment $Assignment
```

## PARAMETERS

### -Assignment

The device group operational rule assignment to use

```yaml
Type: OpRuleDeviceGroupAssignment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### BCMAPI.Assignment.OpRuleDeviceGroupAssignment

## OUTPUTS

## NOTES

## RELATED LINKS
