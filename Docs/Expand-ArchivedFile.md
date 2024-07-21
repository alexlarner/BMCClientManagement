---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Expand-ArchivedFile

## SYNOPSIS

Extracts a single file from an zip file/archive

## SYNTAX

```text
Expand-ArchivedFile [-ArchiveFile] <FileInfo> [-FileName] <String> [-DestinationFolder] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Adds the System.IO.Compression.FileSystem Assembly
Uses .NET ZipFile class to OpenRead the Archive because the Extract-Archive cmdlet extracts all files
Extracts the file to a specified folder
Disposes of the .NET ZipFile object

## EXAMPLES

### Example 1

```PowerShell
Expand-ArchivedFile -ArchiveFile $File -FileName 'install.xml' -DestinationFolder 'C:\Windows\Temp\Unzipped'
```

## PARAMETERS

### -ArchiveFile

Must have a .zip file extension

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName

Name of the file in the archive that you want to unzip (including the extension)

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

### -DestinationFolder

The path of the folder where the file is to be extracted to

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

### System.IO.FileInfo

## OUTPUTS

### System.IO.FileInfo

## NOTES

## RELATED LINKS
