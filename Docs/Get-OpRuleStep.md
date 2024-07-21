---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-OpRuleStep

## SYNOPSIS
Gathers the steps assigned to an OpRule

## SYNTAX

### All (Default)
```
Get-OpRuleStep [-OpRule] <OpRule[]> [-RawResult] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByNumber
```
Get-OpRuleStep [-OpRule] <OpRule[]> [-RawResult] [[-StepNumber] <Int32[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Last
```
Get-OpRuleStep [-OpRule] <OpRule[]> [-RawResult] [-LastStep] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
A detailed description of the Get-OpRuleStep function.

## EXAMPLES

### EXAMPLE 1
```
Get-OpRuleStep -OpRule OPRULE_Adobe_AcrobatProDC_R3
```

### EXAMPLE 2
```
Get-OpRuleStep -OpRule OPRULE_Adobe_AcrobatProDC_R3 -RawResult
```

### EXAMPLE 3
```
Get-OpRuleStep -OpRule OPRULE_Adobe_AcrobatProDC_R3 -StepNumber 1,5,7
```

### EXAMPLE 4
```
Get-OpRuleStep -OpRule OPRULE_Adobe_Reader_R25 -LastStep
```

## PARAMETERS

### -OpRule
The OpRule to gather the steps of

```yaml
Type: OpRule[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -RawResult
A description of the RawResult parameter.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StepNumber
A description of the StepNumber parameter.

```yaml
Type: Int32[]
Parameter Sets: ByNumber
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastStep
A description of the LastStep parameter.

```yaml
Type: SwitchParameter
Parameter Sets: Last
Aliases:

Required: False
Position: 3
Default value: False
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

### StepAssignment
## NOTES
Additional information about the function.

## RELATED LINKS
