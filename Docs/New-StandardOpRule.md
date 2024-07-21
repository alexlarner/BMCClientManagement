---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# New-StandardOpRule

## SYNOPSIS

Creates a new standard OpRule in BMC

## SYNTAX

```text
New-StandardOpRule [-Vendor] <String> [-Application] <String> [-OpRuleRevision] <Int32>
 [-VersionNumber] <String> [-FiletoCheck] <String> [[-UniversalVersionCheckerRevision] <Int32>]
 [[-OpRuleFolder] <OpRuleFolder>] [[-Environment] <String>] [[-Region] <String>] [[-Edition] <String>]
 [[-PackagesToAdd] <Package[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Creates a new OpRule and adds these to it:
Version Checker Package
A version checker step
The specified packages
A second version checker step
The 4 registry keys for the OpRule marker
Two delete directory steps
	"C:\Windows\Temp\media\bmc\$Vendor"
	"C:\Windows\Temp\media\bmc\JET"

## EXAMPLES

### Example 1

```PowerShell
New-StandardOpRule -Vendor 'Adobe' -Application 'Reader' -OpRuleRevision 27 -VersionNumber '15.7.20033.133275' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'
```

### Example 2

```PowerShell
New-StandardOpRule -Vendor 'Oracle' -Application 'JavaRuntimeEnvironment' -OpRuleRevision 13 -VersionNumber '8.0.2410.7' -FiletoCheck 'C:\Program Files\Java\jre1.8.*\bin\java.exe' -UniversalVersionCheckerRevision 9
```

### Example 3

```PowerShell
New-StandardOpRule -Vendor 'Symantec' -Application 'SEP' -OpRuleRevision 14 -VersionNumber '14.2.5323.2000' -FiletoCheck 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\14.2.5323.2000.105\Bin\SMC.EXE' -OpRuleFolder 'Testing Operational Rules'
```

### Example 4

```PowerShell
New-StandardOpRule -Vendor 'Rapid7' -Application 'Insight Agent' -OpRuleRevision 2 -VersionNumber '2.5.3.8' -FiletoCheck 'C:\Program Files\Rapid7\Insight Agent\components\insight_agent\2.5.3.8\ir_agent.exe' -Environment Laptop
```

### Example 5

```PowerShell
New-StandardOpRule -Vendor 'ARC' -Application 'CASE' -OpRuleRevision 4 -VersionNumber '2019.6.1.0' -FiletoCheck 'C:\Program Files\Actuarial Resources Corporation\CASE 2019.06.01 - CASE_PROD\Case.exe' -Region 'PROD'
```

### Example 6

```PowerShell
New-StandardOpRule -Vendor 'Google' -Application 'Chrome' -OpRuleRevision 16 -VersionNumber '80.0.3987.122' -FiletoCheck 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -Edition 'Enterprise'
```

### Example 7

```PowerShell
New-StandardOpRule -Vendor 'SovosETM' -Application 'WingsClient' -OpRuleRevision 2 -VersionNumber '2019.12.7313.21381' -FiletoCheck 'C:\Program Files (x86)\EagleTM\Wings\WingsClient.exe' -PackagesToAdd 'PKG_SovosETM_WingsClient_2019-12-7267-30384_UNINSTALL_R1.msi', 'PKG_SovosETM_WingsClient_2019-12-7313-21381_R1.msi'
```

## PARAMETERS

### -Vendor

The name of the vendor of the application you are packaging
This is used in the OpRule Name, OpRule Marker, and a delete directory step

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

### -Application

The name of the application you are packaging
This is used in the OpRule Name, OpRule Marker, and a delete directory step

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

### -OpRuleRevision

The revision for the new OpRule
This is used in the OpRule Name and OpRule Marker

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -VersionNumber

The version number of the application's main exe
This is used in the version checker in the execute program steps

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FiletoCheck

The file to check with the version checker in the execute program steps

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UniversalVersionCheckerRevision

The universal version checker package revision to use (PKG_JET_Universal_VC_R*)
This is only used to add the package to the OpRule, and is not used in the creation of the execute program steps.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 11
Accept pipeline input: False
Accept wildcard characters: False
```

### -OpRuleFolder

The OpRule folder to place the new OpRule in

```yaml
Type: OpRuleFolder
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: (Get-BCMCommonObject -Name '_OPRULES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS' -ObjectType 'Operational Rule Folder')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Environment

The environment of the application install, if the install is environment is specific.
This is generally only needed if you are creating multiple editions of the OpRule for different environments.
This is used in the OpRule Name and OpRule Marker
Allowable values are: 'Physical', 'Virtual', 'Desktop', 'Laptop', 'VDI', 'Server'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Region

The region of the application install, if the install is region is specific.
This is generally only needed if you are creating multiple editions of the OpRule for different regions.
This is used in the OpRule Name and OpRule Marker
Allowable values are: 'DEV', 'MOD', 'PROD'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Edition

The edition of the application install, if the install is edition is specific.
This is generally only needed if you are creating multiple editions of the OpRule for different editions.
This is used in the OpRule Name and OpRule Marker

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PackagesToAdd

The packages to add to the OpRule that install the application.
These will be placed between the two version checker execute program steps

```yaml
Type: Package[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
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

### Int

### String

### BCMAPI.Object.OpRuleFolder

### BCMAPI.Object.Package.CustomPackage

## OUTPUTS

### OpRule

## NOTES

## RELATED LINKS
