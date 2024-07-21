---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Write a timestamped message to a log and outputs the same message to the select output stream

## SYNTAX

```
Write-Log [-Message] <String> -LogFile <String> [-Stream <String>] [-ErrorAs <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Write-Log -Message 'Installed application' -LogFile 'C:\ProgramData\Media\Logs\Sample_Install.log'
```

### EXAMPLE 2
```
Write-Log -Message 'Failed to find file' -LogFile 'C:\ProgramData\Media\Logs\Sample_Install.log' -Stream Error
```

### EXAMPLE 3
```
Write-Log -Message 'Failed to copy folder' -LogFile 'C:\ProgramData\Media\Logs\Sample_Install.log' -Stream Error -ErrorAs Warning
```

## PARAMETERS

### -Message
The body of the error message

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogFile
The path to the log file.
The file must already exist.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Stream
The PowerShell output stream.
Allowable values are 'Success', 'Error', 'Warning', 'Verbose', 'Debug', 'Information'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Success
Accept pipeline input: False
Accept wildcard characters: False
```

### -ErrorAs
How you want the error to be formmated.
Allowable values are 'Error', 'Throw', 'Warning'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Error
Accept pipeline input: False
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

## OUTPUTS

## NOTES

## RELATED LINKS
