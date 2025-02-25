---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-CheckforStringinFileStep

## SYNOPSIS

Adds a check for string in file step

## SYNTAX

```text
Add-CheckforStringinFileStep [-OpRule] <OpRule> [-FilePath] <String> [-String] <String>
 [[-ErrorIfFound] <Boolean>] [[-MatchCase] <Boolean>] [[-OnFail] <String>] [[-OnSuccess] <String>]
 [[-Verification] <String>] [[-Notes] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1: Add check for string in file step

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">'
```

### Example 2: Add step that errors out if the string is found

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -ErrorIfFound $true
```

### Example 3: Add step whose check is case-sensitive

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -MatchCase $true
```

### Example 4: Add step that continues even if the string is not found

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -OnFail 'Continue'
```

### Example 5: Add step that fails if the string is found

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -OnSuccess 'Fail'
```

### Example 6: Add step that repeats until the string is found

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -Verification 'FailContinue'
```

### Example 7: Add step with a note

```PowerShell
Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -Notes 'Made using the BCM Rest API'
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

The path of the file to check inside of

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

### -String

The string to check for inside the file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ErrorIfFound

Sets the step to error out if the string is found

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MatchCase

Forces the lookup to match the case of the given string

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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
Position: 6
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
Position: 7
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
Position: 8
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
Position: 9
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
