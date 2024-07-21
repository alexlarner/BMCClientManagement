---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Get-DeviceFactoryRunSummary

## SYNOPSIS
Gathers the latest factory run csv log for a given build type for a given machine

## SYNTAX

```
Get-DeviceFactoryRunSummary [-Name] <String[]> [[-BuildType] <String>] [-StatusFilter <String>]
 [-FactoryRunLogFolder <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function:
	Gathers the csv files directly (no recursion) in the path specified in the FactoryRunLogFolder parameter
	For each device:
		The logs containing the device name and specified BuildType are gathered
		The most recent csv is chosen if there are multiple csvs for that device
		The csv is then imported as objects and the steps are filtered down to the ones with the OpRule status grouping specified in the StatusFilter parameter

## EXAMPLES

### EXAMPLE 1
```
Get-DeviceFactoryRunSummary -Name VD0021868
```

### EXAMPLE 2
```
Get-DeviceFactoryRunSummary -Name VD0022169 -BuildType OPS
```

### EXAMPLE 3
```
Get-DeviceFactoryRunSummary -Name VD0022169 -BuildType OPS -StatusFilter Failed
```

### EXAMPLE 4
```
Get-DeviceFactoryRunSummary -Name VD0022169 -BuildType OPS -StatusFilter Failed -FactoryRunLogFolder "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Device Factory Run Summary CSVs"
```

## PARAMETERS

### -Name
The name of the device to gather the log for

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -BuildType
The build type to filter on for the device/s.
Options are Base, Base_Laptop, Base_DesktopandThinClient, Base_Packaging, Base_PhysicalServer, Base_VirtualServer, Cocoon, CycleHarvester, DataScience, JNAM, OPS, SIGDeveloper

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Base
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatusFilter
The OpRule status grouping to filter the factory steps down to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: NonSuccessful
Accept pipeline input: False
Accept wildcard characters: False
```

### -FactoryRunLogFolder
A description of the FactoryRunLogFolder parameter.
Options are:
	All: Assigned, Assignment Paused, Assignment Planned, Assignment Sent, Assignment Waiting, Available, Deleted, Dependency Check Failed, Dependency Check Requested, Dependency Check Successful, Disabled, Executed, Execution Failed, Not Received, Obsolete, Package Missing, Package Requested, Package Sent, Publication Planned, Publication Sent, Publication Waiting, Published, Ready to run, Reassignment Waiting, Reboot Pending, Sending impossible, Step Missing, Step Requested, Step Sent, Unassigned, Unassignment Paused, Unassignment Sent, Unassignment Waiting, Uninstalled, Update Paused, Update Planned, Update Sent, Update Waiting, Updated, Verification Failed, Verification Requested, Verified, Waiting for Operational Rule

	Failed: Dependency Check Failed, Execution Failed, Package Missing, Verification Failed

	Final: Dependency Check Failed, Executed, Execution Failed, Not Received, Publication Planned, Package Missing, Sending impossible, Step Missing, Unassignment Paused, Update Paused, Verification Failed

	NonSuccessful: Assigned, Assignment Paused, Assignment Planned, Assignment Sent, Assignment Waiting, Available, Deleted, Dependency Check Failed, Dependency Check Requested, Dependency Check Successful, Disabled, Execution Failed, Not Received, Obsolete, Package Missing, Package Requested, Package Sent, Publication Planned, Publication Sent, Publication Waiting, Published, Ready to run, Reassignment Waiting, Reboot Pending, Sending impossible, Step Missing, Step Requested, Step Sent, Unassigned, Unassignment Paused, Unassignment Sent, Unassignment Waiting, Uninstalled, Update Paused, Update Planned, Update Sent, Update Waiting, Updated, Verification Failed, Verification Requested, Verified, Waiting for Operational Rule

	Successful: Executed

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Device Factory Run Summary CSVs"
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
01.20.2021 - Alex Larner - Created function

## RELATED LINKS
