---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-BCMObjectType

## SYNOPSIS

Returns a Object Type object from the ObjectTypes variable

## SYNTAX

### ByName (Default)

```text
Get-BCMObjectType [-Name] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByID

```text
Get-BCMObjectType [-ID] <Int32[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByFrontEndName

```text
Get-BCMObjectType [-FrontEndName] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```PowerShell
Get-ObjectType -ID 1613
```

### Example 2

```PowerShell
Get-ObjectType -Name '_DB_STEPNAME_WAIT_'
```

### Example 3

```PowerShell
Get-ObjectType -FrontEndName 'Execute Program'
```

### Example 4

```PowerShell
Get-ObjectType -FrontEndName 'Registry*'
```

## PARAMETERS

### -ID

The ID of the Object Type Attribute
This is different between BCM installs

```yaml
Type: Int32[]
Parameter Sets: ByID
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

The backend BMC database name, from the name property of the Object Type object

```yaml
Type: String[]
Parameter Sets: ByName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### -FrontEndName

The front end name of the Object Type, generally the same name as in the GUI

```yaml
Type: String[]
Parameter Sets: ByFrontEndName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: True
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

### Int

## OUTPUTS

### ObjectType

## NOTES

## RELATED LINKS
