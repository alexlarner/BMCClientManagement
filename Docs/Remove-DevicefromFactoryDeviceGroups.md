---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Remove-DevicefromFactoryDeviceGroups

## SYNOPSIS
Remove devices from all the device groups of a specified factory build

## SYNTAX

```
Remove-DevicefromFactoryDeviceGroups [-Device] <Device[]> [[-BuildType] <String>]
 [-FactoryDefinitions <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Remove-DevicefromFactoryDeviceGroups -Device VDPKG0001
```

### EXAMPLE 2
```
Remove-DevicefromFactoryDeviceGroups -Device VDPKG0001 -BuildType Base
```

### EXAMPLE 3
```
Remove-DevicefromFactoryDeviceGroups -Device VDPKG0001 -FactoryDefinitions "$ITNetworkShare\AutomatedFactory\Factory Definitions Archive\FactoryDefinitions_R34.csv"
```

## PARAMETERS

### -Device
The BCM device to use

```yaml
Type: Device[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BuildType
The build type to remove the device from its device groups
Allowable values are 'All', 'Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'JNAM', 'OPS', 'SIGDeveloper'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -FactoryDefinitions
The path to the factory definitions spreadsheet.
The path must exist and have an extension of .csv.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "$ITNetworkShare\AutomatedFactory\FactoryDefinitions.csv"
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

### BCMAPI.Device
### String
## OUTPUTS

## NOTES
This would generally only be used on IT Systems Engineer test machines

## RELATED LINKS
