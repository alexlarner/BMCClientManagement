---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Update-OpRuleAssignmentStatus

## SYNOPSIS
Updates the status of an OpRule Assignment

## SYNTAX

```
Update-OpRuleAssignmentStatus [-NewStatus] <String> [-Assignment] <OpRuleAssignment[]>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Translates the front end status name to the backend status name
Updates the OpRule assignment using the backend status name and the assignment ID

## EXAMPLES

### EXAMPLE 1
```
Update-OpRuleAssignmentStatus -NewStatus 'Reassignment Waiting' -Assignment $OpRuleAssignment
```

## PARAMETERS

### -NewStatus
The front end name of the OpRule assignment status
Prepopulated from: Get-Enums OpRuleStatus | % {Get-BCMFrontEndText $_ -TranslationOnly}
Allowable values are 'Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Executed', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule'

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

### -Assignment
The OpRule Assignment to use

```yaml
Type: OpRuleAssignment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
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

### BCMAPI.Assignment.OpRuleAssignment
### String
## OUTPUTS

### OpRule
### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS
