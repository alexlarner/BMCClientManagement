---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Build-FactoryDevice

## SYNOPSIS
Runs a group of devices through a factory build type

## SYNTAX

```
Build-FactoryDevice [[-DeviceCSVPath] <String>] [[-FactoryDefinitions] <String>] [[-Reassign] <String>]
 [[-RefreshInterval] <Int32>] [[-MaxOpRuleRetries] <Int32>] [-NovSphere] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Imports the Factory definitions CSV
Sets the reassignable statuses variable relative to the Reassign parameter selection
Test to see if the factory OpRules and device groups exist and are assigned to each other for the build types needed
*Creates a DeviceFactoryRun object for each device to keep track of the device's progress through the factory build
Sets the Factory Status custom vSphere attribute to "$($Run.BuildType)_Staging"
Adds the devices to the needed device groups for their factory build types
Verifies that the OpRule assignments properly cascaded down to the devices from each of the device groups
If the assignment hasn't cascaded down yet, it waits 5 seconds and checks again, and does that 5 times.
If the assignment still hasn't cascaded down yet, an error is thrown and the function is halted
Creates a FactoryBuildAssignment to keep track of each of the OpRule Assignments for the factory build for the device
Sets the Factory Status custom vSphere attribute to "$($Run.BuildType)_InProgress"
Export a CSV of the DeviceFactoryRun objects using New-FactoryRunReport
Reassigns the first OpRule assignment in each DeviceFactoryRun, if the status is in a "reassignable status"
Sets the current OpRule Assignment start time on the DeviceFactoryRun objects
Increments the current OpRule Assignment attempt count on the DeviceFactoryRun objects

Start a while loop that goes on as long as the Stopped property is still set to false on at least 1 of the DeviceFactoryRun objects
Exports an excerpt of the current status of all the DeviceFactoryRuns to "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Status CSVs"
Writes that same excerpt to the information stream
Starts a foreach loop for each DeviceFactoryRun object that has a Stopped property value of false
Refreshes the status of the current OpRule Assignment attempt count on the DeviceFactoryRun objects
Starts a do loop while the $RepeatStatusEval variable is set to $true
Sets the RepeatStatusEval variable to false
If the current OpRule Assignment status is a final status or the run time is over the max runtime in minutes
If the current OpRule Assignment is at its max limit of attempts or has a status of "Executed"
If the DeviceFactoryRun has no more assignments to run, set the Stopped property to true
If there are assignments in the current phase with a status other than "Executed" set the Factory Status custom vSphere attribute to "$($Run.BuildType)_Failed"
Else set the Factory Status custom vSphere attribute to "$($Run.BuildType)_Success"
Else if there are more assignments to run but there are failures in the current phase, set the Stopped property to true and set the Factory Status custom vSphere attribute to "$($Run.BuildType)_Failed"
Else update the current assignment to the next assignment, activate that assignment, set the start time, and increment the attempt counter
Else, reassign the OpRule, reset the assignment start & end times, increment the attempt counter for the assignment, and set the RepeatStatusEval variable to true
Else continue the loop
If all the Stopped properties on all the DeviceFactoryRun objects are set to true, export a new excerpt of the current status of all the DeviceFactoryRuns to "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Status CSVs"
Else wait for the number of the seconds specified by the RefreshInterval

## EXAMPLES

### EXAMPLE 1
```
Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-06__14-11-02_xbz1219.csv"
```

### EXAMPLE 2
```
Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-10__11-23-27_amfap0p.csv" -FactoryDefinitions "$ITNetworkShare\AutomatedFactory\Factory Definitions Archive\FactoryDefinitions_R33.csv"
```

### EXAMPLE 3
```
Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-03__08-39-41_xbz1219.csv" -Reassign 'All'
```

### EXAMPLE 4
```
Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-01-31__09-46-08_xbz1219.csv" -RefreshInterval 60
```

### EXAMPLE 5
```
Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-04__19-04-51_amfap0p.csv" -MaxOpRuleRetries 2
```

## PARAMETERS

### -DeviceCSVPath
The path to the CSV containing the device name and factory build to apply

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FactoryDefinitions
The path to the Factory Definitions CSV

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: "$ITNetworkShare\AutomatedFactory\FactoryDefinitions.csv"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reassign
Reassign the device if it has the specified OpRule assignment status
Allowable values are: 'All', 'ExecutionFailed', 'None', 'NonSuccessful'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RefreshInterval
The amount of time between checks for OpRule status updates

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxOpRuleRetries
The amount of OpRule attempts to make for each OpRule on each device if it is not successfull

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -NovSphere
{{ Fill NovSphere Description }}

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

### String
### Int
## OUTPUTS

### System.Management.Automation.PSObject
## NOTES
This creates a log in "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script" with a title that includes the function start time, initiator's username, and BMC environment being used

## RELATED LINKS
