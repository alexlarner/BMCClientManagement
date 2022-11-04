<#
	.NOTES
		Update Log
		##########################
		05.09.2022 - Alex Larner - Replaced employer specific info with $CompanyName
#>
@{

	# Script module or binary module file associated with this manifest
	ModuleToProcess	= 'BMC_API_PowerShell_Core.psm1'

	# Version number of this module.
	ModuleVersion = '3.1.0.0'

	# ID used to uniquely identify this module
	GUID = '2e115907-f5e2-47a9-aede-e39907485d53'

	# Author of this module
	Author = 'Alex Larner'

	# Company or vendor of this module
	CompanyName = $CompanyName

	# Copyright statement for this module
	Copyright = '(c) 2021. All rights reserved.'

	# Description of the functionality provided by this module
	Description = 'This is a module to allow PowerShell based operating of BCM'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '7.0.0'

	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = 'ConsoleHost'

	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = '7.0.0'

	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '4.7'

	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = '2.0.50727'

	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture = 'None'

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to
	# importing this module
	ScriptsToProcess = @('Import_VMwareModulesforVMBuilding.ps1')

	# Type files (.ps1xml) to be loaded when importing this module
	TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in
	# ModuleToProcess
	NestedModules = @()

	# Functions to export from this module
	FunctionsToExport	   = @(
		'Add-CheckforFileStep',
		'Add-CheckforStringinFileStep',
		'Add-DeleteDirectoryStep',
		'Add-DeviceGrouptoOpRule',
		'Add-DevicetoADGroup',
		'Add-DevicetoDeviceGroup',
		'Add-DevicetoOpRule',
		'Add-ExecuteProgramStep',
		'Add-OpRuleMarkerSteps',
		'Add-PackagetoOpRule',
		'Add-RegistryKeyVerificationStep',
		'Add-RegistryManagementStep',
		'Add-SteptoOpRule',
		'Add-UniversalVersionCheckerStep',
		'Build-FactoryDevice',
		'Build-VM',
		'Expand-ArchivedFile',
		'Get-BCMCommonObject',
		'Get-BCMFrontEndText',
		'Get-BCMID',
		'Get-BCMObjectInstance',
		'Get-BCMObjectInstanceAttribute',
		'Get-BCMObjectType',
		'Get-BCMObjectTypeAttribute',
		'Get-BCMPackage',
		'Get-BCMPackageArchive',
		'Get-BCMPackageXML',
		'Get-BMCErrorCodeText',
		'Get-Device',
		'Get-DeviceFactoryRunSummary',
		'Get-DeviceGroup',
		'Get-DeviceGroupAssignedtoOpRule',
		'Get-DeviceGroupDevices',
		'Get-DeviceID',
		'Get-Enums',
		'Get-LatestVMName',
		'Get-LifeCycleStatus',
		'Get-OpRule',
		'Get-OpRuleAssignment',
		'Get-OpRulePackages',
		'Get-OpRuleStep',
		'Get-StepType',
		'Get-StepTypeParameter',
		'New-FactoryRunReport',
		'New-OpRule',
		'New-StandardOpRule',
		'New-StepParameter',
		'Remove-DeprecatedDeviceFromOpRule',
		'Remove-DevicefromDeviceGroup',
		'Remove-DevicefromFactoryDeviceGroups',
		'Remove-DeviceGroupfromOpRule',
		'Remove-OpRuleAssignment',
		'Replace-OpRuleinDeviceGroup',
		'Send-FactoryAlert',
		'Test-FactoryBuildType',
		'Update-CMDBStatus',
		'Update-LifeCycleStatus',
		'Update-ObjectInstanceAttribute',
		'Update-OpRuleAssignmentStatus',
		'Update-OpRuleDeviceGroupAssignment',
		'Update-OpRuleStepResultCondition',
		'Use-BCMRestAPI',
		'Wait-Computer',
		'Wait-OpRuleAssignment',
		'Write-Log'
	) #For performance, list functions explicitly

	# Cmdlets to export from this module
	CmdletsToExport = '*'

	# Variables to export from this module
	VariablesToExport = '*'

	# Aliases to export from this module
	AliasesToExport = '*' #For performance, list alias explicitly

	# DSC class resources to export from this module.
	#DSCResourcesToExport = ''

	# List of all modules packaged with this module
	ModuleList = @()

	# List of all files packaged with this module
	FileList = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			# ProjectUri = ''

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}