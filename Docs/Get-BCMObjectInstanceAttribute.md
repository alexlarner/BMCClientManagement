---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMObjectInstanceAttribute

## SYNOPSIS

Gathers the attributes of a particular instance of an object type

## SYNTAX

```text
Get-BCMObjectInstanceAttribute [-ObjectType] <ObjectType> [-InstanceID] <Int32>
 [[-TranslateBackendNames] <Boolean>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Get-BCMObjectInstanceAttribute -ObjectType $OpRuleObjectType -InstanceID $InstanceID
```

### Example 2

```PowerShell
Get-BCMObjectInstanceAttribute -ObjectType $OpRuleObjectType -InstanceID $InstanceID -TranslateBackendNames $false
```

## PARAMETERS

### -ObjectType

The ObjectType to use

```yaml
Type: ObjectType
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -InstanceID

The ID of the particular object

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -TranslateBackendNames

Translates the backend names of the properties (using Get-BCMFrontEndText) to their front-end names and adds them as alias properties for the backend names

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
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

### Bool

### Int

## OUTPUTS

## NOTES

## RELATED LINKS
