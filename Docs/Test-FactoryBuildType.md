---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Test-FactoryBuildType

## SYNOPSIS

Tests to see if the Factory Device Groups & Factory OpRules exist and are assigned to each other

## SYNTAX

```text
Test-FactoryBuildType [[-FactoryBuildType] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Test-FactoryBuildType -FactoryBuildType 'Base'
```

## PARAMETERS

### -FactoryBuildType

The Factory Build type to test.
Allowable values are 'Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'DataScience', 'JNAM', 'OPS', 'SIGDeveloper'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### String

## OUTPUTS

### System.Boolean

## NOTES

## RELATED LINKS
