---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Update-CMDBStatus

## SYNOPSIS

Creates a CMDB update csv in the specified folder

## SYNTAX

```text
Update-CMDBStatus [-DeviceNames] <String[]> [[-CMDBstatus] <Int32>] [[-CMDBUpdateFolder] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Update-CMDBStatus -DeviceNames 'VDPKG0001'
```

### Example 2

```PowerShell
Update-CMDBStatus -DeviceNames 'VDPKG0001' -CMDBStatus 3
```

### Example 3

```PowerShell
Update-CMDBStatus -DeviceNames 'VDPKG0001' -CMDBUpdateFolder "\\$CompanyDomainName\apps\Prod\JTS\Factory"
```

## PARAMETERS

### -DeviceNames

The names of the new devices to use

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CMDBstatus

The CMDB status number to update the devices with

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -CMDBUpdateFolder

The folder to place the update CSV in

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: "\\$CMDBUpdateServerName\CMDBstatus"
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

2020.12.15 - Updated function to handle the type entries for physical devices

## RELATED LINKS
