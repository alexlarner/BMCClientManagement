---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-DevicetoADGroup

## SYNOPSIS

Adds a device to an Active Directory group

## SYNTAX

```text
Add-DevicetoADGroup [-ComputerName] <String> [-ADGroupName] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-DevicetoADGroup -ComputerName 'VDPKG0011' -ADGroupName "$ShortCompanyName - Client Services RDP Policy (1.1)"
```

## PARAMETERS

### -ComputerName

The name of the device to add to the group

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ADGroupName

The name of the Active Directory group to add devices to

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

## NOTES

Does not use the Active Directory PowerShell Module, instead this adds the 'System.DirectoryServices.AccountManagement' assembly and uses that

## RELATED LINKS
