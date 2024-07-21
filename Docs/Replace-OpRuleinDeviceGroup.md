---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Replace-OpRuleinDeviceGroup

## SYNOPSIS

{{ Fill in the Synopsis }}

## SYNTAX

```text
Replace-OpRuleinDeviceGroup [-OldOpRule] <OpRule> [-NewOpRule] <OpRule> [-DeviceGroup] <DeviceGroup[]>
 [-AssignInActiveState] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

{{ Fill in the Description }}

## EXAMPLES

### Example 1

```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AssignInActiveState

{{ Fill AssignInActiveState Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceGroup

{{ Fill DeviceGroup Description }}

```yaml
Type: DeviceGroup[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -NewOpRule

{{ Fill NewOpRule Description }}

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

### -OldOpRule

{{ Fill OldOpRule Description }}

```yaml
Type: OpRule
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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

### DeviceGroup[]

## OUTPUTS

### OpRuleDeviceGroupAssignment

## NOTES

## RELATED LINKS
