---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMObjectTypeAttribute

## SYNOPSIS
Gathers the attributes for a BCM Object Type

## SYNTAX

### All (Default)
```
Get-BCMObjectTypeAttribute [-ObjectType] <ObjectType[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ByID
```
Get-BCMObjectTypeAttribute [-ObjectType] <ObjectType[]> [-ID] <Int32[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ByName
```
Get-BCMObjectTypeAttribute [-ObjectType] <ObjectType[]> [-Name] <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ByFrontEndName
```
Get-BCMObjectTypeAttribute [-ObjectType] <ObjectType[]> [-FrontEndName] <String[]>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Get-BCMObjectTypeAttribute -ObjectType $ObjectType
```

### EXAMPLE 2
```
Get-BCMObjectTypeAttribute -ObjectType $ObjectType -ID 12345
```

### EXAMPLE 3
```
Get-BCMObjectTypeAttribute -ObjectType $ObjectType -Name *Time
```

### EXAMPLE 4
```
Get-BCMObjectTypeAttribute -ObjectType $ObjectType -Name _DB_ATTR_CREATEDBY_
```

### EXAMPLE 5
```
Get-BCMObjectTypeAttribute -ObjectType $ObjectType -FrontEndName 'Created By'
```

## PARAMETERS

### -ObjectType
The ObjectType object.
This can be had by using Get-BCMObject.
If this is the only parameter used, all the attributes for the object type will be returned.

```yaml
Type: ObjectType[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ID
The ID of the Object Type Attribute
This:
	Is unique to the object and the attribute (i.e.
the ID for the Name property of an OpRule will be different from the Name property of a Device Group)
	Is be different between BCM installs
	Can be different between BCM revisions

```yaml
Type: Int32[]
Parameter Sets: ByID
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The front end name (generally the same name as in the GUI) of the Object Type Attribute
If this parameter is used, the attributes are filtered down AFTER they are converted to ObjectTypeAttribute objects.

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FrontEndName
A description of the FrontEndName parameter.

```yaml
Type: String[]
Parameter Sets: ByFrontEndName
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
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
### Int
### String
## OUTPUTS

### ObjectTypeAttribute
## NOTES
This will:
	Error out if multiple attributes are found when using the ID parameter
	Give a warning if multiple attributes are found when using the Name or FrontEndName parameter without any wildcards
	Writes a verbose message if no attributes are found when using the ID, Name, or FrontEndName parameters

## RELATED LINKS
