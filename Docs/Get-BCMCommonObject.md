---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMCommonObject

## SYNOPSIS

Gathers a BCM Object

## SYNTAX

```text
Get-BCMCommonObject [-Name] <String[]> [-ObjectType] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Get-BCMCommonObject -Name VDPKG0001 -ObjectType Device
```

### Example 2

```PowerShell
Get-BCMCommonObject -Name 'OPRULE_CrowdStrike_CrowdStrikeWindowsSensor_R%' -ObjectType 'Operational Rule'
```

## PARAMETERS

### -Name

The name of the object
If you want to do a wildcard search, the only allowable wildcard is '%', which matches zero or more characters

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -ObjectType

The front end name of the object type.
Allowable values are Device, Device Group, Operational Rule, Operational Rule Folder, Package

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

## OUTPUTS

### Device

### DeviceGroup

### OpRule

### OpRuleFolder

### Package

### MSIPackage

### CustomPackage

## NOTES

## RELATED LINKS
