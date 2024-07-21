---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# New-FactoryRunReport

## SYNOPSIS

Creates a CSV of a Device's Factory Run

## SYNTAX

```text
New-FactoryRunReport [-DeviceFactoryRun] <DeviceFactoryRun[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Exports a CSV of the Factory Run containing the:
OpRule order, OpRule name, Device Group name, OpRule assignment Status, Factory phase, OpRule attempt count, OpRule assignment duration, OpRule assignment start time, OpRule assignment end time

## EXAMPLES

### Example 1

```PowerShell
New-FactoryRunReport -DeviceFactoryRun $DeviceFactoryRun
```

## PARAMETERS

### -DeviceFactoryRun

The device factory run to use

```yaml
Type: DeviceFactoryRun[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### DeviceFactoryRun

## OUTPUTS

## NOTES

## RELATED LINKS
