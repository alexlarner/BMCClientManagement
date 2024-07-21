---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Send-FactoryAlert

## SYNOPSIS

Sends an email with the subject prepended with "Factory Alert"

## SYNTAX

```text
Send-FactoryAlert [-Body] <String> [-Subject] <String> [[-SubjectPrefix] <String>] [[-Sender] <String>]
 [[-Recipient] <String[]>] [[-LogPath] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

A detailed description of the Send-FactoryAlert function.

## EXAMPLES

### Example 1

```PowerShell
Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores'
```

### Example 2

```PowerShell
Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -SubjectPrefix 'AUTOMATED FACTORY ALERT'
```

### Example 3

```PowerShell
Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -Sender "John.Smith@$CompanyDomainName"
```

### Example 4

```PowerShell
Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -Recipient "Jane.Doe@$CompanyDomainName"
```

### Example 5

```PowerShell
Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -LogPath "$ITNetworkShare\AutomatedFactory\Logs\Trim VM Build Script\TrimVMBuild_amfap0p_2020-02-07__14-45-02.log"
```

## PARAMETERS

### -Body

The body of text for the email

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

### -Subject

A description of the Subject parameter.

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

### -SubjectPrefix

The prefix to prepend the subject with

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: FACTORY ALERT
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sender

The email address to send

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: "do_not_reply@$CompanyDomainName"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recipient

The email address for the recipient

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: ($MainUsersEmail, $MainUsersManagersEmail)
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath

The path to the relevant factory log, to be reference at the end of the email

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

## OUTPUTS

## NOTES

## RELATED LINKS
