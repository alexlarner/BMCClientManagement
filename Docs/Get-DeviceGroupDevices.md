---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-DeviceGroupDevices

## SYNOPSIS

Gathers the devices assigned to a particular device group and returns them in the specified format

## SYNTAX

```text
Get-DeviceGroupDevices [-DeviceGroup] <DeviceGroup[]> [-IDOnly] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Gathers the devices assigned to a device group
By default this just returns the ID, Name, Notes and Created Date
But if DeviceDetails or IDOnly are chosen, a different API call is made to grab just the IDs of the devices assigned to the device group
if DeviceDetails is chosen in the ResultType parameter, the full device properties are gathered using Get-BCMDevice and the device IDs gathered in the previous step

## EXAMPLES

### Example 1

```PowerShell
Get-DeviceGroupDevices -DeviceGroup $DeviceGroup
```

### Example 2

```PowerShell
Get-DeviceGroupDevices -DeviceGroup $DeviceGroup -IDOnly
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
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -IDOnly

Use if you'd like the function to return just the Device IDs

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

## OUTPUTS

### Device

### System.Int32

## NOTES

## RELATED LINKS
