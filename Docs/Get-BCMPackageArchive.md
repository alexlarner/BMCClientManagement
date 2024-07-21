---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMPackageArchive

## SYNOPSIS
Looks for the ZIP file of the package install media in the Vision64Database folder on the BCM server

## SYNTAX

```
Get-BCMPackageArchive [-Package] <Package[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Get-BCMPackageArchive -Package $BCMPackage
```

## PARAMETERS

### -Package
The package to use

```yaml
Type: Package[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### BCMAPI.Object.Package
### BCMAPI.Object.Package.CustomPackage
### BCMAPI.Object.Package.MSIPackage
## OUTPUTS

### System.IO.FileInfo
## NOTES

## RELATED LINKS
