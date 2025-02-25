---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMFrontEndText

## SYNOPSIS

Translates the BCM backend text to the GUI front-end text

## SYNTAX

```text
Get-BCMFrontEndText [-BackendText] <String[]> [-TranslationOnly] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Get-BCMFrontEndText -BackendText '_DB_OBJECTTYPE_OPERATIONALRULE_'
```

### Example 2

```PowerShell
Get-BCMFrontEndText -BackendText '_DB_OBJECTTYPE_OPERATIONALRULE_' -TranslationOnly
```

## PARAMETERS

### -BackendText

The back end text that you want to translate

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TranslationOnly

Returns just a string or array of strings with the front-end text
By default, the API returns an object with the backend text as the property name and the front-end text

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.String

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
