---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Use-BCMRestAPI

## SYNOPSIS
Makes authenticated RestAPI calls to the BMC Server

## SYNTAX

```
Use-BCMRestAPI [-URL] <String> [-Method <String>] [-Body <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Uses Invoke-RestMethod and encrypted credentials stored in $EncryptedCredentialsPath to make API calls.
Bypasses the certificate check.
Errors out if the HTTP response code is something other than 200

## EXAMPLES

### EXAMPLE 1
```
Use-BCMRestAPI -URL '/package/packages'
```

### EXAMPLE 2
```
Use-BCMRestAPI -URL "/device/1252/session" -Method PUT
```

### EXAMPLE 3
```
Use-BCMRestAPI -URL '/i18n/keywords' -Body '{ "keywords": [ "MODIFICATIONDATE", "PUBLISHSTATUS" ] }' -Method POST
```

## PARAMETERS

### -URL
The portion of the URL for the BCM API call after "https://$ServerPort/api/1"

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

### -Method
HTTP methods: GET, DELETE, PATCH, POST, or PUT

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: GET
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body
Use this if you need to send a body with your API call, generally only used with POST methods

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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
