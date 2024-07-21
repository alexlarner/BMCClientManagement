---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# New-StepParameter

## SYNOPSIS

Create the needed step parameter objects for a given step type

## SYNTAX

### Guided (Default)

```text
New-StepParameter -StepType <StepType> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Provided

```text
New-StepParameter -StepType <StepType> -Values <Hashtable> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

This can be run in one of two ways:
	Guided, where you are prompted for the value for each needed parameter
	Provided, where you provide the hash table with the backend parameter name and the value

## EXAMPLES

### Example 1

```PowerShell
New-StepParameter -StepType $StepType
```

### Example 2

```PowerShell
New-StepParameter -StepType $StepType -Values @{
	_DB_STEPPARAM_TARGETPATHURL_	   = 'C:\Windows\Temp\media\blah.txt'
	_DB_STEPPARAM_FORCEDELETEREADONLY_ = $true
	_DB_STEPPARAM_ONLYDELETECONTENT_   = $false
}
```

## PARAMETERS

### -StepType

The step type to add the parameters for

```yaml
Type: StepType
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Values

A hashtable containing the backend property names and their values

```yaml
Type: Hashtable
Parameter Sets: Provided
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.StepType

### Hashtable

## OUTPUTS

## NOTES

## RELATED LINKS
