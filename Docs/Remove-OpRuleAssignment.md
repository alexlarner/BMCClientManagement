---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Remove-OpRuleAssignment

## SYNOPSIS

Removes the assignment of a Device to an OpRule

## SYNTAX

```text
Remove-OpRuleAssignment [-Assignment] <OpRuleAssignment[]> [[-Activation] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Remove-OpRuleAssignment -Assignment $OpRuleAssignment
```

### Example 2

```PowerShell
Remove-OpRuleAssignment -Assignment $OpRuleAssignment -Activation manual
```

## PARAMETERS

### -Assignment

The operational rule assignment to remove

```yaml
Type: OpRuleAssignment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Activation

Whether or not the unaassignment is to be effective immediately (automatic), or in a paused state (manual)
Allowable values are: automatic and manual

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Automatic
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

### BCMAPI.Assignment.OpRuleAssignment

## OUTPUTS

## NOTES

## RELATED LINKS
