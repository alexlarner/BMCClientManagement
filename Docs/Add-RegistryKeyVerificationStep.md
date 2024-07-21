---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-RegistryKeyVerificationStep

## SYNOPSIS
Adds a registry key verification step

## SYNTAX

```
Add-RegistryKeyVerificationStep [-OpRule] <OpRule> [-Key] <String> [[-Property] <String>] [[-Value] <String>]
 [[-BinaryKeyinHexNotation] <Boolean>] [[-OnFail] <String>] [[-OnSuccess] <String>] [[-Verification] <String>]
 [[-Notes] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS'
```

### EXAMPLE 2
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Property 'VMwareAgentToolsRebootCounter'
```

### EXAMPLE 3
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Property 'VMwareAgentToolsRebootCounter' -Value 2
```

### EXAMPLE 4
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Property 'VMwareAgentToolsRebootCounter' -Value 0 -BinaryKeyinHexNotation $true
```

### EXAMPLE 5
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -OnFail Succeed
```

### EXAMPLE 6
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -OnSuccess Fail
```

### EXAMPLE 7
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Verification 'SuccessSucceed'
```

### EXAMPLE 8
```
Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Notes 'Created with the BCM API'
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

### -Key
The full registry key path

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

### -Property
The registry key property name to check for
If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: Open the OpRule and hit OK to remove me
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The value of registry key property to check for.
This must be used with the property
If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Open the OpRule and hit OK to remove me
Accept pipeline input: False
Accept wildcard characters: False
```

### -BinaryKeyinHexNotation
Interprets the hex notated value as a binary value

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
Allowable values are: 'Continue', 'Fail', 'Succeed'

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
Allowable values are: 'Continue', 'Fail', 'Succeed'

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
