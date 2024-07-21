---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Wait-OpRuleAssignment

## SYNOPSIS

Supresses the command prompt until one or all of the OpRule Assignments are in a Final Status.
Can send an email alert.

## SYNTAX

```text
Wait-OpRuleAssignment [-Assignment] <OpRuleAssignment[]> [-MaxWaitTimeMinutes <Int32>]
 [-RefreshIntervalSeconds <Int32>] [-EmailAddress <String[]>] [-EmailMe] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Wait-OpRuleAssignment -Assignment $OpRuleAssignment
```

### Example 2

```PowerShell
Wait-OpRuleAssignment -Assignment $OpRuleAssignment -EmailAddress "John.Smith@$CompanyDomainName" -EmailMe
```

### Example 3

```PowerShell
Wait-OpRuleAssignment -Assignment $OpRuleAssignment -MaxWaitTimeMinutes 60
```

### Example 4

```PowerShell
Wait-OpRuleAssignment -Assignment $OpRuleAssignment -RefreshIntervalSeconds 30
```

## PARAMETERS

### -Assignment

The Operational Rule Assignment to use

```yaml
Type: OpRuleAssignment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -MaxWaitTimeMinutes

The maximum number of minutes that you want to wait for the OpRule Assignments to complete

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshIntervalSeconds

How often you want the status updates in the Information stream

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 60
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

The email addresses that you want the completion notification sent to.
Must be used with the EmailMe parameter else no email will be sent.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $MainUsersEmail
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailMe

Use this if you want an email notification along with the console notification
The email notification is an HTML email with a table containing the OpRule Assignment ID, OpRuleName, DeviceName, and status
The table formatting is controlled by an internal CSS

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

### BCMAPI.Assignment.OpRuleAssignment

### Int

### String

## OUTPUTS

### OpRuleAssignment

## NOTES

## RELATED LINKS
