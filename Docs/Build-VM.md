---
external help file: BMC_API_PowerShell_Core-help.xml
Module Name: BMC_API_PowerShell_Core
online version:
schema: 2.0.0
---

# Build-VM

## SYNOPSIS

Creates a VM based on the details in a CSV

## SYNTAX

```text
Build-VM [-FactoryBuildTemplate] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

Builds a VM using the settings in a CSV
Adds the 'smbios.assettag'
Adds the correct network adapter
Starts the VM

## EXAMPLES

### Example 1

```PowerShell
Build-VM -FactoryBuildTemplate "$ITNetworkShare\AutomatedFactory\Logs\VM Build CSVs\VMBuild_2020-02-04__17-31-22_amfap0p.csv"
```

## PARAMETERS

### -FactoryBuildTemplate

This must be a CSV that contains these columns:
DeviceName (The name of the new device)
Folder (The folder for the new VMs to be created in, i.e.
'Factory')
VMHost (The full host name, including ".$CompanyDomainName")
Datastore (The datastore to create the new device on, i.e.
'vdihost7002a-ilio-f1')
vCenter (The vCenter to create the VM on, i.e.
'vdvcentervd001a')
Network (The network for the VM's network adapter, i.e.
$NewVMNetworkAdapterName)
Template (The VM template to create the new VMs off of, i.e.
$AlmostVanillaOSVMTemplateName)

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

## OUTPUTS

## NOTES

## RELATED LINKS
