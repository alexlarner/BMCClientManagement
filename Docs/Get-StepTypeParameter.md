---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-StepTypeParameter

## SYNOPSIS

Gathers the parameters for a given step type

## SYNTAX

### All (Default)

```text
Get-StepTypeParameter [-StepType] <StepType[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByID

```text
Get-StepTypeParameter [-StepType] <StepType[]> [-ID] <Int32[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ByLabel

```text
Get-StepTypeParameter [-StepType] <StepType[]> [-Label] <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ByFrontEndLabel

```text
Get-StepTypeParameter [-StepType] <StepType[]> [-FrontEndLabel] <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

Gathers the parameters and casts them into a Step Parameter object

## EXAMPLES

### Example 1

```PowerShell
Get-StepTypeParameter -StepType $StepType
```

### Example 2

```PowerShell
Get-StepTypeParameter -StepType _DB_STEPNAME_DELETEDIRECTORY_ -ID 5025
```

### Example 3

```PowerShell
Get-StepTypeParameter -StepType '_DB_STEPNAME_REGISTRYMANAGEMENT_' -Label '_DB_STEPPARAM_REGISTRYKEY_'
```

### Example 4

```PowerShell
Get-StepTypeParameter -StepType '_DB_STEPNAME_RUNPROGRAM_' -FrontEndLabel 'Executable Path'
```

### Example 5

```PowerShell
Get-StepTypeParameter -StepType '_DB_STEPNAME_COPYFILE_' -FrontEndLabel '*Path*'
```

## PARAMETERS

### -StepType

The step type object to use
If this is the only parameter used, all the parameters for the object type will be returned.

```yaml
Type: StepType[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ID

The ID of the step type parameter
This is unique to the step type and the parameter (i.e.
the ID for the Executable Path parameter of an Execute Program step will be different from the Name property of a Executable Path parameter of an Execute Program as User step)
This can also be different between BCM revisions

```yaml
Type: Int32[]
Parameter Sets: ByID
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Label

The value of the label property on the step parameter
Use this only if you want to filter the parameters down to ones with a particular label

```yaml
Type: String[]
Parameter Sets: ByLabel
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -FrontEndLabel

The front end label of the parameter, generally the same name as in the GUI
Use this only if you want to filter the parameters down to ones with a particular front end label

```yaml
Type: String[]
Parameter Sets: ByFrontEndLabel
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
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

### BCMAPI.StepType

### Int

### String

## OUTPUTS

### StepTypeParameter

## NOTES

The Label property is used because the Name property does not use the usual BCM backend name, and does not translate properly to the front end name using BCMs own internal translation.
Why BMC decided to make the name property values on these objects different from the majority of their object types, remains to be seen.

## RELATED LINKS
