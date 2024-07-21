---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMObjectInstance

## SYNOPSIS

Gathers the instances of a particular object type that matches the specified attribute value

## SYNTAX

```text
Get-BCMObjectInstance [-ObjectType] <ObjectType> [[-Source] <String>] [-Attribute] <ObjectTypeAttribute>
 [-Value] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Translates the front end operator name to the backend operator name
Updates the 'Objects Found' parameter value to the proper formatting the API call, if used
Gathers the object instances

## EXAMPLES

### Example 1

```PowerShell
Get-BCMObjectInstance -ObjectType '_DB_OBJECTTYPE_OPERATIONALRULE_' -Attribute $OpRuleNameObjectTypeAttribute -Value '%Reader%'
```

### Example 2

```PowerShell
Get-BCMObjectInstance -ObjectType '_DB_OBJECTTYPE_DEVICE_' -Attribute $DeviceNameObjectTypeAttribute -Value 'VDPKG0001' -Source Topology
```

## PARAMETERS

### -ObjectType

The object type to use

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

### -Source

The place in BMC to search.
Allowable values are 'All', 'Hierarchy', 'Objects Found', and 'Topology' (Topology is what is used for devices)

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -Attribute

The BCM object type attribute

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

The value that you want to search off of.
If you want to do a wildcard search, the only allowable wildcard is '%', which matches zero or more characters
See https://docs.bmc.com/docs/bcm129/searching-objects-869555770.html#Searchingobjects-Advancesearch

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
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

### BCMAPI.ObjectType

### BCMAPI.ObjectTypeAttribute

### String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
