---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMID

## SYNOPSIS
Get the ID of a BCM object

## SYNTAX

### ByName (Default)
```
Get-BCMID -Name <String[]> -ObjectType <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByObjectType
```
Get-BCMID -Name <String[]> -ObjectTypeObject <ObjectType> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Get-BCMID -Name 'APPGRP_CrowdStrike_CrowdStrikeWindowsSensor_CUR' -ObjectType 'Device Group'
```

### EXAMPLE 2
```
Get-BCMID -Name 'OPRULE_Microsoft_Office365-64bit_R%' -ObjectType 'Operational Rule'
```

### EXAMPLE 3
```
Get-BCMID -Name 'PACKAGES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS' -ObjectTypeObject '_DB_OBJECTTYPE_PACKAGEFOLDER_'
```

## PARAMETERS

### -Name
The value of the name property of the object
If you want to do a wildcard search, the only allowable wildcard is '%', which matches zero or more characters

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -ObjectType
The object type to use

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectTypeObject
The front end name of the object type.
Allowable values are Device, Device Group, Operational Rule, Operational Rule Folder, Package

```yaml
Type: ObjectType
Parameter Sets: ByObjectType
Aliases:

Required: True
Position: Named
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

### BCMAPI.ObjectType
### String
## OUTPUTS

### System.Int32
## NOTES
Because device groups being in multiple parent groups will cause the name to return the same ID multiple times, the function only returns the unique IDs

## RELATED LINKS
