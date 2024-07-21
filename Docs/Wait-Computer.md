---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Wait-Computer

## SYNOPSIS

Wait for a new computer to appear in BCM or Active Directory

## SYNTAX

```text
Wait-Computer [-ComputerName] <String[]> [-System] <Object> [[-MaxWaitTimeMinutes] <Int32>]
 [[-RefreshIntervalSeconds] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Wait-Computer -ComputerName VD0030000 -System 'Active Directory'
```

### Example 2

```PowerShell
Wait-Computer -ComputerName VD0030000 -System 'Active Directory' -MaxWaitTimeMinutes 60
```

### Example 3

```PowerShell
Wait-Computer -ComputerName VD0030000 -System 'BMC Client Management' -RefreshIntervalSeconds 120
```

## PARAMETERS

### -ComputerName

The name of the device to look for

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

### -System

The system to look for the device in: 'Active Directory' or 'BMC Client Management'

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxWaitTimeMinutes

The maximum amount of time that you want to wait for the device to appear

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 45
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshIntervalSeconds

The amount of seconds between checks for the device

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Int

### String

## OUTPUTS

## NOTES

This does not use the Active Directory module, instead it adds the 'System.DirectoryServices.AccountManagement' assembly to do the Active Directory lookup

## RELATED LINKS
