---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-OpRuleMarkerSteps

## SYNOPSIS

Adds the steps for the registry keys for the OpRule markers in Programs & Features

## SYNTAX

```text
Add-OpRuleMarkerSteps [-OpRule] <OpRule[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-OpRuleMarkerSteps -OpRule 'OPRULE_Alex_RESTAPI-Test_R1'
```

## PARAMETERS

### -OpRule

The OpRule to add the steps to

```yaml
Type: OpRule[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRule

## OUTPUTS

## NOTES

## RELATED LINKS
