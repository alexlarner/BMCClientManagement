---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-CheckforFileStep

## SYNOPSIS

Adds a check for file step to an OpRule

## SYNTAX

```text
Add-CheckforFileStep [-OpRule] <OpRule> [-FilePath] <String> [[-OnFail] <String>] [[-OnSuccess] <String>]
 [[-Verification] <String>] [[-Notes] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe'
```

### Example 2

```PowerShell
Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -OnFail 'Continue'
```

### Example 3

```PowerShell
Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -OnSuccess 'Fail'
```

### Example 4

```PowerShell
Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -Verification 'SuccessContinue'
```

### Example 5

```PowerShell
Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -Notes 'Created by BCM Rest API'
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

### -FilePath

The path of the file to check for

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

### -OnFail

What to do if the step fails
Allowable values are: 'Continue', 'Fail', 'Succeed'

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
Allowable values are: 'Continue', 'Fail', 'Succeed'

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
	FailContinue (Loop while verification fails)

	FailFail (Rule execution fails if the verification fails.)

	FailSucceed (Rule successfully executes if the verification fails)

	SuccessContinue (Loop while verification succeeds)

	SuccessFail (Rule execution fails if the verification succeeds.)

	SuccessSucceed (Rule successfully executes if the verification succeeds)

	None (Do not perform verification)

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

## RELATED LINKS
