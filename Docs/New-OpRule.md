---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# New-OpRule

## SYNOPSIS

Create a new blank OpRule with no steps

## SYNTAX

```text
New-OpRule [-Name] <String[]> [-OpRuleFolder] <OpRuleFolder> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
New-OpRule -Name 'OPRULE_Sample_Test_R1'
```

### Example 2

```PowerShell
New-OpRule -Name 'OPRULE_Sample_Test_R1' -OpRuleFolder 'Engineers'
```

## PARAMETERS

### -Name

The name to use for the new OpRule

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OpRuleFolder

The operational rule folder to place the new operational rule in
Default is the '_OPRULES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS' folder

```yaml
Type: OpRuleFolder
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: (Get-BCMCommonObject _OPRULES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS -ObjectType 'Operational Rule Folder')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.OpRuleFolder

### String

## OUTPUTS

### OpRule

## NOTES

## RELATED LINKS
