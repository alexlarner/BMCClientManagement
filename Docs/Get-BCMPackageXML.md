---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMPackageXML

## SYNOPSIS

Finds the Install.XML file for a given BMC package

## SYNTAX

```text
Get-BCMPackageXML [-Package] <Package[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Looks for the Install.XML file under the correct subfolder (PackagerMSI or PackagerCustom) on the BMC server under 'D:\Program Files\BMC Software\Client Management\Master\data'
if that doesn't exist, it looks for the Install.XML file in the package archive file listed on the ArchiveFile property.
if the Install.XML file is found in the package archive file, it is extracted to "$env:temp\BCMAPI\$($Package.Name)"
Then the Install.XML file is read into a \[xml\] type variable, and if the XML file had to be extracted, the extracted source file is deleted

## EXAMPLES

### Example 1

```PowerShell
Get-BCMPackageXML -Package $BCMPackage
```

## PARAMETERS

### -Package

Must be a BCMAPI.Object.Package type with the "Type" property being Custom or MSI

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BCMAPI.Object.Package

### BCMAPI.Object.Package.CustomPackage

### BCMAPI.Object.Package.MSIPackage

## OUTPUTS

### System.Xml.XmlDocument

## NOTES

## RELATED LINKS
