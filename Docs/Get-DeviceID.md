---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-DeviceID

## SYNOPSIS
Gets the ID of a device, given the device name

## SYNTAX

```
Get-DeviceID [-Name] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Looks up the device by the name
if more than one result is returned, the deprecated devices are filtered out
Errors out if multiple or no non-deprecated devices are found
The object returned by the API does not contain an ID property.
The Device ID itself is listed as a property name containing all the device properties
So the Device ID is extracted by grabbing the name of the note properties on the API response that only contain digits
Errors out if multiple or no possible IDs are found

## EXAMPLES

### EXAMPLE 1
```
Get-DeviceID -Name 'VDPKG0001'
```

## PARAMETERS

### -Name
The full name of the device

```yaml
Type: String[]
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

### System.String
## OUTPUTS

### System.Int
## NOTES

## RELATED LINKS
