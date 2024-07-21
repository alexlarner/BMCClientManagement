---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-SteptoOpRule

## SYNOPSIS

Add a step to an OpRule

## SYNTAX

```text
Add-SteptoOpRule [-OpRule] <OpRule> [-StepType] <StepType> [[-OnFail] <String>] [[-OnSuccess] <String>]
 [[-Verification] <String>] [[-Notes] <String>] [[-StepParameters] <StepParameter[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType
```

### Example 2

```PowerShell
Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -OnFail Succeed
```

### Example 3

```PowerShell
Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -OnSuccess Succeed
```

### Example 4

```PowerShell
Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -Verification FailSucceed
```

### Example 5

```PowerShell
Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -Notes 'This step is here because xyz'
```

## PARAMETERS

### -OpRule

The OpRule to add the step to

```yaml
Type: OpRule
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StepType

The step type to add to the OpRule

```yaml
Type: StepType
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnFail

What to do if the step fails

Allowable values are:

- Continue
- Fail
- Succeed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Fail
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnSuccess

What to do if the step succeeds

Allowable values are:

- Continue
- Fail
- Succeed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Continue
Accept pipeline input: False
Accept wildcard characters: False
```

### -Verification

The setting for the step verification

Allowable values are:

- FailContinue
    - Loop while verification fails
- FailFail
    - Rule execution fails if the verification fails.
- FailSucceed
    - Rule successfully executes if the verification fails
- SuccessContinue
    - Loop while verification succeeds
- SuccessFail
    - Rule execution fails if the verification succeeds.
- SuccessSucceed
    - Rule successfully executes if the verification succeeds
- None
    - Do not perform verification


```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes

The notes to add to the step

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StepParameters

The parameters for the new step.
If this is not used, then the new step is created with all the default values and sample text.

```yaml
Type: StepParameter[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRule

### BCMAPI.StepType

### BCMAPI.StepParameter

### String

## OUTPUTS

### StepAssignment

## NOTES

There is no way to set the succeed or fail condition to go to to a step.
To do that you have to use this function to create the command, then use Update-OpRuleStepResultCondition to set the success or fail condition to "Go to Step _"

## RELATED LINKS
