---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Update-ObjectInstanceAttribute

## SYNOPSIS
Update the attribute of a BCM object instance

## SYNTAX

```
Update-ObjectInstanceAttribute [-ObjectType] <ObjectType> [-Instance] <BCMAPI[]>
 [-ObjectTypeAttribute] <ObjectTypeAttribute> [-Value] <Object> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Update-ObjectInstanceAttribute -ObjectType $ObjectType -Instance $Instance -ObjectTypeAttribute $ObjectTypeAttribute -Value $Value
```

## PARAMETERS

### -ObjectType
The object type of the object that you want to update.
Use Get-BCMObjectType to get the object for this

```yaml
Type: ObjectType
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Instance
The Object instance to update.
This can be any object type under BCMAPI, because the object just needs to have an ID property.
Only one object type should be used for this

```yaml
Type: BCMAPI[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ObjectTypeAttribute
The attribute of the object to update.
This is not just the name of the object but the unique BCM object for the attribute for that particular object type
i.e.
The object for the Name attribute of an OpRule is distinct from the object for the Name attribute of a Device Group

```yaml
Type: ObjectTypeAttribute
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The new value to update the object's attribute with

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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

## OUTPUTS

## NOTES
This is a very unstable function as the BCM API is very inconsistent with the required input formatting between object types

## RELATED LINKS
