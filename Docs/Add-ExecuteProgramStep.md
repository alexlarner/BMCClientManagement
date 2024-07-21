---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-ExecuteProgramStep

## SYNOPSIS

Add an execute program step to an OpRule

## SYNTAX

```text
Add-ExecuteProgramStep [-OpRule] <OpRule> [-RunCommand] <String> [[-WaitforEndofExecution] <Boolean>]
 [[-BackgroundMode] <Boolean>] [[-RunProgramInItsContext] <Boolean>] [[-ValidReturnCodes] <Int32[]>]
 [[-UseAShell] <Boolean>] [[-OnFail] <String>] [[-OnSuccess] <String>] [[-Notes] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad'
```

### Example 2

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -WaitforEndofExecution $false
```

### Example 3

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -BackgroundMode $false
```

### Example 4

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -RunProgramInItsContext $false
```

### Example 5

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -ValidReturnCodes 0, 1603
```

### Example 6

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -UseAShell $true
```

### Example 7

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -OnFail Succeed
```

### Example 8

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -OnSuccess Fail
```

### Example 9

```PowerShell
Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -Notes 'This was created from the API'
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

### -RunCommand

The Run Command for the step

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WaitforEndofExecution

Forces the step to wait until the command has finished executing before going to the next step

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

### -BackgroundMode

Runs the command in background mode

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -RunProgramInItsContext

Runs the command in its context

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidReturnCodes

The return codes from the run command to count as successes

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAShell

Runs the command in a shell

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: False
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
Position: 8
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
Position: 9
Default value: Continue
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
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRule

### Bool

### Int

### String

## OUTPUTS

### StepAssignment

## NOTES

## RELATED LINKS
