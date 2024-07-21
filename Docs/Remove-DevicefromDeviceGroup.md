---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Remove-DevicefromDeviceGroup

## SYNOPSIS

Removes a device from a device group

## SYNTAX

```text
Remove-DevicefromDeviceGroup [-Device] <Device[]> [-DeviceGroup] <DeviceGroup>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Remove-DevicefromDeviceGroup -Device 'VDPKG0011' -DeviceGroup 'APPGRP_Adobe_AcrobatProDC_CUR'
```

## PARAMETERS

### -Device

The device to remove

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

### -DeviceGroup

The device group to be removed from.

```yaml
Type: DeviceGroup
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

### BCMAPI.Device

### BCMAPI.Object.DeviceGroup

## OUTPUTS

## NOTES

If the API call fails due to a bad input, i.e.
Device doesn't exist, Device Group doesn't exist, Device isn't in the Device Group, the API result will just be blank.
There will not be an error code returned.

## RELATED LINKS
