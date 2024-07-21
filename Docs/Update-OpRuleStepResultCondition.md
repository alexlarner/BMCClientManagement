---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Update-OpRuleStepResultCondition

## SYNOPSIS

Update the result logic of an OpRule step

## SYNTAX

### Simple (Default)

```text
Update-OpRuleStepResultCondition -StepAssignment <StepAssignment[]> -ResultType <String> -Action <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### GoTo

```text
Update-OpRuleStepResultCondition -StepAssignment <StepAssignment[]> -ResultType <String> -GoToStep <Int32>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Update-OpRuleStepResultCondition -StepAssignment $StepAssignment -ResultType Fail -Action Fail
```

### Example 2

```PowerShell
Update-OpRuleStepResultCondition -StepAssignment $StepAssignment -ResultType Success -GoToStep 5
```

## PARAMETERS

### -StepAssignment

The step assignment to update

```yaml
Type: StepAssignment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ResultType

The result logic of the step to update, on "Fail" or on "Success"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action

What to do on step fail or success

Allowable values are:

- Continue
- Fail
- Succeed

```yaml
Type: String
Parameter Sets: Simple
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GoToStep

The step to go to on fail or success

```yaml
Type: Int32
Parameter Sets: GoTo
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.StepAssignment

### Int

### String

## OUTPUTS

## NOTES

## RELATED LINKS
