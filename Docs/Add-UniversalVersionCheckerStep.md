---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Add-UniversalVersionCheckerStep

## SYNOPSIS

Adds an execute program step with the run command for the Universal Version Checker

## SYNTAX

```text
Add-UniversalVersionCheckerStep [-OpRule] <OpRule> [[-VersionCheckerRevision] <Int32>] [-FiletoCheck] <String>
 [-VersionNumber] <String> [[-VersionType] <String>] [-ReplaceComma] [-ForcePath] [[-OnFail] <String>]
 [[-OnSuccess] <String>] [[-Notes] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275'
```

### Example 2

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '1.2.3.4' -VersionType 'FileVersionRaw'
```

### Example 3

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -ReplaceComma
```

### Example 4

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -ForcePath
```

### Example 5

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -ForcePath
```

### Example 6

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -OnFail 'Continue'
```

### Example 7

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -OnSuccess 'Fail'
```

### Example 8

```PowerShell
Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -Notes 'Made with BCM Rest API'
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

### -VersionCheckerRevision

The revision number of the universal version checker

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 11
Accept pipeline input: False
Accept wildcard characters: False
```

### -FiletoCheck

The path of the file to do the version check on

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

### -VersionNumber

The version number for the version check

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VersionType

The version property on the file object (from "(Get-ItemProperty $FilePath).VersionInfo") to check off of.
Allowable values: 'FileVersion', 'ProductVersion', 'FileVersionRaw', 'ProductVersionRaw'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: FileVersion
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReplaceComma

If the file's version number uses commas instead of periods, use this for replace them so the version number can be recognized as a version number object

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

### -ForcePath

This forces the file to only be looked for in the path specified.
By default the version checker looks for the file in both "Program Files" & "Program Files (x86)"

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

### -Notes

The notes to add to the step

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
