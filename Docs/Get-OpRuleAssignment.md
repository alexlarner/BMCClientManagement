---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-OpRuleAssignment

## SYNOPSIS

Get assignments of devices to Operational Rules

## SYNTAX

### Normal (Default)

```text
Get-OpRuleAssignment [-OpRule] <OpRule[]> [[-Device] <Device[]>] [-Status <String>]
 [-DeviceGroup <DeviceGroup>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Raw

```text
Get-OpRuleAssignment [-OpRule] <OpRule[]> [[-Device] <Device[]>] [-RawData]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Get-OpRuleAssignment -OpRule 'OPRULE_CrowdStrike_CrowdStrikeWindowsSensor_R14'
```

### Example 2

```PowerShell
Get-OpRuleAssignment -OpRule 'OPRULE_Symantec_SEP_R12' -Device 'VDPKG0011'
```

### Example 3

```PowerShell
Get-OpRuleAssignment -OpRule 'OPRULE_Symantec_SEP_R12' -Device 'VDPKG0011' -RawData
```

### Example 4

```PowerShell
Get-OpRuleAssignment -OpRule 'OPRULE_LastPass_LastPass_R6' -Status 'Execution Failed'
```

### Example 5

```PowerShell
Get-OpRuleAssignment -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R12' -DeviceGroup 'GRP900_VMware_HorizonAgent-Tools_NOW'
```

### Example 6

```PowerShell
Get-OpRuleAssignment -OpRule 'OPRULE_Cortado_ThinPrintDesktopAgent_R6' -DeviceGroup 'GRP900_Cortado_ThinPrintDesktopAgent_NEW' -Status 'Executed'
```

## PARAMETERS

### -OpRule

The Operational Rule to use

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

### -Device

The device that you want to filter the OpRule assignments down to.

```yaml
Type: Device[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status

The front end status that you want to filter the OpRule assignments down to.
Allowable values are:
Assigned, Assignment Paused, Assignment Sent, Assignment Waiting, Executed, Execution Failed, Not Received, Ready to Run, Reassignment Waiting, Sending Impossible, Unassignment Paused, Unassignment Waiting, Update Sent, Update Waiting, Updated, Verification Failed

```yaml
Type: String
Parameter Sets: Normal
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceGroup

The device group that you want to filter the OpRule assignments down to.

```yaml
Type: DeviceGroup
Parameter Sets: Normal
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RawData

This returns the raw API response, without any property flattening or value translations

```yaml
Type: SwitchParameter
Parameter Sets: Raw
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

## OUTPUTS

### OpRule

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
