---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-PackagetoOpRule

## SYNOPSIS

Adds a package to an OpRule

## SYNTAX

```text
Add-PackagetoOpRule [-Package] <Package[]> [-OpRule] <OpRule> [[-OnSuccess] <String>] [[-OnFail] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-PackagetoOpRule -Package 'PKG_OpenText_Exstream_16-3-5_R1.cst' -OpRule 'OPRULE_OpenText_Exstream_R4'
```

### Example 2

```PowerShell
Add-PackagetoOpRule -Package 'PKG_OpenText_Exstream_16-3-5_R1.cst' -OpRule 'OPRULE_OpenText_Exstream_R4' -OnSuccess 'Fail'
```

### Example 3

```PowerShell
Add-PackagetoOpRule -Package 'PKG_OpenText_Exstream_16-3-5_R1.cst' -OpRule 'OPRULE_OpenText_Exstream_R4' -OnFail 'Continue'
```

## PARAMETERS

### -Package

The package to add
If adding by name, make sure to include the extension ('.cst' or '.msi') in the name

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

### -OpRule

The OpRule to add the packages to

```yaml
Type: OpRule
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
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
Position: 3
Default value: Continue
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
Position: 4
Default value: Fail
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
