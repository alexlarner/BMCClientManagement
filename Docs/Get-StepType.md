---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-StepType

## SYNOPSIS

Returns a step type object from the StepTypes variable

## SYNTAX

### ByName (Default)

```text
Get-StepType [-Name] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByID

```text
Get-StepType [-ID] <Int32[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByFrontEndName

```text
Get-StepType [-FrontEndName] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Get-StepType -ID 1613
```

### Example 2

```PowerShell
Get-StepType -Name '_DB_STEPNAME_WAIT_'
```

### Example 3

```PowerShell
Get-StepType -FrontEndName 'Execute Program'
```

### Example 4

```PowerShell
Get-StepType -FrontEndName 'Registry*'
```

## PARAMETERS

### -ID

The ID of the step type
This is particular to the revision of the step and therefore can be different between BCM revisions

```yaml
Type: Int32[]
Parameter Sets: ByID
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

The backend BMC database name, from the name property of the step type object

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -FrontEndName

The front end name of the step type, generally the same name as in the GUI

```yaml
Type: String[]
Parameter Sets: ByFrontEndName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### String

### Int

## OUTPUTS

### StepType

## NOTES

## RELATED LINKS
