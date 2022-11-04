#Requires -Version 7

<#
	.SYNOPSIS
		This is a module to allow PowerShell based operating of BCM

	.DESCRIPTION
		This connects to both BCM and vSphere

	.PARAMETER BMCEnvironment
		The BCM Environment to use
		Allowable values are: 'PROD', 'DEV', 'QA', 'BETA'

	.PARAMETER ADUsername
		The username to use for BCM & vSphere

	.PARAMETER EncryptedCredentialsPath
		The path to a txt file containing the encrypted AD password for the account given in ADUsername

	.PARAMETER vCenterstoConnectTo
		The grouping of vCenters to connect to.
		Allowable values are: 'All', 'DEV', 'Factory and Hot Pool', 'PROD', 'Support Clusters'

	.NOTES
		################
		Version History
		################
		05.08.2019 - Alex Larner
					- Updated Get-Root Packages to error out if null
					- Updated all funtions to use cmdlet binding

		10.30.2019 - Alex Larner - Updated Device, DeviceGroup, OpRule, and OpRuleFolder constructors to contain a string constructor that uses Get-BCMCommonObject, so OpRules with those classes can use strings as input (i.e. Add-DeviceToOpRule)
		11.14.2019 - Alex Larner - Updated Update-CMDBStatus
		02.26.2020 - Alex Larner - Updated ObjectType and StepType classes with string constructors
		02.28.2020 - Alex Larner - Updated functions that used WildcardSearch or Operator parameters, to detect the wildcard/contains search internally
		12.28.2020 - Alex Larner - Updated Build-FactoryDevice to prevent the normal 2 retries on OpRule assignments over their max runtime and with a status of Update Sent
		01.19.2021 - Alex Larner - See below:
									- Updated Remove-OpRuleAssignment to include an activation parameter, set that parameter to automatic by default, as the BCM API now uses manual as the default, though they did not update their documentation to say so
									- Updated Build-FactoryDevice to set the Lifecycle status of successful machines to "Build_Patch" if the command was run in PROD BCM and without the NovSphere switch
									- Created Get-DeviceFactoryRunSummary to find and parse factory logs for a device
									- Created Update-OpRuleDeviceGroupAssignment to update the setting of device group OpRule assignments
		04.30.2021 - Alex Larner - Added Rosh Kiran Gunakala to the default recipients of the Send-FactoryAlert alerts
		05.09.2022 - Alex Larner - Replaced employer specific info with these undefined variabes:
			$ITNetworkShare
			$DomainNickname
			$CompanyDomainName
			$ShortCompanyName
			$ITDepartmentName
			$RootDomain
			$APIServiceAccountName
			$ITSystemsEngineerUsernames
			$MainUsersEmail
			$MainUsersManagersEmail
			$NewVMNetworkAdapterName
			$FactoryVMNameRegex
			$FactoryVMNameWildcardPrefix
			$AlmostVanillaOSVMTemplateName
			$CMDBUpdateServerName

		##########
		To Do List
		##########
		Investigate functions to see which ones will benefit from the parallel option on ForEach-Object
#>
param
(
	[Parameter(Position = 0)]
	[ValidateSet('PROD', 'DEV', 'QA', 'BETA')]
	[string]$BMCEnvironment = 'PROD',
	[Parameter(Position = 1)]
	[string]$ADUsername = $APIServiceAccountName,
	[Parameter(Position = 2)]
	[string]$EncryptedCredentialsPath = "$env:LOCALAPPDATA\AutomatedFactory_EncryptedNetworkCredentials.txt",
	[Parameter(Position = 3)]
	[ValidateSet('All', 'DEV', 'Factory and Hot Pool', 'PROD', 'Support Clusters', 'None')]
	[string]$vCentersToConnectTo = 'Factory and Hot Pool'
)

#region Classes

Write-Verbose 'Importing Classes'

class FactoryBuildAssignment
{
	# Properties
	[int]$Order
	[OpRuleAssignment]$OpRuleAssignment
	[int]$Phase
	[int]$Attempts
	[int]$MaxRuntimeInMinutes
	[DateTime]$StartTime
	[DateTime]$EndTime

	# Constructors
	FactoryBuildAssignment (
		[int]$Order,
		[OpRuleAssignment]$OpRuleAssignment,
		[int]$Phase,
		[int]$MaxRuntimeInMinutes
	)
	{
		$this.Order = $Order
		$this.OpRuleAssignment = $OpRuleAssignment
		$this.Phase = $Phase
		$this.MaxRuntimeInMinutes = $MaxRuntimeInMinutes

		Add-Member -InputObject $this -MemberType ScriptProperty -Name Duration -Value {
			if ($this.StartTime -eq (Get-Date 0)) { '' }
			else
			{
				if ($this.EndTime -eq (Get-Date 0)) { (Get-Date).ToUniversalTime() - $this.StartTime }
				else { $this.EndTime - $this.StartTime }
			}
		}
	}
}

class DeviceFactoryRun
{
	# Properties
	[Device]$Device
	[FactoryBuildAssignment[]]$FactoryBuildAssignment
	[string]$BuildType
	[int]$CurrentPosition
	[int]$MaxOpRuleRetries
	[bool]$Stopped
	[string]$LogPath

	# Constructors
	DeviceFactoryRun (
		[Device]$Device,
		[string]$BuildType,
		[int]$CurrentPosition,
		[int]$MaxOpRuleRetries
	)
	{
		$this.Device = $Device
		$this.BuildType = $BuildType
		$this.CurrentPosition = $CurrentPosition
		$this.MaxOpRuleRetries = $MaxOpRuleRetries
		$this.LogPath = "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Device Factory Run Summary CSVs\$($Device.Name)`_$BuildType`_FactoryRun_$env:USERNAME`_$(Get-Date -Format 'yyyy-MM-dd__HH-mm-ss').csv"


		#I'm only mostly sure that this will be dynamic so that it can pick up on the status changes of the current assignment
		Add-Member -InputObject $this -MemberType ScriptProperty -Name CurrentAssignment -Value { $This.FactoryBuildAssignment | Where-Object Order -EQ $This.CurrentPosition }

		Add-Member -InputObject $this -MemberType ScriptProperty -Name CurrentPhase -Value { $this.CurrentAssignment.Phase }

		Add-Member -InputObject $this -MemberType ScriptProperty -Name NextAssignment -Value { $This.FactoryBuildAssignment | Where-Object Order -EQ ($This.CurrentPosition + 1) }

		Add-Member -InputObject $this -MemberType ScriptProperty -Name NextAssignmentinNewPhase -Value {
			if ($this.NextAssignment.Phase -ne $this.CurrentAssignment.Phase) { $true }
			else { $false }
		}

		Add-Member -InputObject $this -MemberType ScriptProperty -Name NonExecutedInCurrentPhase -Value {
			if (($this.FactoryBuildAssignment | Where-Object Phase -EQ $this.CurrentAssignment.Phase | Select-Object -ExpandProperty OpRuleAssignment | Select-Object -ExpandProperty Status -Unique) -ne 'Executed') { $true }
			else { $false }
		}
		Add-Member -InputObject $this -MemberType ScriptProperty -Name FailuresInCurrentPhase -Value {
			if (($this.FactoryBuildAssignment | Where-Object Phase -EQ $this.CurrentAssignment.Phase | Select-Object -ExpandProperty OpRuleAssignment | Select-Object -ExpandProperty Status -Unique) -contains 'Execution Failed') { $true }
			else { $false }
		}
	}

	# Methods

	GoToNextAssignment ()
	{
		$this.CurrentPosition++
	}
}

#region Non-Factory Classes
class BCMAPI
{
	# Properties
	[int]$ID
}

class ObjectType: bcmapi
{
	#Properties
	[string]$FrontEndName
	[string]$FrontEndClass
	[string]$ParentType
	[bool]$AvailableForSearch
	[bool]$AvailableForQuery
	[bool]$IsGroup
	[bool]$CheckSecurity
	[string]$SmallIcon
	[string]$LargeIcon
	[string]$Name
	[string]$FormattedName
	[string]$Class


	#Constructors
	ObjectType ([pscustomobject]$Result)
	{
		Write-Debug "Converting $($Result.Name) to a ObjectType class object"
		$This.ID = $Result.ID
		$This.Name = $Result.Name
		$This.FrontEndName = Get-BCMFrontEndText $This.Name -TranslationOnly
		$This.FormattedName = "$($This.FrontEndName) (ID: $($This.ID))"
		$This.Class = $Result.Class
		$This.FrontEndClass = Get-BCMFrontEndText $This.Class -TranslationOnly
		$This.SmallIcon = $Result.SmallIcon
		$This.LargeIcon = $Result.LargeIcon
		$This.ParentType = $Result.ParentType
		$This.AvailableForSearch = $Result.AvailableForSearch
		$This.AvailableForQuery = $Result.AvailableForQuery
		$This.IsGroup = $Result.IsGroup
		$This.CheckSecurity = $Result.CheckSecurity
	}

	ObjectType ([string]$ObjectTypeName)
	{
		$BCMCObject = Get-BCMObjectType -Name $ObjectTypeName
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}
}

class ObjectTypeAttribute: bcmapi
{
	#Properties
	[string]$FrontEndName
	[string]$Column
	[string]$Type
	[string]$EnumName
	[string]$Units
	[string]$ValueCheckRegex
	[bool]$ReadOnly
	[int]$DisplayOrder
	[bool]$DisplayInList
	[bool]$NeedTranslation
	[string]$Name
	[string]$FormattedName

	#Constructors
	ObjectTypeAttribute ([pscustomobject]$Result)
	{
		Write-Debug "Converting $($Result.Name) to a ObjectTypeAttribute class object"
		$This.ID = $Result.ID
		$This.Name = $Result.Name
		$This.FrontEndName = Get-BCMFrontEndText $This.Name -TranslationOnly
		$This.FormattedName = "$($This.FrontEndName) (ID: $($This.ID))"
		$This.Column = $Result.Column
		$This.Type = $Result.Type
		$This.EnumName = $Result.EnumName
		$This.Units = $Result.Units
		$This.ReadOnly = $Result.ReadOnly
		$This.DisplayOrder = $Result.DisplayOrder
		$This.DisplayInList = $Result.DisplayInList
		$This.NeedTranslation = $Result.NeedTranslation
		$This.ValueCheckRegex = $Result.ValueCheckRegex
	}
}

class StepType: bcmapi
{
	# Properties
	[string]$FrontEndName
	[string]$FrontEndClass
	[string]$FrontEndNotes
	[string]$Notes
	[string]$Name
	[string]$Class
	[string]$FormattedName
	[string]$FrontEndFormattedName

	#Constructors
	StepType ([pscustomobject]$Result)
	{
		$This.ID = $Result.ID
		$This.Name = $Result.Name
		$This.Class = $Result.Class
		$This.Notes = $Result.Notes
		$This.FrontEndName = Get-BCMFrontEndText $This.Name -TranslationOnly
		$This.FrontEndClass = Get-BCMFrontEndText $This.Class -TranslationOnly
		$This.FrontEndNotes = Get-BCMFrontEndText $This.Notes -TranslationOnly
		$This.FormattedName = "$($This.Name) (ID: $($This.ID))"
		$This.FrontEndFormattedName = "$($This.FrontEndName) (ID: $($This.ID))"
	}

	StepType ([string]$StepTypeName)
	{
		$BCMCObject = Get-StepType -Name $StepTypeName
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}
}

class StepTypeParameter: bcmapi
{
	# Properties
	[string]$FrontEndName
	[string]$Type
	[string]$FrontEndLabel
	[string]$Name
	[string]$Label
	[string]$FormattedName
	[string]$FormattedFrontEndName

	#Constructors
	StepTypeParameter ([pscustomobject]$Result)
	{
		$This.ID = $Result.ID
		$This.Label = $Result.Label
		$This.FrontEndLabel = Get-BCMFrontEndText $Result.Label -TranslationOnly
		$This.Name = $Result.Name
		$This.FormattedName = "$($this.Name) ($($this.ID))"
		$This.FrontEndName = Get-BCMFrontEndText $Result.Name -TranslationOnly
		$This.FormattedFrontEndName = "$($this.FrontEndName) ($($this.ID))"
		$This.Type = $Result.Type
	}
}

class StepParameter: bcmapi
{
	# Properties
	[string]$FrontEndName
	[string]$Type
	[string]$FrontEndLabel
	$Value
	[string]$Name
	[string]$Label
	[string]$FormattedName
	[string]$FormattedFrontEndName


	#Constructors
	StepParameter ([pscustomobject]$Result)
	{
		$This.ID = $Result.ID
		$This.Label = $Result.Label
		$This.FrontEndLabel = Get-BCMFrontEndText $Result.Label -TranslationOnly
		$This.Name = $Result.Name
		$This.FormattedName = "$($this.Name) ($($this.ID))"
		$This.FrontEndName = Get-BCMFrontEndText $Result.Name -TranslationOnly
		$This.FormattedFrontEndName = "$($this.FrontEndName) ($($this.ID))"
		$This.Type = $Result.Type
		$This.Value = $Result.Value
	}

	StepParameter ([StepTypeParameter]$STP, $Value)
	{
		$This.ID = $STP.ID
		$This.Label = $STP.Label
		$This.FrontEndLabel = $STP.FrontEndLabel
		$This.Name = $STP.Name
		$This.FormattedName = $STP.FormattedName
		$This.FrontEndName = $STP.FrontEndName
		$This.FormattedFrontEndName = $STP.FormattedFrontEndName
		$This.Type = $STP.Type
		$This.Value = $Value
	}
}

class Step: bcmapi
{
	# Properties
	[string]$FrontEndName
	[string]$Name
	[StepParameter[]]$Parameters

	# Constructors
	Step ([int]$ID, [string]$Name, [PSCustomObject]$RawParams)
	{
		$This.ID = $ID
		$this.Name = $Name
		$this.FrontEndName = Get-BCMFrontEndText $Name -TranslationOnly
		$This.Parameters = $RawParams | ForEach-Object { [StepParameter]::New($_) }
	}

	# Methods
}

class StepAssignment: bcmapi
{
	# Properties
	[int]$StepNumber
	[bool]$Activated
	[string]$SuccessCondition
	[int]$GoToStepOnSuccess
	[string]$StopCondition
	[int]$GoToStepOnFail
	[string]$VerificationCondition
	[string]$Notes
	[string]$CreatedBy
	[DateTime]$CreatedTime
	[string]$LastModifiedBy
	[DateTime]$LastModifiedTime
	[Step]$Step
	[OpRule]$OpRule

	# Constructors
	StepAssignment ([int]$ID, [OpRule]$OpRule)
	{
		$ObjectInstance = Get-BCMObjectInstanceAttribute -InstanceID $ID -ObjectType _DB_OBJECTTYPE_OPERATIONALSTEP_
		$Result = (Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/step/assignment/$ID").Assignment

		$this.ID = $ID
		$this.Activated = $ObjectInstance._DB_ATTR_ISACTIVE_
		$this.CreatedBy = $ObjectInstance._DB_ATTR_CREATEDBY_
		if ($ObjectInstance._DB_ATTR_CREATETIME_ -ne '') { $this.CreatedTime = $ObjectInstance._DB_ATTR_CREATETIME_ }
		$this.GoToStepOnFail = $ObjectInstance._DB_ATTR_OPSTEP_GOTOFAILSTEP_
		$this.GoToStepOnSuccess = $ObjectInstance._DB_ATTR_OPSTEP_GOTOSUCCESSSTEP_
		$this.LastModifiedBy = $ObjectInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($ObjectInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $this.LastModifiedTime = $ObjectInstance._DB_ATTR_LASTMODIFYTIME_ }
		$this.Notes = $ObjectInstance._DB_ATTR_NOTES_
		$this.OpRule = $OpRule
		$this.Step = [Step]::New($Result.Step.ID, $ObjectInstance._DB_ATTR_OPSTEP_TYPE_, $Result.Step.Params)
		$this.StepNumber = $ObjectInstance._DB_ATTR_OPSTEP_NUMBER_
		$this.StopCondition = Get-BCMFrontEndText $ObjectInstance._DB_ATTR_OPSTEP_STOPONERROR_ -TranslationOnly
		$this.SuccessCondition = Get-BCMFrontEndText $ObjectInstance._DB_ATTR_OPSTEP_STEPACTIONSUCCESS_ -TranslationOnly
		$this.VerificationCondition = Get-BCMFrontEndText $ObjectInstance._DB_ATTR_OPSTEP_VERIFCONDITION_ -TranslationOnly
	}
	# Methods
}

class Device: bcmapi
{
	#Properties
	[string]$Name
	[string]$PrimaryUser
	[string]$User
	[IPAddress]$IPAddress
	[System.Net.NetworkInformation.PhysicalAddress]$MACAddress
	[string]$OperatingSystemName
	[string]$LifeCycleStatus
	[string]$DirectoryServerEntryDN
	[string]$Parent
	[string]$AgentBuild
	[int]$AgentRevision
	[int]$AgentVersionMajor
	[int]$AgentVersionMinor
	[bool]$AssetDiscoveryScanner
	[string]$CreatedBy
	[DateTime]$CreateTime
	[string]$CurrentLargeIcon
	[string]$Deprecatedby
	[string]$DirectGroupMember
	[string]$DirectorIndirectGroupMember
	[bool]$DirectoryServerProxy
	[string]$DiscoveredBy
	[DateTime]$DiscoveryDate
	[string]$DiskSerialNumber
	[string]$DomainName
	[string]$FAMAssetTag
	[string]$FormattedName
	[string]$GUID
	[string]$HostID
	[string]$Hostsahypervisor
	[int]$HTTPConsolePort
	[int]$HTTPPort
	[string]$HypervisorVersion
	[string]$Icon
	[int]$ID
	[bool]$IntelVProAvailable
	[DateTime]$LastModificationTime
	[string]$LastModifiedBy
	[DateTime]$LastUpdate
	[string]$Location
	[string]$LocationName
	[bool]$MobileDeviceManager
	[string]$NetBIOSName
	[IPAddress]$NetworkName
	[string]$Notes
	[string]$OperatingSystemBuild
	[string]$OperatingSystemRevision
	[int]$OperatingSystemVersionMajor
	[int]$OperatingSystemVersionMinor
	[bool]$OSDManager
	[bool]$Packager
	[Version]$PatchKnowledgeBaseVersion
	[bool]$PatchManager
	[bool]$RestrictDeviceTypeUpdate
	[bool]$RolloutServer
	[string]$RoomLocation
	[string]$SecureCommunication
	[string]$Site
	[string]$SubnetMask
	[string]$TopologyType
	[string]$Type
	[bool]$UnderNAT
	[string]$Virtualizedon
	[bool]$WebService

	# Constructors
	Device ([int]$ID)
	{
		$DeviceInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_DEVICE_ -InstanceID $ID -TranslateBackendNames $false
		$DeviceFinancialInfo = Use-BCMRestAPI "/device/$ID/financial"

		$This.AgentBuild = $DeviceInstance._DB_ATTR_DEV_AGENTBUILD_
		$This.AgentRevision = $DeviceInstance._DB_ATTR_DEV_AGENTREVISION_
		$This.AgentVersionMajor = $DeviceInstance._DB_ATTR_DEV_AGENTVERMAJOR_
		$This.AgentVersionMinor = $DeviceInstance._DB_ATTR_DEV_AGENTVERMINOR_
		$This.AssetDiscoveryScanner = $DeviceInstance._DB_ATTR_RISCANNER_
		$This.CreatedBy = $DeviceInstance._DB_ATTR_CREATEDBY_
		if ($DeviceInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreateTime = $DeviceInstance._DB_ATTR_CREATETIME_ }
		$This.CurrentLargeIcon = $DeviceInstance._DB_ATTR_LARGEICON_
		$This.Deprecatedby = $DeviceInstance._DB_ATTR_DEV_RETIREDBY_
		$This.DirectGroupMember = $DeviceInstance._DB_ATTR_DIRECTMEMBER_
		$This.DirectorIndirectGroupMember = $DeviceInstance._DB_ATTR_DIRECTINDIRECTMEMBER_
		$This.DirectoryServerEntryDN = $DeviceInstance._DB_ATTR_ENTRYDN_
		$This.DirectoryServerProxy = $DeviceInstance._DB_ATTR_DIRECTORYSERVERPROXY_
		$This.DiscoveredBy = $DeviceInstance._DB_ATTR_DISCOVEREDBY_
		if ($DeviceInstance._DB_ATTR_SCANTIME_ -ne '') { $This.DiscoveryDate = $DeviceInstance._DB_ATTR_SCANTIME_ }
		$This.DiskSerialNumber = $DeviceInstance._DB_ATTR_DEVICE_DISKSERNUM_
		$This.DomainName = $DeviceInstance._DB_ATTR_DEV_DOMAINNAME_
		$This.FAMAssetTag = $DeviceInstance._DB_ATTR_DEVICE_FAMASSETTAG_
		$This.FormattedName = "$($DeviceInstance._DB_ATTR_NAME_) (ID: $($DeviceInstance.DeviceID))"
		$This.GUID = $DeviceInstance._DB_ATTR_DEV_GUID_
		$This.HostID = $DeviceInstance._DB_ATTR_DEVICE_HOSTID_
		$This.Hostsahypervisor = $DeviceInstance._DB_ATTR_HYPERVISORVENDOR_
		$This.HTTPConsolePort = $DeviceInstance._DB_ATTR_DEV_HTTPCONSOLEPORT_
		$This.HTTPPort = $DeviceInstance._DB_ATTR_DEV_HTTPPORT_
		$This.HypervisorVersion = $DeviceInstance._DB_ATTR_HYPERVISORVERSION_
		$This.Icon = $DeviceInstance._DB_ATTR_SMALLICON_
		$This.ID = $DeviceInstance.DeviceID
		$This.IntelVProAvailable = $DeviceInstance._DB_ATTR_VPROAVAILABLE_
		if ($DeviceInstance._DB_ATTR_DEVICE_IPADDRESS_ -ne '') { $This.IPAddress = $DeviceInstance._DB_ATTR_DEVICE_IPADDRESS_ }
		if ($DeviceInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModificationTime = $DeviceInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.LastModifiedBy = $DeviceInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($DeviceInstance._DB_ATTR_DEV_UPDATETIME_ -ne '') { $This.LastUpdate = $DeviceInstance._DB_ATTR_DEV_UPDATETIME_ }
		$This.LifeCycleStatus = $DeviceFinancialInfo.LifeCycleStatus
		$This.Location = $DeviceInstance.FAMLocation
		$This.LocationName = $DeviceInstance.'Location Name'
		if ($DeviceInstance._DB_ATTR_DEVICE_MACADDRESS_ -ne '') { $This.MACAddress = [PhysicalAddress]::Parse($DeviceInstance._DB_ATTR_DEVICE_MACADDRESS_.Replace(':', '')) }
		$This.MobileDeviceManager = $DeviceInstance._DB_ATTR_MOBILEPROXY_
		$This.Name = $DeviceInstance._DB_ATTR_NAME_
		$This.NetBIOSName = $DeviceInstance._DB_ATTR_DEVICE_NETBIOSNAME_
		if ($DeviceInstance._DB_ATTR_DEV_NETWORKNAME_ -ne '') { $This.NetworkName = $DeviceInstance._DB_ATTR_DEV_NETWORKNAME_ }
		$This.Notes = $DeviceInstance._DB_ATTR_NOTES_
		$This.OperatingSystemBuild = $DeviceInstance._DB_ATTR_DEV_OSBUILD_
		$This.OperatingSystemName = $DeviceInstance._DB_ATTR_DEV_OSNAME_
		$This.OperatingSystemRevision = $DeviceInstance._DB_ATTR_DEV_OSREVISION_
		$This.OperatingSystemVersionMajor = $DeviceInstance._DB_ATTR_DEV_OSVERMAJOR_
		$This.OperatingSystemVersionMinor = $DeviceInstance._DB_ATTR_DEV_OSVERMINOR_
		$This.OSDManager = $DeviceInstance._DB_ATTR_OSD_
		$This.Packager = $DeviceInstance._DB_ATTR_PKGFACTORY_
		if ($DeviceInstance._DB_ATTR_PARENT_ -ne '') { $This.Parent = Get-BCMFrontEndText $DeviceInstance._DB_ATTR_PARENT_ -TranslationOnly }
		if ($DeviceInstance._DB_ATTR_PATCHCONFIGFILEVERSION_ -ne '') { $This.PatchKnowledgeBaseVersion = $DeviceInstance._DB_ATTR_PATCHCONFIGFILEVERSION_ }
		$This.PatchManager = $DeviceInstance._DB_ATTR_PATCHPROXY_
		$This.PrimaryUser = $DeviceInstance._DB_ATTR_DEVICE_PRIMARYUSER_
		$This.RestrictDeviceTypeUpdate = $DeviceInstance._DB_ATTR_RESTRICTDEVICETYPEUPDATE_
		$This.RolloutServer = $DeviceInstance._DB_ATTR_ROLLOUTSRV_
		$This.RoomLocation = $DeviceInstance.'Room Location'
		$This.SecureCommunication = Get-BCMFrontEndText $DeviceInstance._DB_ATTR_DEV_SSL_ -TranslationOnly
		$This.Site = $DeviceInstance.Site
		$This.SubnetMask = $DeviceInstance._DB_ATTR_DEVICE_NETWORKMASK_
		$This.TopologyType = Get-BCMFrontEndText $DeviceInstance._DB_ATTR_DEVICE_TOPOLOGYTYPE_ -TranslationOnly
		$This.Type = $DeviceInstance._DB_ATTR_DEV_TYPE_
		$This.UnderNAT = $DeviceInstance._DB_ATTR_DEVICE_UNDERNAT_
		$This.User = $DeviceInstance.UserName
		$This.Virtualizedon = $DeviceInstance._DB_ATTR_VIMVENDOR_
		$This.WebService = $DeviceInstance._DB_ATTR_RESTROLE_
	}

	Device ([string]$DeviceName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $DeviceName -ObjectType Device
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}

	# Methods
	[OpRuleAssignment] AddtoOpRule([OpRule]$OpRule, [bool]$Active)
	{
		if ($Active) { return (Add-DevicetoOpRule -Device $This -OpRule $OpRule -Active) }
		else { return (Add-DevicetoOpRule -Device $This -OpRule $OpRule) }
	}

	AddtoDeviceGroup([DeviceGroup]$DeviceGroup)
	{
		Add-DevicetoDeviceGroup -Device $this -DeviceGroup $DeviceGroup
	}

	RemoveFromDeviceGroup([DeviceGroup]$DeviceGroup)
	{
		Remove-DevicefromDeviceGroup -Device $this -DeviceGroup $DeviceGroup
	}
}

Update-TypeData -TypeName Device -DefaultDisplayPropertySet ID, Name, IPAddress, LifeCycleStatus

class Object: bcmapi
{
	# Properties
	[string]$Name
	[string]$Notes
	[string]$CreatedBy
	[DateTime]$CreatedTime
	[string]$LastModifiedBy
	[DateTime]$LastModifiedTime
	[string]$CurrentLargeIcon
	[string]$Icon
	[string]$FormattedName
}

class OpRuleFolder: object
{
	OpRuleFolder ([int]$ID)
	{
		$OpRuleFolderObjectInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_OPERATIONALRULEFOLDER_ -InstanceID $ID -TranslateBackendNames $false

		$This.ID = $ID
		$This.Name = $OpRuleFolderObjectInstance._DB_ATTR_NAME_
		$This.CurrentLargeIcon = $OpRuleFolderObjectInstance._DB_ATTR_LARGEICON_
		$This.Icon = $OpRuleFolderObjectInstance._DB_ATTR_SMALLICON_
		$This.CreatedBy = $OpRuleFolderObjectInstance._DB_ATTR_CREATEDBY_
		if ($OpRuleFolderObjectInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreatedTime = $OpRuleFolderObjectInstance._DB_ATTR_CREATETIME_ }
		$This.LastModifiedBy = $OpRuleFolderObjectInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($OpRuleFolderObjectInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModifiedTime = $OpRuleFolderObjectInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.Notes = $OpRuleFolderObjectInstance._DB_ATTR_NOTES_
		$This.FormattedName = "$($This.Name) (ID: $ID)"
	}

	OpRuleFolder ([string]$FolderName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $FolderName -ObjectType 'Operational Rule Folder'
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}
}

Update-TypeData -TypeName OpRuleFolder -DefaultDisplayPropertySet ID, Name, CreatedTime, LastModifiedTime

class OpRule: object
{
	# Properties
	[string]$Type
	[string]$MyAppsIcon
	[string]$URL
	[string]$DeploymentFromExternalIntegration
	[string]$KioskIcon

	# Constructors
	OpRule ([int]$ID)
	{
		$ObjectTypeInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_OPERATIONALRULE_ -InstanceID $ID -TranslateBackendNames $false
		$OpRuleDetails = (Use-BCMRestAPI "/oprule/rule/$ID").Rule
		$This.ID = $ID
		$This.Name = $ObjectTypeInstance._DB_ATTR_NAME_
		$This.MyAppsIcon = $ObjectTypeInstance._DB_ATTR_KIOSKICON_
		$This.URL = $ObjectTypeInstance._DB_ATTR_OPRULE_URL_
		$This.Type = $OpRuleDetails.Type
		$This.DeploymentFromExternalIntegration = $OpRuleDetails.DeploymentFromExternalIntegration
		$This.CurrentLargeIcon = $ObjectTypeInstance._DB_ATTR_LARGEICON_
		$This.Icon = $ObjectTypeInstance._DB_ATTR_SMALLICON_
		$This.CreatedBy = $ObjectTypeInstance._DB_ATTR_CREATEDBY_
		if ($ObjectTypeInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreatedTime = $ObjectTypeInstance._DB_ATTR_CREATETIME_ }
		$This.LastModifiedBy = $ObjectTypeInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModifiedTime = $ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.Notes = $ObjectTypeInstance._DB_ATTR_NOTES_
		$This.FormattedName = "$($This.Name) (ID: $ID)"
	}

	OpRule ([string]$OpRuleName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $OpRuleName -ObjectType 'Operational Rule'
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}

	# Methods
	[OpRuleDeviceGroupAssignment[]] GetDeviceGroupAssignments()
	{
		return (Get-DeviceGroupAssignedtoOpRule -OpRule $This)
	}

	[DeviceGroup[]] GetAssignedDeviceGroups ()
	{
		return (Get-DeviceGroupAssignedtoOpRule -OpRule $This -DeviceGroupsOnly)
	}

	[OpRuleAssignment[]] GetDeviceAssignments ()
	{
		return (Get-OpRuleAssignment -OpRule $This)
	}
}

Update-TypeData -TypeName OpRule -DefaultDisplayPropertySet ID, Name, CreatedTime, LastModifiedTime

class Assignment: bcmapi
{
	# Properties
	[string]$OpRuleName
	[string]$DeviceGroupName
	[string]$Status
	[string]$CreatedBy
	[DateTime]$CreateTime
	[DateTime]$LastModificationTime
	[string]$LastModifiedBy
	[int]$AssignEnableTime
	[bool]$AssignmentActivation
	[bool]$BypassTransferWindow
	[bool]$RunAsCurrentUser
	[bool]$RunWhileExecutionFails
	[int]$SpecialCase
	[bool]$UploadIntermediaryStatusValues
	[bool]$UploadStatusAfterEveryExecution
	[bool]$WakeupDevices
	[DeviceGroup]$DeviceGroup
	[int]$DeviceGroupID
	[bool]$InstallationType
	[OpRule]$OpRule
	[int]$ScheduleID

	#Constructors
	#Assignment () { }
}

class OpRuleAssignment: assignment
{
	# Properties
	[string]$DeviceName
	[int]$FailedStep
	[int]$ErrorCode
	[string]$ErrorDetails
	[string]$ErrorType
	[DateTime]$LastStatusUpdateTime
	[DateTime]$SendTime
	[string]$TransportMode
	[Device]$Device
	[int]$DeviceID

	# Constructors
	OpRuleAssignment ([OpRule]$OpRule, [int]$ID)
	{
		$OpRuleAssignmentInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_OPRULDEVICEASSIGNMENT_ -InstanceID $ID -TranslateBackendNames $false

		$This.ID = $ID
		if ($OpRuleAssignmentInstance.AssignEnableTime -ne '') { $This.AssignEnableTime = $OpRuleAssignmentInstance.AssignEnableTime }
		$This.AssignmentActivation = $OpRuleAssignmentInstance.IsActive
		$This.BypassTransferWindow = $OpRuleAssignmentInstance._DB_ATTR_BYPASSTRANSWINDOW_
		$This.CreatedBy = $OpRuleAssignmentInstance._DB_ATTR_CREATEDBY_
		if ($OpRuleAssignmentInstance._DB_ATTR_CREATETIME_ -ne '') {$This.CreateTime = $OpRuleAssignmentInstance._DB_ATTR_CREATETIME_}
		$This.DeviceGroupID = $OpRuleAssignmentInstance._DB_ATTR_GROUPID_
		if ($This.DeviceGroupID -ne 0) { $This.DeviceGroup = [DeviceGroup]::New($This.DeviceGroupID) }
		$This.DeviceGroupName = $This.DeviceGroup.Name
		$This.DeviceID = $OpRuleAssignmentInstance.DeviceID
		$This.Device = [Device]::New([int]$OpRuleAssignmentInstance.DeviceID)
		$This.DeviceName = $This.Device.Name
		$This.ErrorCode = $OpRuleAssignmentInstance.ErrorCode
		$This.ErrorDetails = $OpRuleAssignmentInstance.ErrorText
		$This.ErrorType = $OpRuleAssignmentInstance.ErrorType
		$This.FailedStep = $OpRuleAssignmentInstance.ErrorStepNumber
		$This.InstallationType = $OpRuleAssignmentInstance._DB_ATTR_NETWORKINSTALL_
		if ($OpRuleAssignmentInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModificationTime = $OpRuleAssignmentInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.LastModifiedBy = $OpRuleAssignmentInstance._DB_ATTR_LASTMODIFIEDBY_
		$This.OpRule = $OpRule
		$This.OpRuleName = $OpRule.Name
		$This.RunAsCurrentUser = $OpRuleAssignmentInstance._DB_ATTR_RUNASCURRENTUSER_
		$This.RunWhileExecutionFails = $OpRuleAssignmentInstance._DB_ATTR_EXECUTEWHILEFAILS_
		$This.ScheduleID = $OpRuleAssignmentInstance.ScheduleId
		if ($OpRuleAssignmentInstance._DB_ATTR_SENDTIME_ -ne '') { $This.SendTime = $OpRuleAssignmentInstance._DB_ATTR_SENDTIME_ }
		$This.SpecialCase = $OpRuleAssignmentInstance._DB_ATTR_SPECIALCASE_
		$This.Status = Get-BCMFrontEndText $OpRuleAssignmentInstance.Status -TranslationOnly
		$This.TransportMode = $OpRuleAssignmentInstance._DB_ATTR_TRANSPORTMODE_
		$This.UploadIntermediaryStatusValues = $OpRuleAssignmentInstance._DB_ATTR_UPLOADSTATUS_
		$This.UploadStatusAfterEveryExecution = $OpRuleAssignmentInstance._DB_ATTR_UPLOADSTATUSEVERYEXEC_
		$This.WakeupDevices = $OpRuleAssignmentInstance._DB_ATTR_WAKEUPDEVICES_
		if ($OpRuleAssignmentInstance._DB_ATTR_LASTSTATUSUPDATE_ -ne '') { $This.LastStatusUpdateTime = $OpRuleAssignmentInstance._DB_ATTR_LASTSTATUSUPDATE_ }
	}
	# Methods

	[OpRuleAssignment] RefreshStatus()
	{
		Write-Verbose "Getting Assignment Status for $($this.OpRule.FormattedName) on $($this.Device.FormattedName)"
		$OpRuleAssignmentInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_OPRULDEVICEASSIGNMENT_ -InstanceID $This.ID -TranslateBackendNames $false

		$This.Status = Get-BCMFrontEndText $OpRuleAssignmentInstance.Status -TranslationOnly
		return $this
	}

	[OpRuleAssignment] UpdateStatus([string]$NewStatus)
	{
		Update-OpRuleAssignmentStatus -Assignment $this -NewStatus $NewStatus | Out-Null
		return $this
	}

	[OpRuleAssignment] Reassign()
	{
		Update-OpRuleAssignmentStatus -Assignment $this -NewStatus 'Reassignment Waiting' | Out-Null
		return $this
	}

	[OpRuleAssignment] RefreshAllProperties()
	{
		$OpRuleAssignmentInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_OPRULDEVICEASSIGNMENT_ -InstanceID $This.ID -TranslateBackendNames $false

		if ($OpRuleAssignmentInstance.AssignEnableTime -ne '') { $This.AssignEnableTime = $OpRuleAssignmentInstance.AssignEnableTime }
		$This.AssignmentActivation = $OpRuleAssignmentInstance.IsActive
		$This.BypassTransferWindow = $OpRuleAssignmentInstance._DB_ATTR_BYPASSTRANSWINDOW_
		$This.CreatedBy = $OpRuleAssignmentInstance._DB_ATTR_CREATEDBY_
		$This.CreateTime = $OpRuleAssignmentInstance._DB_ATTR_CREATETIME_
		$This.DeviceGroupID = $OpRuleAssignmentInstance._DB_ATTR_GROUPID_
		if ($This.DeviceGroupID -ne 0) { $This.DeviceGroup = [DeviceGroup]::New($This.DeviceGroupID) }
		$This.DeviceGroupName = $This.DeviceGroup.Name
		$This.DeviceID = $OpRuleAssignmentInstance.DeviceID
		$This.Device = [Device]::New([int]$OpRuleAssignmentInstance.DeviceID)
		$This.DeviceName = $This.Device.Name
		$This.ErrorCode = $OpRuleAssignmentInstance.ErrorCode
		$This.ErrorDetails = $OpRuleAssignmentInstance.ErrorText
		$This.ErrorType = $OpRuleAssignmentInstance.ErrorType
		$This.FailedStep = $OpRuleAssignmentInstance.ErrorStepNumber
		$This.InstallationType = $OpRuleAssignmentInstance._DB_ATTR_NETWORKINSTALL_
		if ($OpRuleAssignmentInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModificationTime = $OpRuleAssignmentInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.LastModifiedBy = $OpRuleAssignmentInstance._DB_ATTR_LASTMODIFIEDBY_
		$This.RunAsCurrentUser = $OpRuleAssignmentInstance._DB_ATTR_RUNASCURRENTUSER_
		$This.RunWhileExecutionFails = $OpRuleAssignmentInstance._DB_ATTR_EXECUTEWHILEFAILS_
		$This.ScheduleID = $OpRuleAssignmentInstance.ScheduleId
		if ($OpRuleAssignmentInstance._DB_ATTR_SENDTIME_ -ne '') { $This.SendTime = $OpRuleAssignmentInstance._DB_ATTR_SENDTIME_ }
		$This.SpecialCase = $OpRuleAssignmentInstance._DB_ATTR_SPECIALCASE_
		$This.Status = Get-BCMFrontEndText $OpRuleAssignmentInstance.Status -TranslationOnly
		$This.TransportMode = $OpRuleAssignmentInstance._DB_ATTR_TRANSPORTMODE_
		$This.UploadIntermediaryStatusValues = $OpRuleAssignmentInstance._DB_ATTR_UPLOADSTATUS_
		$This.UploadStatusAfterEveryExecution = $OpRuleAssignmentInstance._DB_ATTR_UPLOADSTATUSEVERYEXEC_
		$This.WakeupDevices = $OpRuleAssignmentInstance._DB_ATTR_WAKEUPDEVICES_
		if ($OpRuleAssignmentInstance._DB_ATTR_LASTSTATUSUPDATE_ -ne '') { $This.LastStatusUpdateTime = $OpRuleAssignmentInstance._DB_ATTR_LASTSTATUSUPDATE_ }

		return $this
	}
}

Update-TypeData -TypeName OpRuleAssignment -DefaultDisplayPropertySet ID, OpRuleName, DeviceName, Status

class OpRuleDeviceGroupAssignment: assignment
{
	# Properties

	#Constructors
	OpRuleDeviceGroupAssignment ([OpRule]$OpRule, [int]$ID)
	{
		$OpRuleDeviceGroupAssignmentInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_OPRULGROUPASSIGNMENT_ -InstanceID $ID -TranslateBackendNames $false

		$This.ID = $ID
		if ($OpRuleDeviceGroupAssignmentInstance.AssignEnableTime -ne '') { $This.AssignEnableTime = $OpRuleDeviceGroupAssignmentInstance.AssignEnableTime }
		$This.AssignmentActivation = $OpRuleDeviceGroupAssignmentInstance.IsActive
		$This.BypassTransferWindow = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_BYPASSTRANSWINDOW_
		$This.CreatedBy = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_CREATEDBY_
		$This.CreateTime = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_CREATETIME_
		$This.DeviceGroupID = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_GROUPID_
		$This.DeviceGroup = [DeviceGroup]::New($This.DeviceGroupID)
		$This.DeviceGroupName = $This.DeviceGroup.Name
		$This.InstallationType = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_NETWORKINSTALL_
		if ($OpRuleDeviceGroupAssignmentInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModificationTime = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.LastModifiedBy = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_LASTMODIFIEDBY_
		$This.OpRule = $OpRule
		$This.OpRuleName = $OpRule.Name
		$This.RunAsCurrentUser = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_RUNASCURRENTUSER_
		$This.RunWhileExecutionFails = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_EXECUTEWHILEFAILS_
		$This.ScheduleID = $OpRuleDeviceGroupAssignmentInstance.ScheduleId
		$This.SpecialCase = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_SPECIALCASE_
		$This.Status = Get-BCMFrontEndText $OpRuleDeviceGroupAssignmentInstance.Status -TranslationOnly
		$This.UploadIntermediaryStatusValues = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_UPLOADSTATUS_
		$This.UploadStatusAfterEveryExecution = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_UPLOADSTATUSEVERYEXEC_
		$This.WakeupDevices = $OpRuleDeviceGroupAssignmentInstance._DB_ATTR_WAKEUPDEVICES_
	}
}

Update-TypeData -TypeName OpRuleDeviceGroupAssignment -DefaultDisplayPropertySet OpRuleName, DeviceGroupName, Status, LastModificationTime

class DeviceGroup: object
{
	# Properties
	[string]$DeviceType
	[string]$DisplayNodes
	[string]$GroupEntryDN
	[int]$QueryStatus
	[string]$Operator
	[string]$Populator

	# Constructors
	DeviceGroup ([int]$ID)
	{
		$DeviceGroupObjectInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_DEVICEGROUP_ -InstanceID $ID -TranslateBackendNames $false
		$This.ID = $ID
		$This.Name = $DeviceGroupObjectInstance._DB_ATTR_NAME_
		$This.CurrentLargeIcon = $DeviceGroupObjectInstance._DB_ATTR_LARGEICON_
		$This.Icon = $DeviceGroupObjectInstance._DB_ATTR_SMALLICON_
		$This.CreatedBy = $DeviceGroupObjectInstance._DB_ATTR_CREATEDBY_
		if ($DeviceGroupObjectInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreatedTime = $DeviceGroupObjectInstance._DB_ATTR_CREATETIME_ }
		$This.LastModifiedBy = $DeviceGroupObjectInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($DeviceGroupObjectInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModifiedTime = $DeviceGroupObjectInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.Notes = $DeviceGroupObjectInstance._DB_ATTR_NOTES_
		$This.FormattedName = "$($This.Name) (ID: $ID)"
		$This.DeviceType = Get-BCMFrontEndText $DeviceGroupObjectInstance._DB_ATTR_DISPLAYMEMBERS_ -TranslationOnly
		$This.DisplayNodes = Get-BCMFrontEndText $DeviceGroupObjectInstance._DB_ATTR_DISPLAYNODES_ -TranslationOnly
		$This.GroupEntryDN = $DeviceGroupObjectInstance._DB_ATTR_GRP_ENTRYDN_
		$This.QueryStatus = $DeviceGroupObjectInstance._DB_ATTR_GRP_QUERYMEMACTIVE_
		$This.Operator = $DeviceGroupObjectInstance._DB_ATTR_GRP_QUERYOPERATOR_
		$This.Populator = $DeviceGroupObjectInstance._DB_ATTR_POPULATEBY_
	}

	DeviceGroup ([string]$DeviceGroupName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $DeviceGroupName -ObjectType 'Device Group'
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}

	# Method
	AddDevice ([Device[]]$Device)
	{
		Add-DevicetoDeviceGroup -Device $Device -DeviceGroup $this
	}

	RemoveDevice ([Device[]]$Device)
	{
		Remove-DevicefromDeviceGroup -Device $Device -DeviceGroup $this
	}

	RemoveDeprecatedDevices ()
	{
		Get-DeviceGroupDevices $this | Where-Object TopologyType -eq 'Deprecated Device' | Remove-DevicefromDeviceGroup -DeviceGroup $this
	}
}

Update-TypeData -TypeName DeviceGroup -DefaultDisplayPropertySet ID, Name, CreatedTime, LastModifiedTime

class Package: object
{
	# Properties
	[System.IO.FileInfo]$ArchiveFile
	[String]$ArchiveName
	[String]$ArchiveType
	[string]$Checksum
	[String]$CreatingDevice
	[bool]$DynamicPackage
	[int]$FileCount
	[bool]$ForceReassignment
	[GUID]$GUID
	[bool]$MappingActivated
	[int]$PackageSizeCompressedKB
	[int]$PackageSizeKB
	[String]$PackageType
	[bool]$Referenced
	[bool]$Relay
	[xml]$InstallXML

	# Constructors
	Package () { }

	Package ([int]$ID)
	{
		$ObjectTypeInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_PACKAGE_ -InstanceID $ID -TranslateBackendNames $false

		$This.ArchiveName = $ObjectTypeInstance._DB_ATTR_ARCHNAME_
		$This.ArchiveType = $ObjectTypeInstance._DB_ATTR_ARCHIVETYPE_
		$This.Checksum = $ObjectTypeInstance._DB_ATTR_PKG_CHECKSUM_
		$This.CreatedBy = $ObjectTypeInstance._DB_ATTR_CREATEDBY_
		if ($ObjectTypeInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreatedTime = $ObjectTypeInstance._DB_ATTR_CREATETIME_ }
		$This.CreatingDevice = $ObjectTypeInstance._DB_ATTR_CREATEDEVICE_
		$This.CurrentLargeIcon = $ObjectTypeInstance._DB_ATTR_LARGEICON_
		$This.DynamicPackage = $ObjectTypeInstance._DB_ATTR_PKG_ISDYNAMIC_
		$This.FileCount = $ObjectTypeInstance._DB_ATTR_PKG_NUMBEROFFILE_
		$This.ForceReassignment = $ObjectTypeInstance._DB_ATTR_PKG_FORCEREASSIGN_
		if ($This.Checksum -ne '') { $this.GUID = $This.Checksum }
		$This.Icon = $ObjectTypeInstance._DB_ATTR_SMALLICON_
		$This.ID = $ID
		$This.LastModifiedBy = $ObjectTypeInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModifiedTime = $ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.MappingActivated = $ObjectTypeInstance._DB_ATTR_PKG_ISMAPPING_
		$This.Name = $ObjectTypeInstance._DB_ATTR_NAME_
		$This.Notes = $ObjectTypeInstance._DB_ATTR_NOTES_
		$This.PackageSizeCompressedKB = $ObjectTypeInstance._DB_ATTR_PKG_SIZE_COMPRESSED_
		$This.PackageSizeKB = $ObjectTypeInstance._DB_ATTR_PKG_SIZE_
		$This.PackageType = $ObjectTypeInstance._DB_ATTR_PKG_TYPE_
		$This.Referenced = $ObjectTypeInstance._DB_ATTR_PKG_ISREFERENCE_
		$This.Relay = $ObjectTypeInstance._DB_ATTR_PKGADMINRELAY_
		$This.FormattedName = "$($This.Name) (ID: $ID)"
		$This.ArchiveFile = Get-BCMPackageArchive $This -WarningAction SilentlyContinue
		if ($This.ArchiveFile) { $This.InstallXML = Get-BCMPackageXML $This }
	}

	Package ([string]$PackageName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $PackageName -ObjectType 'Package'
		$BCMCObject.PSObject.Properties.Name | Where-Object { $_ -in $This.PSObject.Properties.Name } | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}

	# Methods
	[MSIPackage] ConvertToMSIPackageObject()
	{
		Return ([MSIPackage]::New($this))
	}

	[CustomPackage] ConvertToCustomPackageObject()
	{
		Return ([CustomPackage]::New($this))
	}

	<#
	[Package] ConvertToAdvancedPackageObject()
	{
		switch ($this.PackageType) {
			'Custom' {
				return ([CustomPackage]::New($this))
			}
			'MSI' {
				return ([MSIPackage]::New($this))
			}
			default {
				Write-Warning "$($this.PackageType) is not an allowable advanced package type (Custom, MSI)"
				return $this
			}
		}
	}
	#>
}

Update-TypeData -TypeName Package -DefaultDisplayPropertySet ID, Name, CreatedTime, LastModifiedTime

class CustomPackage: Package
{
	# Properties
	[string]$Destination
	[string]$RunCommand
	[bool]$OverwriteSystemFiles
	[bool]$OverwriteNonSystemFiles
	[bool]$OverwriteOlderFileVersions
	[bool]$OverwriteReadOnlyFiles
	[bool]$RunProgramInItsContext
	[bool]$FastInstallation
	[bool]$UseAShell

	# Constructors
	CustomPackage ([int]$ID)
	{
		$ObjectTypeInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_PACKAGE_ -InstanceID $ID -TranslateBackendNames $false

		$This.ArchiveName = $ObjectTypeInstance._DB_ATTR_ARCHNAME_
		$This.ArchiveType = $ObjectTypeInstance._DB_ATTR_ARCHIVETYPE_
		$This.Checksum = $ObjectTypeInstance._DB_ATTR_PKG_CHECKSUM_
		$This.CreatedBy = $ObjectTypeInstance._DB_ATTR_CREATEDBY_
		if ($ObjectTypeInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreatedTime = $ObjectTypeInstance._DB_ATTR_CREATETIME_ }
		$This.CreatingDevice = $ObjectTypeInstance._DB_ATTR_CREATEDEVICE_
		$This.CurrentLargeIcon = $ObjectTypeInstance._DB_ATTR_LARGEICON_
		$This.DynamicPackage = $ObjectTypeInstance._DB_ATTR_PKG_ISDYNAMIC_
		$This.FileCount = $ObjectTypeInstance._DB_ATTR_PKG_NUMBEROFFILE_
		$This.ForceReassignment = $ObjectTypeInstance._DB_ATTR_PKG_FORCEREASSIGN_
		if ($This.Checksum -ne '') { $this.GUID = $This.Checksum }
		$This.Icon = $ObjectTypeInstance._DB_ATTR_SMALLICON_
		$This.ID = $ID
		$This.LastModifiedBy = $ObjectTypeInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModifiedTime = $ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.MappingActivated = $ObjectTypeInstance._DB_ATTR_PKG_ISMAPPING_
		$This.Name = $ObjectTypeInstance._DB_ATTR_NAME_
		$This.Notes = $ObjectTypeInstance._DB_ATTR_NOTES_
		$This.PackageSizeCompressedKB = $ObjectTypeInstance._DB_ATTR_PKG_SIZE_COMPRESSED_
		$This.PackageSizeKB = $ObjectTypeInstance._DB_ATTR_PKG_SIZE_
		$This.PackageType = $ObjectTypeInstance._DB_ATTR_PKG_TYPE_
		$This.Referenced = $ObjectTypeInstance._DB_ATTR_PKG_ISREFERENCE_
		$This.Relay = $ObjectTypeInstance._DB_ATTR_PKGADMINRELAY_
		$This.FormattedName = "$($This.Name) (ID: $ID)"
		$This.ArchiveFile = Get-BCMPackageArchive $This -WarningAction SilentlyContinue
		if ($This.ArchiveFile) { $This.InstallXML = Get-BCMPackageXML $This }

		if ($This.InstallXML)
		{
			$This.Destination = $This.InstallXML.Package.Options.Destination
			$This.RunCommand = $This.InstallXML.Package.Options.CommandLine.Command.'#text'
			$This.OverwriteSystemFiles = $This.InstallXML.Package.Options.Overwrite.SystemFiles
			$This.OverwriteNonSystemFiles = $This.InstallXML.Package.Options.Overwrite.NonSystemFiles
			$This.OverwriteOlderFileVersions = $This.InstallXML.Package.Options.Overwrite.CheckVersion
			$This.OverwriteReadOnlyFiles = $This.InstallXML.Package.Options.Overwrite.ReadOnlyFiles
			$This.FastInstallation = $This.InstallXML.Package.Options.FastInstall
			$This.RunProgramInItsContext = $This.InstallXML.Package.Options.ProgramContext
			$This.UseAShell = $This.InstallXML.Package.Options.ShellParser
		}
	}

	CustomPackage ([string]$CustomPackageName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $CustomPackageName -ObjectType 'Package'
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}

	CustomPackage ([Package]$Package)
	{
		$Package.PSObject.Properties.Name | ForEach-Object { $this.$_ = $Package.$_ }

		$This.Destination = $Package.InstallXML.Package.Options.Destination
		$This.RunCommand = $Package.InstallXML.Package.Options.CommandLine.Command.'#text'
		$This.OverwriteSystemFiles = $Package.InstallXML.Package.Options.Overwrite.SystemFiles
		$This.OverwriteNonSystemFiles = $Package.InstallXML.Package.Options.Overwrite.NonSystemFiles
		$This.OverwriteOlderFileVersions = $Package.InstallXML.Package.Options.Overwrite.CheckVersion
		$This.OverwriteReadOnlyFiles = $Package.InstallXML.Package.Options.Overwrite.ReadOnlyFiles
		$This.FastInstallation = $Package.InstallXML.Package.Options.FastInstall
		$This.RunProgramInItsContext = $Package.InstallXML.Package.Options.ProgramContext
		$This.UseAShell = $Package.InstallXML.Package.Options.ShellParser
	}

	# Methods

}

Update-TypeData -TypeName CustomPackage -DefaultDisplayPropertySet ID, Name, RunCommand, Destination

class MSIPackage: package
{
	# Properties
	[string]$UserInterface
	[string]$Installation
	[bool]$DeleteMSIFiles
	[string]$OtherOptions
	[string]$ListOfTransform
	[string]$LogFile
	[bool]$RunProgramInItsContext

	# Constructors
	MSIPackage ([int]$ID)
	{
		$ObjectTypeInstance = Get-BCMObjectInstanceAttribute -ObjectType _DB_OBJECTTYPE_PACKAGE_ -InstanceID $ID -TranslateBackendNames $false

		$This.ArchiveName = $ObjectTypeInstance._DB_ATTR_ARCHNAME_
		$This.ArchiveType = $ObjectTypeInstance._DB_ATTR_ARCHIVETYPE_
		$This.Checksum = $ObjectTypeInstance._DB_ATTR_PKG_CHECKSUM_
		$This.CreatedBy = $ObjectTypeInstance._DB_ATTR_CREATEDBY_
		if ($ObjectTypeInstance._DB_ATTR_CREATETIME_ -ne '') { $This.CreatedTime = $ObjectTypeInstance._DB_ATTR_CREATETIME_ }
		$This.CreatingDevice = $ObjectTypeInstance._DB_ATTR_CREATEDEVICE_
		$This.CurrentLargeIcon = $ObjectTypeInstance._DB_ATTR_LARGEICON_
		$This.DynamicPackage = $ObjectTypeInstance._DB_ATTR_PKG_ISDYNAMIC_
		$This.FileCount = $ObjectTypeInstance._DB_ATTR_PKG_NUMBEROFFILE_
		$This.ForceReassignment = $ObjectTypeInstance._DB_ATTR_PKG_FORCEREASSIGN_
		if ($This.Checksum -ne '') { $this.GUID = $This.Checksum }
		$This.Icon = $ObjectTypeInstance._DB_ATTR_SMALLICON_
		$This.ID = $ID
		$This.LastModifiedBy = $ObjectTypeInstance._DB_ATTR_LASTMODIFIEDBY_
		if ($ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ -ne '') { $This.LastModifiedTime = $ObjectTypeInstance._DB_ATTR_LASTMODIFYTIME_ }
		$This.MappingActivated = $ObjectTypeInstance._DB_ATTR_PKG_ISMAPPING_
		$This.Name = $ObjectTypeInstance._DB_ATTR_NAME_
		$This.Notes = $ObjectTypeInstance._DB_ATTR_NOTES_
		$This.PackageSizeCompressedKB = $ObjectTypeInstance._DB_ATTR_PKG_SIZE_COMPRESSED_
		$This.PackageSizeKB = $ObjectTypeInstance._DB_ATTR_PKG_SIZE_
		$This.PackageType = $ObjectTypeInstance._DB_ATTR_PKG_TYPE_
		$This.Referenced = $ObjectTypeInstance._DB_ATTR_PKG_ISREFERENCE_
		$This.Relay = $ObjectTypeInstance._DB_ATTR_PKGADMINRELAY_
		$This.FormattedName = "$($This.Name) (ID: $ID)"
		$This.ArchiveFile = Get-BCMPackageArchive $This -WarningAction SilentlyContinue
		if ($This.ArchiveFile) { $This.InstallXML = Get-BCMPackageXML $This }

		if ($This.InstallXML)
		{
			$This.LogFile = ($This.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'Log file').'#text'
			$This.OtherOptions = ($This.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'Other options').'#text'
			$This.ListOfTransform = ($This.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'List of transform').'#text'
			$This.RunProgramInItsContext = ($This.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'ProgramContext').'#text'
			$This.DeleteMSIFiles = ($This.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'Delete Msi Files').'#text'
			$This.UserInterface = $This.InstallXML.Package.UserInterface.Option.Name
			$This.Installation = $This.InstallXML.Package.Installation.Option.Type
		}
	}

	MSIPackage ([string]$MSIPackageName)
	{
		$BCMCObject = Get-BCMCommonObject -Name $MSIPackageName -ObjectType 'Package'
		$BCMCObject.PSObject.Properties.Name | ForEach-Object { $This.$_ = $BCMCObject.$_ }
	}

	MSIPackage ([Package]$Package)
	{
		$Package.PSObject.Properties.Name | ForEach-Object { $this.$_ = $Package.$_ }

		$This.LogFile = ($Package.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'Log file').'#text'
		$This.OtherOptions = ($Package.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'Other options').'#text'
		$This.ListOfTransform = ($Package.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'List of transform').'#text'
		$This.RunProgramInItsContext = ($Package.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'ProgramContext').'#text'
		$This.DeleteMSIFiles = ($Package.InstallXML.Package.Installation.Options.ChildNodes | Where-Object Name -EQ 'Delete Msi Files').'#text'
		$This.UserInterface = $Package.InstallXML.Package.UserInterface.Option.Name
		$This.Installation = $Package.InstallXML.Package.Installation.Option.Type
	}

	# Methods

}

Update-TypeData -TypeName MSIPackage -DefaultDisplayPropertySet ID, Name, LogFile, OtherOptions

#endregion Classes

Write-Verbose 'Finished Importing Classes'

#endregion

#region BMC Server Setup
Write-Verbose 'Setting BMC server locations'

$ServerPort = switch ($BMCEnvironment)
{
	PROD { 'fpacms01:1611'; break }
	QA { 'cscmmasterq001:1611' }
	DEV { 'cscmmasterd001:16111'; break }
	BETA { 'fpacv12tstng01:1610'; break }
	default { Throw "ERROR: $_ BMC Environment does not exist" }
}

if ($host.ui.RawUI.WindowTitle -like "Administrator: *") { $host.ui.RawUI.WindowTitle = "$BMCEnvironment BMC Rest API & $vCentersToConnectTo PowerCLI - $ADUsername - ADMIN" }
else { $host.ui.RawUI.WindowTitle = "$BMCEnvironment BMC Rest API & $vCentersToConnectTo PowerCLI - $ADUsername" }

$BaseURL = "https://$ServerPort/api/1"
$Server = $ServerPort.Split(':')[0]
$PackagesDir = "\\$Server\d$\Program Files\BMC Software\Client Management\master\data\Vision64Database\packages"
$CustomPackageDir = "\\$Server\d$\Program Files\BMC Software\Client Management\Master\data\PackagerCustom\packages"
$MSIPackageDir = "\\$Server\d$\Program Files\BMC Software\Client Management\Master\data\PackagerMsi\packages"

Write-Verbose 'Finished setting BMC server locations'
#endregion BMC Server Setup

#region Credential Setup

Write-Verbose 'Setting up API & PowerCLI credentials'

if (-Not(Test-Path $EncryptedCredentialsPath))
{
	$Credential = Get-Credential -UserName "$env:USERDOMAIN\$ADUsername" -Title 'Automated Factory Credentials Needed' -Message "Please provide network credentials for $ADUsername to be saved to $EncryptedCredentialsPath"
	$Credential.Password | ConvertFrom-SecureString | Set-Content $EncryptedCredentialsPath -Force
}
<#
How to setup new cached credentials using PowerShell 5

$EncryptedCredentialsPath = "$env:LOCALAPPDATA\AutomatedFactory_EncryptedNetworkCredentials.txt"
$ADUsername = $APIServiceAccountName
$Credential = Get-Credential -UserName "$env:USERDOMAIN\$ADUsername" -Message "Please provide network credentials for $ADUsername to be saved to $EncryptedCredentialsPath"
$Credential.Password | ConvertFrom-SecureString | Set-Content $EncryptedCredentialsPath -Force
#>

#if ($BMCEnvironment -eq 'QA') { $Username = "$env:USERDOMAIN\$env:USERNAME" }
#else { $Username = "$DomainNickname\$env:USERNAME" }

$BCMUsername = "$DomainNickname\$ADUsername"
$Encrypted = Get-Content $EncryptedCredentialsPath
try { $Encrypted = $Encrypted | ConvertTo-SecureString -ErrorAction Stop }
Catch { throw "Failed to convert encrypted credentials to a secure string, see encrypted credentials below:`r`n$Encrypted" }

$Credential = New-Object System.Management.Automation.PsCredential($BCMUsername, $Encrypted)

$vSphereUsername = "$env:USERDOMAIN\$ADUsername"
$vSphereCredential = New-Object System.Management.Automation.PsCredential($vSphereUsername, $Encrypted)

Write-Verbose 'Finished setting up API & PowerCLI credentials'
#endregion Credential Setup

#region Translation Tables

Write-Verbose 'Defining Translation Tables'

$PackageConfigTranslation = @{
	ORIGNAME		    = 'OriginalName'
	CREATEDATE		    = 'Create Time'
	MODIFYDATE		    = 'LastModifiedTime'
	MODIFIEDBY		    = 'LastModifiedBy'
	PUBLISHSTATUS	    = 'PackageStatus'
	FORCERENAME		    = 'ForceReassignmentWhenPublished'
	DynamicPackage	    = 'DynamicPackage'
	MappingPackage	    = 'Mapping'
	SYSTEMFILES		    = 'OverwriteSystemFiles'
	NONSYSTEMFILES	    = 'OverwriteNonSystemFiles'
	CHECKVERSION	    = 'OverwriteOlderFileVersions'
	READONLYFILES	    = 'OverwriteReadOnlyFiles'
	COMMANDLINE		    = 'RunCommand'
	FASTINSTALL		    = 'Fast Installation'
	PROGRAMCONTEXT	    = 'RunProgramInItsContext'
	SHELLPARSER		    = 'UseAShell'
	ADMINLOGIN		    = 'Login'
	ADMINPASSWORD	    = 'Password'
	CONTINUEINSTALL	    = 'ContinueInstallationifLoginFails'
	CREATIONDATE	    = 'CreateTime'
	MODIFICATIONDATE    = 'LastModificationTime'
	SRCPATH			    = 'SourcePath'
	'Log file'		    = 'LogFile'
	'Other options'	    = 'OtherOptions'
	'List of transform' = 'ListOfTransform'
	'Delete Msi Files'  = 'DeleteMSIFiles'
}
$StatusTranslation = @{
	_STATUS_ASSIGNOK_			     = 'Assigned'
	_STATUS_ASSIGNPAUSED_		     = 'Assignment Paused'
	_STATUS_ASSIGNPLANNED_		     = 'Assignment Planned'
	_STATUS_ASSIGNSENT_			     = 'Assignment Sent'
	_STATUS_ASSIGNWAITING_		     = 'Assignment Waiting'
	_STATUS_AVAILABLE_			     = 'Available'
	_STATUS_DELETED_				 = 'Deleted'
	_STATUS_DEPENDENCIESCHECKFAILED_ = 'Dependency Check Failed'
	_STATUS_DEPENDENCIESCHECKREQ_    = 'Dependency Check Requested'
	_STATUS_DEPENDENCIESCHECKOK_	 = 'Dependency Check Successful'
	_STATUS_DISABLED_			     = 'Disabled'
	_STATUS_EXECUTEDOK_			     = 'Executed'
	_STATUS_EXECUTEFAILED_		     = 'Execution Failed'
	_STATUS_NOTRECEIVED_			 = 'Not Received'
	_STATUS_OBSOLETE_			     = 'Obsolete'
	_STATUS_MISSINGPACKAGE_		     = 'Package Missing'
	_STATUS_PACKAGEREQUESTED_	     = 'Package Requested'
	_STATUS_PACKAGESENT_			 = 'Package Sent'
	_STATUS_ADVERTISEPLANNED_	     = 'Publication Planned'
	_STATUS_ADVERTISESENT_		     = 'Publication Sent'
	_STATUS_ADVERTISEWAITING_	     = 'Publication Waiting'
	_STATUS_ADVERTISEOK_			 = 'Published'
	_STATUS_CONFIGUREDOK_		     = 'Ready to run'
	_STATUS_REASSIGNWAITING_		 = 'Reassignment Waiting'
	_STATUS_REBOOTPENDING_		     = 'Reboot Pending'
	_STATUS_IMPOSSIBLESENDING_	     = 'Sending impossible'
	_STATUS_STEPMISSINGSCRIPT_	     = 'Step Missing'
	_STATUS_STEPREQUESTED_		     = 'Step Requested'
	_STATUS_STEPSENT_			     = 'Step Sent'
	_STATUS_UNASSIGNEDOK_		     = 'Unassigned'
	_STATUS_UNASSIGNEDPAUSED_	     = 'Unassignment Paused'
	_STATUS_UNASSIGNEDSENT_		     = 'Unassignment Sent'
	_STATUS_UNASSIGNEDWAITING_	     = 'Unassignment Waiting'
	_STATUS_UNINSTALLED_			 = 'Uninstalled'
	_STATUS_UPDATEPAUSED_		     = 'Update Paused'
	_STATUS_UPDATEPLANNED_		     = 'Update Planned'
	_STATUS_UPDATESENT_			     = 'Update Sent'
	_STATUS_UPDATEWAITING_		     = 'Update Waiting'
	_STATUS_UPDATEOK_			     = 'Updated'
	_STATUS_VERIFICATIONFAILED_	     = 'Verification Failed'
	_STATUS_VERIFICATIONREQUESTED_   = 'Verification Requested'
	_STATUS_VERIFICATIONOK_		     = 'Verified'
	_STATUS_OPRULEWAITING_		     = 'Waiting for Operational Rule'
}

$OpRuleStepResultConditionTranslation = @{
	#From Get-Enums StepActionsSuccess & Get-Enums StepActions
	Continue = '_DB_STEPACTION_CONTINUE_'
	Fail	 = '_DB_STEPACTION_FAILED_'
	Succeed  = '_DB_STEPACTION_SUCCEED_'
	GoTo = '_DB_STEPACTION_GOTO_'
}

$OpRuleVerificationConditionTranslation = @{
	#From Get-Enums VerificationActions or (Use-BMCRestAPI "/enum/group?name=VerificationActions").Group.Members.Name
	FailContinue    = '"_DB_STEPACTION_VERIFLOOPONERROR_"'
	FailFail	    = '"_DB_STEPACTION_VERIFSTOPONERROR_FAILED_"'
	FailSucceed	    = '"_DB_STEPACTION_VERIFSTOPONERROR_"'
	SuccessContinue = '"_DB_STEPACTION_VERIFLOOPONSUCCESS_"'
	SuccessFail	    = '"_DB_STEPACTION_VERIFSTOPONSUCCESS_FAILED_"'
	SuccessSucceed  = '"_DB_STEPACTION_VERIFSTOPONSUCCESS_"'
	None		    = '"_DB_STEPACTION_VERIFNONE_"'
}

$BCMObjectClassTranslation = @{
	_DB_OBJECTTYPCLASS_BASIC_						   = 'Basic'
	_DB_OBJECTTYPCLASS_SOFTWAREINVENTORY_			   = 'Software Inventory'
	_DB_OBJECTTYPCLASS_HARDWAREINVENTORY_			   = 'Hardware Inventory'
	_DB_OBJECTTYPCLASS_CUSTOMINVENTORY_			       = 'Custom Inventory'
	_DB_OBJECTTYPCLASS_SECURITYINVENTORY_			   = 'Security Inventory'
	_DB_OBJECTTYPCLASS_POWERMANAGEMENTINVENTORY_	   = 'Power Management Inventory'
	_DB_OBJECTTYPCLASS_CONNECTIVITYINVENTORY_		   = 'Connectivity Inventory'
	_DB_OBJECTTYPCLASS_VIRTUALINFRASTRUCTUREINVENTORY_ = 'Virtual Infrastructure Inventory'
}

Write-Verbose 'Finished defining Translation Tables'

#endregion Translation Tables

#region Core functions

Write-Verbose 'Defining Core functions'

<#
	.SYNOPSIS
		Makes authenticated RestAPI calls to the BMC Server

	.DESCRIPTION
		Uses Invoke-RestMethod and encrypted credentials stored in $EncryptedCredentialsPath to make API calls. Bypasses the certificate check.
		Errors out if the HTTP response code is something other than 200

	.PARAMETER URL
		The portion of the URL for the BCM API call after "https://$ServerPort/api/1"

	.PARAMETER Method
		HTTP methods: GET, DELETE, PATCH, POST, or PUT

	.PARAMETER Body
		Use this if you need to send a body with your API call, generally only used with POST methods

	.EXAMPLE
		PS C:\> Use-BCMRestAPI -URL '/package/packages'

	.EXAMPLE
		PS C:\> Use-BCMRestAPI -URL "/device/1252/session" -Method PUT

	.EXAMPLE
		PS C:\> Use-BCMRestAPI -URL '/i18n/keywords' -Body '{ "keywords": [ "MODIFICATIONDATE", "PUBLISHSTATUS" ] }' -Method POST
#>
function Use-BCMRestAPI
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$URL,
		[ValidateSet('POST', 'GET', 'PUT', 'PATCH', 'DELETE')]
		[string]$Method = 'GET',
		[string]$Body
	)
	if ($URL.StartsWith('/')) { $URL = $URL.TrimStart('/') }
	if ($URL.Contains('+')) { $URL = $URL.Replace('+', '%2B') }

	try
	{
		if ($Body -eq $null) { $Result = Invoke-RestMethod -SkipCertificateCheck -Method $Method -Uri "$BaseURL/$URL" -Authentication basic -Credential $credential 4>$null }
		else { $Result = Invoke-RestMethod -SkipCertificateCheck -Method $Method -Uri "$BaseURL/$URL" -body $Body -Authentication basic -Credential $credential 4>$null }
	}
	catch [Microsoft.PowerShell.Commands.HttpResponseException]
	{
		$HTTPExceptionCode = $_.Exception.Response.StatusCode
		Write-Host "HTTP Exception Code is $HTTPExceptionCode $($HTTPExceptionCode.value__)"
		#Write-Host "Exception Code is type $($HTTPExceptionCode.GetType().FullName)"
		switch ($HTTPExceptionCode.value__)
		{
			401 {
				Write-Warning "Invalid credentials, please re-enter your credentials"
				$Username = "$DomainNickname\$env:USERNAME"
				$Encrypted = (Get-Credential).Password
				$Credential = New-Object System.Management.Automation.PsCredential($Username, $Encrypted)
			}
			404 { Write-Host "Error 404" }
			200 { Write-Host "Sucessful API Call" }
			default { throw "Invalid exception code" }
		}
	}
	catch [System.Net.Http.HttpRequestException] {
		$InnerExceptionErrorCode = $_.Exception.InnerException.InnerException.ErrorCode
		if ($InnerExceptionErrorCode -eq $null) { $InnerExceptionErrorCode = $_.Exception.InnerException.ErrorCode }

		if ($InnerExceptionErrorCode)
		{
			Write-Warning "Error Code is $InnerExceptionErrorCode"
			if ($InnerExceptionErrorCode -eq 10061) { throw "$BMCEnvironment BMC is down" }
		}

		if ($_.Exception.Message) { Write-Warning $_.Exception.Message }
		elseif ($_.Exception) { Write-Warning $_.Exception }
		else { Write-Error $_ }


	}
	Catch
	{
		if ($_.Execution) { throw "Returned error type is $($_.Execution.GetType().FullName)" }
		else { Write-Error $_ -ErrorAction Stop }
	}

	if (($Result.ErrorCode) -and ($Result.ErrorCode -ne 0)) { throw "API call returned error code $($Result.ErrorCode)" }
	else { return $Result }
}

<#
	.SYNOPSIS
		Returns a Object Type object from the ObjectTypes variable

	.PARAMETER ID
		The ID of the Object Type Attribute
		This is different between BCM installs

	.PARAMETER Name
		The backend BMC database name, from the name property of the Object Type object

	.PARAMETER FrontEndName
		The front end name of the Object Type, generally the same name as in the GUI

	.EXAMPLE
		PS C:\> Get-ObjectType -ID 1613

	.EXAMPLE
		PS C:\> Get-ObjectType -Name '_DB_STEPNAME_WAIT_'

	.EXAMPLE
		PS C:\> Get-ObjectType -FrontEndName 'Execute Program'

	.EXAMPLE
		PS C:\> Get-ObjectType -FrontEndName 'Registry*'

	.INPUTS
		String
		Int
#>
function Get-BCMObjectType
{
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	[OutputType([ObjectType])]
	param
	(
		[Parameter(ParameterSetName = 'ByID',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[int[]]$ID,
		[Parameter(ParameterSetName = 'ByName',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$Name,
		[Parameter(ParameterSetName = 'ByFrontEndName',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$FrontEndName
	)

	begin
	{
		$Index = $ObjectTypes
		$SearchTerm = switch ($PsCmdlet.ParameterSetName)
		{
			'ByName' { $Name }
			'ByFrontEndName' { $FrontEndName }
			'ByID' { $ID }
		}
	}
	process
	{
		foreach ($Term in $SearchTerm)
		{
			if ([WildcardPattern]::ContainsWildcardCharacters($Term)) { $Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -Like $Term }
			else
			{
				$Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -eq $Term

				if ($Result.Count -gt 1)
				{
					if ($PsCmdlet.ParameterSetName -eq 'ByID') { throw "More than one Object Type was found with the ID $Term" }
					else { Write-Warning "More than one Object Type was found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term" }
				}
			}

			if (-not ($Result)) { Write-Verbose "No Object Types were found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term" }
			else { Write-Output $Result }
		}
	}
}

<#
	.SYNOPSIS
		Gathers the attributes for a BCM Object Type

	.PARAMETER ObjectType
		The ObjectType object. This can be had by using Get-BCMObject.
		If this is the only parameter used, all the attributes for the object type will be returned.

	.PARAMETER ID
		The ID of the Object Type Attribute
		This:
			Is unique to the object and the attribute (i.e. the ID for the Name property of an OpRule will be different from the Name property of a Device Group)
			Is be different between BCM installs
			Can be different between BCM revisions

	.PARAMETER Name
		The front end name (generally the same name as in the GUI) of the Object Type Attribute
		If this parameter is used, the attributes are filtered down AFTER they are converted to ObjectTypeAttribute objects.

	.PARAMETER FrontEndName
		A description of the FrontEndName parameter.

	.PARAMETER BackendName
		The backend BMC database name of the Object Type Attribute
		If this parameter is used, the attributes are filtered down before they are converted to ObjectTypeAttribute objects, which is noticeably quicker.

	.EXAMPLE
		PS C:\> Get-BCMObjectTypeAttribute -ObjectType $ObjectType

	.EXAMPLE
		PS C:\> Get-BCMObjectTypeAttribute -ObjectType $ObjectType -ID 12345

	.EXAMPLE
		PS C:\> Get-BCMObjectTypeAttribute -ObjectType $ObjectType -Name *Time

	.EXAMPLE
		PS C:\> Get-BCMObjectTypeAttribute -ObjectType $ObjectType -Name _DB_ATTR_CREATEDBY_

	.EXAMPLE
		PS C:\> Get-BCMObjectTypeAttribute -ObjectType $ObjectType -FrontEndName 'Created By'

	.NOTES
		This will:
			Error out if multiple attributes are found when using the ID parameter
			Give a warning if multiple attributes are found when using the Name or FrontEndName parameter without any wildcards
			Writes a verbose message if no attributes are found when using the ID, Name, or FrontEndName parameters

	.INPUTS
		BCMAPI.ObjectType
		Int
		String
#>
function Get-BCMObjectTypeAttribute
{
	[CmdletBinding(DefaultParameterSetName = 'All')]
	[OutputType([ObjectTypeAttribute])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[ObjectType[]]$ObjectType,
		[Parameter(ParameterSetName = 'ByID',
				   Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[int[]]$ID,
		[Parameter(ParameterSetName = 'ByName',
				   Mandatory = $true,
				   Position = 1)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$Name,
		[Parameter(ParameterSetName = 'ByFrontEndName',
				   Mandatory = $true,
				   Position = 1)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$FrontEndName
	)

	process
	{
		foreach ($Type in $ObjectType)
		{
			Write-Verbose "Gathering Object Type Attributes for $($Type.FormattedName)"
			$Index = (Use-BCMRestAPI "/object/$($Type.ID)/attrs").Attrs

			switch ($PsCmdlet.ParameterSetName)
			{
				'All'{
					$SearchTerm = $null
					$Index | ForEach-Object { Write-Output ([ObjectTypeAttribute]::New($_)) }
				}
				'ByName' {
					$SearchTerm = $Name
				}
				'ByFrontEndName' {
					$SearchTerm = $FrontEndName
					$Index = $Index | ForEach-Object { [ObjectTypeAttribute]::New($_) }
				}
				'ByID' {
					$SearchTerm = $ID
				}
			}

			foreach ($Term in $SearchTerm)
			{
				if ([WildcardPattern]::ContainsWildcardCharacters($Term)) { $Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -Like $Term }
				else
				{
					$Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -eq $Term

					if ($Result.Count -gt 1)
					{
						if ($PsCmdlet.ParameterSetName -eq 'ByID') { throw "More than one attribute was found with the ID $Term for the object type $($Type.FormattedName)" }
						else { Write-Warning "More than one attribute was found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term for the obejct type $($Type.FormattedName)" }
					}
				}

				if (-not ($Result)) { Write-Verbose "No attributes were found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term for the object type $($Type.FormattedName)" }

				if ($PsCmdlet.ParameterSetName -eq 'ByFrontEndName') { Write-Output $Result }
				else { $Result | ForEach-Object { Write-Output ([ObjectTypeAttribute]::New($_)) } }
			}
		}
	}
}

<#
	.SYNOPSIS
		Gathers the instances of a particular object type that matches the specified attribute value

	.DESCRIPTION
		Translates the front end operator name to the backend operator name
		Updates the 'Objects Found' parameter value to the proper formatting the API call, if used
		Gathers the object instances

	.PARAMETER ObjectType
		The object type to use

	.PARAMETER Source
		The place in BMC to search.
		Allowable values are 'All', 'Hierarchy', 'Objects Found', and 'Topology' (Topology is what is used for devices)

	.PARAMETER Attribute
		The BCM object type attribute

	.PARAMETER Value
		The value that you want to search off of.
		If you want to do a wildcard search, the only allowable wildcard is '%', which matches zero or more characters
		See https://docs.bmc.com/docs/bcm129/searching-objects-869555770.html#Searchingobjects-Advancesearch

	.EXAMPLE
		PS C:\> Get-BCMObjectInstance -ObjectType '_DB_OBJECTTYPE_OPERATIONALRULE_' -Attribute $OpRuleNameObjectTypeAttribute -Value '%Reader%'

	.EXAMPLE
		PS C:\> Get-BCMObjectInstance -ObjectType '_DB_OBJECTTYPE_DEVICE_' -Attribute $DeviceNameObjectTypeAttribute -Value 'VDPKG0001' -Source Topology

	.INPUTS
		BCMAPI.ObjectType
		BCMAPI.ObjectTypeAttribute
		String
#>
function Get-BCMObjectInstance
{
	[CmdletBinding()]
	[OutputType([pscustomobject])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $false)]
		[ObjectType]$ObjectType,
		[ValidateSet('All', 'Hierarchy', 'ObjectsFound', 'Topology')]
		[string]$Source = 'All',
		[Parameter(Mandatory = $true)]
		[ObjectTypeAttribute]$Attribute,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[string[]]$Value
	)
	process
	{
		foreach ($SearchTerm in $Value)
		{
			if ($SearchTerm.Contains('%')) { $BackendOperator = '_DB_QUERYOPERATOR_CONTAINS_' }
			else { $BackendOperator = '_DB_QUERYOPERATOR_EQUAL_' }

			Write-Debug "Backend Operator is $BackendOperator"

			Write-Verbose "Looking for a $($ObjectType.FormattedName) type object with a $($Attribute.FormattedName) attribute of $SearchTerm"
			$Result = Use-BCMRestAPI "/object/$($ObjectType.ID)/insts?source=$Source&attr=$($Attribute.Name)&operator=$BackendOperator&value=$SearchTerm"

			if ($Result.Fault) { Write-Warning "Failed to find object instance with error code $($Result.Fault.Code)" }
			elseif (-not ($Result.insts)) { Write-Verbose "No $($ObjectType.FormattedName) objects were found with $SearchTerm in their $Attribute attribute under $Source" }
			else { Write-Output $Result.insts }
		}
	}
}

<#
	.SYNOPSIS
		Gathers the attributes of a particular instance of an object type

	.PARAMETER ObjectType
		The ObjectType to use

	.PARAMETER InstanceID
		The ID of the particular object

	.PARAMETER TranslateBackendNames
		Translates the backend names of the properties (using Get-BCMFrontEndText) to their front-end names and adds them as alias properties for the backend names

	.EXAMPLE
		PS C:\> Get-BCMObjectInstanceAttribute -ObjectType $OpRuleObjectType -InstanceID $InstanceID

	.EXAMPLE
		PS C:\> Get-BCMObjectInstanceAttribute -ObjectType $OpRuleObjectType -InstanceID $InstanceID -TranslateBackendNames $false

	.INPUTS
		BCMAPI.ObjectType
		Bool
		Int
#>
function Get-BCMObjectInstanceAttribute
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ObjectType]$ObjectType,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[int]$InstanceID,
		[bool]$TranslateBackendNames = $true
	)

	Process
	{
		Write-Verbose "Gathering attributes for instance $InstanceID of $($ObjectType.FormattedName)"
		$Result = (Use-BCMRestAPI "/object/$($ObjectType.ID)/inst/$InstanceID/attrs").Values

		if (($Result | Get-Member -MemberType NoteProperty) -eq $null) { throw "No $($ObjectType.FrontEndName) object instances exist with a ID of $InstanceID" }

		if ($TranslateBackendNames)
		{
			$PropertyNames = $Result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
			foreach ($BackendPropertyName in $PropertyNames)
			{
				Write-Verbose "Adding alias property for $BackendPropertyName"
				$Result | Add-Member -MemberType AliasProperty -Name (Get-BCMFrontEndText $BackendPropertyName -TranslationOnly) -Value $BackendPropertyName -ErrorAction SilentlyContinue
			}
		}
		Write-Output $Result
	}
}

<#
	.SYNOPSIS
		Get the ID of a BCM object

	.PARAMETER Name
		The value of the name property of the object
		If you want to do a wildcard search, the only allowable wildcard is '%', which matches zero or more characters

	.PARAMETER ObjectType
		The object type to use

	.PARAMETER ObjectTypeObject
		The front end name of the object type.
		Allowable values are Device, Device Group, Operational Rule, Operational Rule Folder, Package

	.EXAMPLE
		PS C:\> Get-BCMID -Name 'APPGRP_CrowdStrike_CrowdStrikeWindowsSensor_CUR' -ObjectType 'Device Group'

	.EXAMPLE
		PS C:\> Get-BCMID -Name 'OPRULE_Microsoft_Office365-64bit_R%' -ObjectType 'Operational Rule'

	.EXAMPLE
		PS C:\> Get-BCMID -Name 'PACKAGES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS' -ObjectTypeObject '_DB_OBJECTTYPE_PACKAGEFOLDER_'

	.INPUTS
		BCMAPI.ObjectType
		String

	.NOTES
		Because device groups being in multiple parent groups will cause the name to return the same ID multiple times, the function only returns the unique IDs
#>
function Get-BCMID
{
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	[OutputType([int])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[SupportsWildcards()]
		[string[]]$Name,
		[Parameter(ParameterSetName = 'ByName',
				   Mandatory = $true)]
		[ValidateSet('Device', 'Device Group', 'Operational Rule', 'Operational Rule Folder', 'Package')]
		[string]$ObjectType,
		[Parameter(ParameterSetName = 'ByObjectType',
				   Mandatory = $true)]
		[ObjectType]$ObjectTypeObject
	)

	begin
	{
		$ObjectTypeTranslation = @{
			'Device'				  = '_DB_OBJECTTYPE_DEVICE_'
			'Device Group'		      = '_DB_OBJECTTYPE_DEVICEGROUP_'
			'Operational Rule'	      = '_DB_OBJECTTYPE_OPERATIONALRULE_'
			'Operational Rule Folder' = '_DB_OBJECTTYPE_OPERATIONALRULEFOLDER_'
			'Package'				  = '_DB_OBJECTTYPE_PACKAGE_'
		}

		if ($PSCmdlet.ParameterSetName -eq 'ByName') { $ObjectTypeObject = Get-BCMObjectType -Name $ObjectTypeTranslation[$ObjectType] }

		$NameAttribute = Get-BCMObjectTypeAttribute -ObjectType $ObjectTypeObject -Name '_DB_ATTR_NAME_'
	}
	process
	{
		$Name | Get-BCMObjectInstance -ObjectType $ObjectTypeObject -Attribute $NameAttribute | ForEach-Object { $_.ID -as [int] } | Select-Object -Unique | Write-Output
	}
}

<#
	.SYNOPSIS
		Gathers a BCM Object

	.PARAMETER Name
		The name of the object
		If you want to do a wildcard search, the only allowable wildcard is '%', which matches zero or more characters

	.PARAMETER ObjectType
		The front end name of the object type.
		Allowable values are Device, Device Group, Operational Rule, Operational Rule Folder, Package

	.EXAMPLE
		PS C:\> Get-BCMCommonObject -Name VDPKG0001 -ObjectType Device

	.EXAMPLE
		PS C:\> Get-BCMCommonObject -Name 'OPRULE_CrowdStrike_CrowdStrikeWindowsSensor_R%' -ObjectType 'Operational Rule'

	.INPUTS
		String
#>
function Get-BCMCommonObject
{
	[CmdletBinding()]
	[OutputType([Device], [DeviceGroup], [OpRule], [OpRuleFolder], [Package], [MSIPackage], [CustomPackage])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[string[]]$Name,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateSet('Device', 'Device Group', 'Operational Rule', 'Operational Rule Folder', 'Package')]
		[string]$ObjectType
	)

	process
	{
		$Objects = @()
		foreach ($Value in $Name)
		{
			$ID = Get-BCMID -Name $Value -ObjectType $ObjectType
			if (($Value -NotLike '*%*') -and ($ID.Count -gt 1))
			{
				throw "Multiple IDs were found for the $ObjectType with the name $Value`: $($ID -join ', ')"
			}

			foreach ($Number in $ID)
			{
				$Objects += switch ($ObjectType)
				{
					'Device' { [Device]::New($Number) }
					'Device Group' { [DeviceGroup]::New($Number) }
					'Operational Rule' { [OpRule]::New($Number) }
					'Operational Rule Folder' { [OpRuleFolder]::New($Number) }
					'Package' {
						$Basic = [Package]::New($Number)
						switch ($Basic.PackageType)
						{
							'MSI' { [MSIPackage]::New($Basic) }
							'Custom' { [CustomPackage]::New($Basic) }
							default { $Basic }
						}
					}
				}
			}
		}
		Write-Output ($Objects | Sort-Object Name)
	}
}

<#
	.SYNOPSIS
		Looks for the ZIP file of the package install media in the Vision64Database folder on the BCM server

	.PARAMETER Package
		The package to use

	.EXAMPLE
		PS C:\> Get-BCMPackageArchive -Package $BCMPackage

	.INPUTS
		BCMAPI.Object.Package
		BCMAPI.Object.Package.CustomPackage
		BCMAPI.Object.Package.MSIPackage
#>
function Get-BCMPackageArchive
{
	[OutputType([System.IO.FileInfo])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[Package[]]$Package
	)
	process
	{
		foreach ($ClassyPackage in $Package)
		{
			Write-Verbose "Looking for package folder $PackagesDir\$($ClassyPackage.Name)\$($ClassyPackage.Checksum)"
			if (Test-Path "$PackagesDir\$($ClassyPackage.Name)\$($ClassyPackage.Checksum)")
			{
				Write-Verbose "Found package folder, looking for ZIP files inside the folder"
				$PackageZIP = Get-ChildItem "$PackagesDir\$($ClassyPackage.Name)\$($ClassyPackage.Checksum)" -Filter "*.zip" -Recurse

				if (-Not ($PackageZIP)) { Write-Warning "Cannot find any zip file in $PackagesDir\$($ClassyPackage.Name)\$($ClassyPackage.Checksum)" }
				elseif ($PackageZIP.Count -gt 1) { Write-Warning "There are multiple versions (zips) of this package under $PackagesDir\$($ClassyPackage.Name)\$($ClassyPackage.Checksum)" }
				else { Write-Output $PackageZIP }
			}
			else { Write-Warning "Cannot find package folder for $($ClassyPackage.Name) in $PackagesDir" }
		}
	}
}

<#
	.SYNOPSIS
		Extracts a single file from an zip file/archive

	.DESCRIPTION
		Adds the System.IO.Compression.FileSystem Assembly
		Uses .NET ZipFile class to OpenRead the Archive because the Extract-Archive cmdlet extracts all files
		Extracts the file to a specified folder
		Disposes of the .NET ZipFile object

	.PARAMETER ArchiveFile
		Must have a .zip file extension

	.PARAMETER FileName
		Name of the file in the archive that you want to unzip (including the extension)

	.PARAMETER DestinationFolder
		The path of the folder where the file is to be extracted to

	.EXAMPLE
		PS C:\> Expand-ArchivedFile -ArchiveFile $File -FileName 'install.xml' -DestinationFolder 'C:\Windows\Temp\Unzipped'

	.INPUTS
		String
		System.IO.FileInfo
#>
function Expand-ArchivedFile
{
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateScript({ (Test-Path $_.FullName) -and ((Split-Path $_.FullName -Extension) -eq '.zip') })]
		[System.IO.FileInfo]$ArchiveFile,
		[Parameter(Mandatory = $true)]
		[string]$FileName,
		[Parameter(Mandatory = $true)]
		[string]$DestinationFolder
	)

	if (-Not (Test-Path "$DestinationFolder"))
	{
		Write-Verbose "$DestinationFolder does not exist, creating directory"
		New-Item "$DestinationFolder" -ItemType Directory | Out-Null
	}

	Add-Type -AssemblyName System.IO.Compression.FileSystem

	Write-Verbose "Opening $($ArchiveFile.Name)"
	$Zip = [IO.Compression.ZipFile]::OpenRead($ArchiveFile)

	$ZippedFile = $Zip.Entries | Where-Object Name -EQ $FileName

	if ($ZippedFile.Count -eq 0)
	{
		Write-Warning "$($ArchiveFile.Name) does not contain a file named $FileName"
		Return
	}
	elseif ($ZippedFile.Count -gt 1)
	{
		Write-Warning "$($ArchiveFile.Name) contains $($ZippedFile.Count) files named $FileName"
		Return
	}

	$ExtractedPath = "$DestinationFolder\$FileName"

	try
	{
		Write-Verbose "Extracting $FileName to $DestinationFolder"
		[System.IO.Compression.ZipFileExtensions]::ExtractToFile($ZippedFile, $ExtractedPath, $true)
	}
	catch
	{
		Write-Warning "Failed to extract $($ZippedFile.Name)"
		Return
	}
	finally { $zip.Dispose() }

	if (-Not (Test-Path $ExtractedPath))
	{
		Write-Warning "$ExtractedPath does not exist"
		Return
	}
	else
	{
		Write-Verbose "Successfully extracted $($ZippedFile.Name) file to $ExtractedPath"
		Return  (Get-Item $ExtractedPath)
	}
}

<#
	.SYNOPSIS
		Finds the Install.XML file for a given BMC package

	.DESCRIPTION
		Looks for the Install.XML file under the correct subfolder (PackagerMSI or PackagerCustom) on the BMC server under 'D:\Program Files\BMC Software\Client Management\Master\data'
		if that doesn't exist, it looks for the Install.XML file in the package archive file listed on the ArchiveFile property.
		if the Install.XML file is found in the package archive file, it is extracted to "$env:temp\BCMAPI\$($Package.Name)"
		Then the Install.XML file is read into a [xml] type variable, and if the XML file had to be extracted, the extracted source file is deleted

	.PARAMETER Package
		Must be a BCMAPI.Object.Package type with the "Type" property being Custom or MSI

	.EXAMPLE
		PS C:\> Get-BCMPackageXML -Package $BCMPackage

	.INPUTS
		BCMAPI.Object.Package
		BCMAPI.Object.Package.CustomPackage
		BCMAPI.Object.Package.MSIPackage
#>
function Get-BCMPackageXML
{
	[CmdletBinding()]
	[OutputType([System.Xml.XmlDocument])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[Package[]]$Package
	)

	process
	{
		foreach ($ClassyPackage in $Package)
		{
			switch ($ClassyPackage.PackageType)
			{
				Custom { $PackagerDataDir = $CustomPackageDir }
				MSI { $PackagerDataDir = $MSIPackageDir }
				default { throw "$_ is an invalid package extension" }
			}
			Write-Debug "Packager Data Directory is: $PackagerDataDir"

			Write-Verbose "Looking for $PackagerDataDir\$($ClassyPackage.Name)\install.xml"
			if (Test-Path "$PackagerDataDir\$($ClassyPackage.Name)\install.xml") { [xml]$XML = Get-Content "$PackagerDataDir\$($ClassyPackage.Name)\install.xml" }
			else
			{
				Write-Verbose "Could not find $PackagerDataDir\$($ClassyPackage.Name)\install.xml."
				Write-Verbose "Looking for Install.XML in the archive file listed under the `"ArchiveFile`" property"
				if (-not ($ClassyPackage.ArchiveFile)) { Write-Warning "Package does not contain an archive file property" }
				else
				{
					$DestinationFolder = "$env:temp\BCMAPI\$($ClassyPackage.Name)"

					if (($ClassyPackage.ArchiveFile).Count -gt 1)
					{
						Write-Verbose "Found multiple zip files for the same package, picking the most recently written one"
						$MostRecentZip = $ClassyPackage.ArchiveFile | Sort-Object LastWriteTime -Descending | Select-Object -First 1
						[xml]$XML = Get-Content (Expand-ArchivedFile -ArchiveFile $MostRecentZip -FileName 'install.xml' -DestinationFolder $DestinationFolder)
					}
					else { [xml]$XML = Get-Content (Expand-ArchivedFile -ArchiveFile $ClassyPackage.ArchiveFile -FileName 'install.xml' -DestinationFolder $DestinationFolder) }

					Write-Verbose "Deleting $DestinationFolder"
					Remove-Item $DestinationFolder -Force -Recurse
				}
			}
			if ($XML) { Write-Output $XML }
		}
	}
}

<#
	.SYNOPSIS
		Translates the BCM backend text to the GUI front-end text

	.PARAMETER BackendText
		The back end text that you want to translate

	.PARAMETER TranslationOnly
		Returns just a string or array of strings with the front-end text
		By default, the API returns an object with the backend text as the property name and the front-end text

	.EXAMPLE
		PS C:\> Get-BCMFrontEndText -BackendText '_DB_OBJECTTYPE_OPERATIONALRULE_'

	.EXAMPLE
		PS C:\> Get-BCMFrontEndText -BackendText '_DB_OBJECTTYPE_OPERATIONALRULE_' -TranslationOnly

	.INPUTS
		System.String
#>
function Get-BCMFrontEndText
{
	[CmdletBinding()]
	[OutputType([String], [PSCustomObject])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[AllowEmptyString()]
		[string[]]$BackendText,
		[switch]$TranslationOnly
	)

	begin { $Body = "{ `"keywords`": [ `"$($BackendText -join '", "')`" ] }" }
	process
	{
		if ($BackendText -eq '') { Return '' }
		$FrontEndText = Use-BCMRestAPI "/i18n/keywords" -Method POST -Body $Body
		if ($FrontEndText.Fault -ne $null) { throw "Failed to find front end text with an error ID of $($FrontEndText.Fault.Code)" }
		if ($TranslationOnly.IsPresent) { Write-Output ($FrontEndText.Keywords).$BackendText }
		else { Write-Output $FrontEndText.Keywords }
	}
}

<#
	.SYNOPSIS
		Write a timestamped message to a log and outputs the same message to the select output stream

	.PARAMETER Message
		The body of the error message

	.PARAMETER LogFile
		The path to the log file. The file must already exist.

	.PARAMETER Stream
		The PowerShell output stream.
		Allowable values are 'Success', 'Error', 'Warning', 'Verbose', 'Debug', 'Information'.

	.PARAMETER ErrorAs
		How you want the error to be formmated.
		Allowable values are 'Error', 'Throw', 'Warning'

	.EXAMPLE
		PS C:\> Write-Log -Message 'Installed application' -LogFile 'C:\ProgramData\Media\Logs\Sample_Install.log'

	.EXAMPLE
		PS C:\> Write-Log -Message 'Failed to find file' -LogFile 'C:\ProgramData\Media\Logs\Sample_Install.log' -Stream Error

	.EXAMPLE
		PS C:\> Write-Log -Message 'Failed to copy folder' -LogFile 'C:\ProgramData\Media\Logs\Sample_Install.log' -Stream Error -ErrorAs Warning
#>
function Write-Log
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[string]$Message,
		[Parameter(Mandatory = $true)]
		[ValidateScript({ Test-Path $_ })]
		[string]$LogFile,
		[ValidateSet('Success', 'Error', 'Warning', 'Verbose', 'Debug', 'Information')]
		[string]$Stream = 'Success',
		[ValidateSet('Error', 'Throw', 'Warning')]
		[string]$ErrorAs = 'Error'
	)

	$TimeStamp = Get-Date -Format "MM/dd/yyyy HH:mm:ss"

	$Line = "[$TimeStamp] $($Stream.ToUpper())`: $Message"

	Add-Content $LogFile -Value $Line -Force

	switch ($Stream)
	{
		Success { Write-Output $Message }
		Error {
			switch ($ErrorAs)
			{
				'Error' { Write-Error $Message }
				'Throw' { throw $Message }
				'Warning' { Write-Warning $Message }
			}
		}
		Warning { Write-Warning $Message }
		Verbose { Write-Verbose $Message }
		Debug { Write-Debug $Message }
		Information { Write-Information $Message }
	}
}

<#
	.SYNOPSIS
		Get enumerators in a BCM enumerator group

	.PARAMETER EnumGroup
		The name of the enum groups.
		All enum groups can be listed with (Use-BCMRestAPI "/enum/groups").groups

	.EXAMPLE
		PS C:\> Get-Enums -EnumGroup 'TimeStep'

	.INPUTS
		String
#>
function Get-Enums
{
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$EnumGroup
	)

	#This might need to be shortened to remove 'Value' as there are two properties under Members that I presume to be identical
	Return (Use-BCMRestAPI "/enum/group?name=$EnumGroup").Group.Members.Value
}

Write-Verbose 'Finished defining Core functions'
#endregion Core functions

#region Core Variable Definitions
Write-Verbose 'Defining Core Variables'

Write-Verbose 'Defining Object Types'
$ObjectTypes = '_DB_OBJECTTYPCLASS_BASIC_', '_DB_OBJECTTYPCLASS_SOFTWAREINVENTORY_', '_DB_OBJECTTYPCLASS_HARDWAREINVENTORY_', '_DB_OBJECTTYPCLASS_CUSTOMINVENTORY_', '_DB_OBJECTTYPCLASS_SECURITYINVENTORY_', '_DB_OBJECTTYPCLASS_POWERMANAGEMENTINVENTORY_', '_DB_OBJECTTYPCLASS_CONNECTIVITYINVENTORY_', '_DB_OBJECTTYPCLASS_VIRTUALINFRASTRUCTUREINVENTORY_' | ForEach-Object { (Use-BCMRestAPI "/objects?class=$($_)").Types } | ForEach-Object { [ObjectType]::New($_) }
Write-Verbose 'Finished defining Object Types'

Write-Verbose 'Defining Enum Groups'
$EnumGroups = (Use-BCMRestAPI "/enum/groups").groups
Write-Verbose 'Finished defining Enum Groups'

Write-Verbose 'Defining Enums'
$AllEnums = $EnumGroups | ForEach-Object { Get-Enums $_.Name -ErrorAction SilentlyContinue } | Select-Object -Unique | Sort-Object
Write-Verbose 'Finished defining Enums'

Write-Verbose 'Defining Step Types'
$StepTypes = (Use-BCMRestAPI "/oprule/steps").Steps | ForEach-Object { [StepType]::New($_) }
Write-Verbose 'Finished defining Step Types'

Write-Verbose 'Finished defining Core Variables'

Write-Verbose 'Exporting BCM variables'
Export-ModuleMember -Variable BMCEnvironment, ObjectTypes, EncryptedCredentialsPath, EnumGroups, StepTypes
Write-Verbose 'Finished exporting BCM variables'
#endregion Core Variable Definitions

#region Extra functions

Write-Verbose 'Defining Extra functions'

function Get-Device
{
	[CmdletBinding()]
	[OutputType([Device])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[string[]]$Name
	)

	process { $Name | Get-BCMCommonObject -ObjectType Device | Write-Output }
}

function Get-OpRule
{
	[CmdletBinding()]
	[OutputType([OpRule])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[string[]]$Name
	)

	process	{ $Name | Get-BCMCommonObject -ObjectType 'Operational Rule' | Write-Output }
}

function Get-DeviceGroup
{
	[CmdletBinding()]
	[OutputType([DeviceGroup])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[string[]]$Name
	)

	process { $Name | Get-BCMCommonObject -ObjectType 'Device Group' | Write-Output }
}

function Get-BCMPackage
{
	[CmdletBinding()]
	[OutputType([Package])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[SupportsWildcards()]
		[string[]]$Name
	)

	process { $Name | Get-BCMCommonObject -ObjectType Package | Write-Output }
}

<#
	.SYNOPSIS
		Gets the ID of a device, given the device name

	.DESCRIPTION
		Looks up the device by the name
		if more than one result is returned, the deprecated devices are filtered out
		Errors out if multiple or no non-deprecated devices are found
		The object returned by the API does not contain an ID property.
		The Device ID itself is listed as a property name containing all the device properties
		So the Device ID is extracted by grabbing the name of the note properties on the API response that only contain digits
		Errors out if multiple or no possible IDs are found

	.PARAMETER Name
		The full name of the device

	.EXAMPLE
		PS C:\> Get-DeviceID -Name 'VDPKG0001'

	.OUTPUTS
		System.Int

	.INPUTS
		System.String
#>
function Get-DeviceID
{
	[CmdletBinding()]
	[OutputType([int])]
	param
	(
		[Parameter(Mandatory = $true,
			 ValueFromPipeline = $true)]
		[string[]]$Name
	)
	process
	{
		foreach ($DeviceName in $Name)
		{
			Write-Verbose "Looking for $DeviceName"
			$DeviceQuery = Use-BCMRestAPI "/devices?source=index&query=$DeviceName"
			if ($DeviceQuery.fault) { Throw "Device: $DeviceName does not exist in this BMC environment" }

			if ($DeviceQuery.Total -gt 1)
			{
				Write-Warning "There are $($DeviceQuery.Total) devices in BMC with the name $DeviceName"
				$DeviceList = @()

				#This needs a good test case to be able to update it like the ID definition below
				$IDs = ($DeviceQuery | Get-Member -MemberType NoteProperty)[0 .. ($DeviceQuery.Total - 1)].Name

				$IDs | ForEach-Object {
					$SeparatedDevice = $DeviceQuery.$_
					$SeparatedDevice | Add-Member -Name ID -Value $_ -MemberType NoteProperty
					$DeviceList += $SeparatedDevice
				}

				$NonRetired = $DeviceList | Where-Object TopologyType -ne '_DB_DEVTYPE_RETIRED_'
				if (-not ($NonRetired)) { Throw "Device: $DeviceName is deprecated" }
				elseif ($NonRetired.Count -eq 1)
				{
					Write-Warning "Luckily, only 1 of the devices was not retired" -InformationAction Continue
					$DeviceID = $NonRetired.ID
				}
				else { throw "There are duplicate non-deprecated entries for $DeviceName`:`n`r$($NonRetired | Format-Table | Out-String)" }
			}
			else
			{
				Write-Verbose "Only 1 device was found with the name $DeviceName"

				Write-Verbose "Parsing Device ID from object property names"
				$DeviceIDProperty = $DeviceQuery | Get-Member -MemberType NoteProperty | Where-Object Name -match '^\d+$'

				if (-not ($DeviceIDProperty)) { throw "No device ID was found in the object property names" }
				elseif ($DeviceIDProperty.Count -gt 1) { throw "Multiple object property names exist that could be Device IDs: $($DeviceIDProperty.Name -join ', ')" }
				else { $DeviceID = $DeviceIDProperty.Name }
			}

			Write-Verbose "Found Device ID $DeviceID for $DeviceName"
			Write-Output $DeviceID
		}
	}
}

<#
	.SYNOPSIS
		Gathers packages attached to an OpRule

	.PARAMETER OpRule
		The Operation Rule to use

	.EXAMPLE
		PS C:\> Get-OpRulePackages -OpRule 'OPRULE_Adobe_Reader_R27'

	.INPUT
		BCMAPI.Object.OpRule
#>
function Get-OpRulePackages
{
	[CmdletBinding()]
	[OutputType([CustomPackage], [MSIPackage], [Package])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[OpRule]$OpRule
	)

	process
	{
		Write-Verbose "Gathering package IDs attached to $($OpRule.FormattedName)"
		$PackageResults = (Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/packages").Packages | Sort-Object Name

		if ($PackageResults.Count -eq 0) { Write-Warning "There are no packages associated to $($OpRule.FormattedName)" }
		else
		{
			foreach ($Result in $PackageResults)
			{
				Write-Verbose "Finding package object for ID $($Result.ID)"
				$Object = switch ($Result.Type)
				{
					'MSI' { [MSIPackage]::New([int]$Result.ID) }
					'Custom' { [CustomPackage]::New([int]$Result.ID) }
					default { [Package]::New([int]$Result.ID) }
				}
				Write-Output $Object
			}
		}
	}
}

<#
	.SYNOPSIS
		Gathers the devices assigned to a particular device group and returns them in the specified format

	.DESCRIPTION
		Gathers the devices assigned to a device group
		By default this just returns the ID, Name, Notes and Created Date
		But if DeviceDetails or IDOnly are chosen, a different API call is made to grab just the IDs of the devices assigned to the device group
		if DeviceDetails is chosen in the ResultType parameter, the full device properties are gathered using Get-BCMDevice and the device IDs gathered in the previous step

	.PARAMETER DeviceGroup
		The device group to use

	.PARAMETER IDOnly
		Use if you'd like the function to return just the Device IDs

	.PARAMETER ResultType
		The amount of device info that you want returned
		Base: The properties normally returned by the API call: ID, Name, Notes and Created Date
		DeviceDetails: The full list of device properties returned by Get-BCMDevice
		IDOnly: Just the IDs of the devices

	.INPUTS
		BCMAPI.Object.DeviceGroup

	.EXAMPLE
		PS C:\> Get-DeviceGroupDevices -DeviceGroup $DeviceGroup

	.EXAMPLE
		PS C:\> Get-DeviceGroupDevices -DeviceGroup $DeviceGroup -IDOnly
#>
function Get-DeviceGroupDevices
{
	[CmdletBinding()]
	[OutputType([Device], [int])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[DeviceGroup[]]$DeviceGroup,
		[Parameter(Position = 1)]
		[switch]$IDOnly
	)

	begin
	{
		$DeviceIDs = @()
	}

	process
	{
		foreach ($Group in $DeviceGroup)
		{
			Write-Verbose "Gathering devices under $($Group.FormattedName)"
			$Result = (Use-BCMRestAPI "/group/subgroup/$($Group.ID)/devices?count=0&brief=true").Devices.ID

		if ($Result.count -eq 0)
		{
				Write-Verbose "No devices are assigned to $($Group.FormattedName)"
		}
		else
		{
				$Result | ForEach-Object { $DeviceIDs += [int]$_ }
		}
	}
	}

	end
	{
		$DeviceIDs = $DeviceIDs | Select-Object -Unique
		if ($IDOnly.IsPresent) { Write-Output $DeviceIDs }
		else { $DeviceIDs | ForEach-Object { [Device]::New($_) | Write-Output } }
	}
}

<#
	.SYNOPSIS
		Get assignments of devices to Operational Rules

	.PARAMETER OpRule
		The Operational Rule to use

	.PARAMETER Device
		The device that you want to filter the OpRule assignments down to.

	.PARAMETER Status
		The front end status that you want to filter the OpRule assignments down to.
		Allowable values are:
		Assigned, Assignment Paused, Assignment Sent, Assignment Waiting, Executed, Execution Failed, Not Received, Ready to Run, Reassignment Waiting, Sending Impossible, Unassignment Paused, Unassignment Waiting, Update Sent, Update Waiting, Updated, Verification Failed

	.PARAMETER DeviceGroup
		The device group that you want to filter the OpRule assignments down to.

	.PARAMETER RawData
		This returns the raw API response, without any property flattening or value translations

	.EXAMPLE
		PS C:\> Get-OpRuleAssignment -OpRule 'OPRULE_CrowdStrike_CrowdStrikeWindowsSensor_R14'

	.EXAMPLE
		PS C:\> Get-OpRuleAssignment -OpRule 'OPRULE_Symantec_SEP_R12' -Device 'VDPKG0011'

	.EXAMPLE
		PS C:\> Get-OpRuleAssignment -OpRule 'OPRULE_Symantec_SEP_R12' -Device 'VDPKG0011' -RawData

	.EXAMPLE
		PS C:\> Get-OpRuleAssignment -OpRule 'OPRULE_LastPass_LastPass_R6' -Status 'Execution Failed'

	.EXAMPLE
		PS C:\> Get-OpRuleAssignment -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R12' -DeviceGroup 'GRP900_VMware_HorizonAgent-Tools_NOW'

	.EXAMPLE
		PS C:\> Get-OpRuleAssignment -OpRule 'OPRULE_Cortado_ThinPrintDesktopAgent_R6' -DeviceGroup 'GRP900_Cortado_ThinPrintDesktopAgent_NEW' -Status 'Executed'
#>
function Get-OpRuleAssignment
{
	[CmdletBinding(DefaultParameterSetName = 'Normal')]
	[OutputType([OpRule], [PSCustomObject])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[OpRule[]]$OpRule,
		[Parameter(Position = 1)]
		[Device[]]$Device,
		[Parameter(ParameterSetName = 'Normal')]
		[ValidateSet('Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Executed', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule')]
		[string]$Status,
		[Parameter(ParameterSetName = 'Normal')]
		[DeviceGroup]$DeviceGroup,
		[Parameter(ParameterSetName = 'Raw')]
		[switch]$RawData
	)
	process
	{
		foreach ($OpRuleObject in $OpRule)
		{
			Write-Verbose "Gathering device IDs of devices assigned to $($OpRuleObject.FormattedName)"
			$Result = (Use-BCMRestAPI "/oprule/rule/$($OpRuleObject.ID)/device/assignments?brief=true&count=0").Assignments

			if ($Device)
			{
				Write-Verbose "Filtering assignments down to devices listed in the Device parameter"
				$Result = $Result | Where-Object { $_.Device.ID -in $Device.ID }
				$MissingDevices = $Device | Where-Object { $_.ID -NotIn $Result.Device.ID }

				if ($MissingDevices)
				{
					$MissingDevices | ForEach-Object { Write-Warning "$($_.FormattedName) is not in $($OpRuleObject.FormattedName)" }
					if ($MissingDevices.Count -eq $Device.Count) { Write-Warning "None of these machines are assigned to $($OpRuleObject.FormattedName)" }
				}
			}

			if ($Result.count -eq 0)
			{
				Write-Verbose "There are no relevant devices assigned to $($OpRuleObject.FormattedName)"
				break
			}

			if ($RawData.IsPresent) { $Assignments = $Result }
			else { $Assignments = $Result.ID | ForEach-Object { [OpRuleAssignment]::New($OpRuleObject, $_) } }

			if ($Status)
			{
				Write-Verbose "Filtering assignments down to devices with a status of $Status"
				$Assignments = $Assignments | Where-Object Status -EQ $Status
			}

			if ($DeviceGroup)
			{
				Write-Verbose "Filtering assignments down to assignments from $($DeviceGroup.FormattedName)"
				$Assignments = $Assignments | Where-Object { $_.DeviceGroup.ID -eq $DeviceGroup.ID }
			}

			if ($Assignments.count -eq 0) { Write-Verbose "There are no relevant devices assigned to $($OpRuleObject.FormattedName)" }
			else { Write-Output $Assignments }
		}
	}
}

<#
	.SYNOPSIS
		Updates the status of an OpRule Assignment

	.DESCRIPTION
		Translates the front end status name to the backend status name
		Updates the OpRule assignment using the backend status name and the assignment ID

	.PARAMETER NewStatus
		The front end name of the OpRule assignment status
		Prepopulated from: Get-Enums OpRuleStatus | % {Get-BCMFrontEndText $_ -TranslationOnly}
		Allowable values are 'Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Executed', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule'

	.PARAMETER Assignment
		The OpRule Assignment to use

	.EXAMPLE
		PS C:\> Update-OpRuleAssignmentStatus -NewStatus 'Reassignment Waiting' -Assignment $OpRuleAssignment

	.INPUTS
		BCMAPI.Assignment.OpRuleAssignment
		String
#>
function Update-OpRuleAssignmentStatus
{
	[CmdletBinding()]
	[OutputType([OpRule], [PSCustomObject])]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateSet('Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Executed', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule')]
		[string]$NewStatus,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[OpRuleAssignment[]]$Assignment
	)

	begin { $BackendStatusName = ($StatusTranslation.GetEnumerator() | Where-Object Value -eq $NewStatus).Name }
	process
	{
		foreach ($OpRuleAssignment in $Assignment)
		{
			$Body = "{`"status`":`"$BackendStatusName`"}"
			$Result = Use-BCMRestAPI -URL "/oprule/rule/device/assignment/$($OpRuleAssignment.ID)" -Body $Body -Method PUT
			if ($Result.ErrorCode -eq 0)
			{
				Write-Verbose "Updated status of $($OpRuleAssignment.OpRule.FormattedName) on $($OpRuleAssignment.Device.FormattedName) to $NewStatus" -InformationAction Continue
				$Assignment.RefreshStatus()
				Write-Output $Assignment
			}
			else { Throw "Failed to activate $($OpRuleAssignment.OpRule.FormattedName) on $($OpRuleAssignment.Device.FormattedName) with $ErrorCode" }
		}
	}
}

<#
	.SYNOPSIS
		Supresses the command prompt until one or all of the OpRule Assignments are in a Final Status. Can send an email alert.

	.PARAMETER Assignment
		The Operational Rule Assignment to use

	.PARAMETER MaxWaitTimeMinutes
		The maximum number of minutes that you want to wait for the OpRule Assignments to complete

	.PARAMETER RefreshIntervalSeconds
		How often you want the status updates in the Information stream

	.PARAMETER EmailAddress
		The email addresses that you want the completion notification sent to.
		Must be used with the EmailMe parameter else no email will be sent.

	.PARAMETER EmailMe
		Use this if you want an email notification along with the console notification
		The email notification is an HTML email with a table containing the OpRule Assignment ID, OpRuleName, DeviceName, and status
		The table formatting is controlled by an internal CSS

	.EXAMPLE
		PS C:\> Wait-OpRuleAssignment -Assignment $OpRuleAssignment

	.EXAMPLE
		PS C:\> Wait-OpRuleAssignment -Assignment $OpRuleAssignment -EmailAddress "John.Smith@$CompanyDomainName" -EmailMe

	.EXAMPLE
		PS C:\> Wait-OpRuleAssignment -Assignment $OpRuleAssignment -MaxWaitTimeMinutes 60

	.EXAMPLE
		PS C:\> Wait-OpRuleAssignment -Assignment $OpRuleAssignment -RefreshIntervalSeconds 30

	.INPUTS
		BCMAPI.Assignment.OpRuleAssignment
		Int
		String
#>
function Wait-OpRuleAssignment
{
	[CmdletBinding()]
	[OutputType([OpRuleAssignment])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[OpRuleAssignment[]]$Assignment,
		[int]$MaxWaitTimeMinutes = 20,
		[int]$RefreshIntervalSeconds = 60,
		[string[]]$EmailAddress = $MainUsersEmail,
		[switch]$EmailMe
	)

	#This needs to be updated to process all the assignments at once when being passed through the pipeline. As it's currently processing them one at a time

	begin
	{
		$Recipient = $EmailAddress

		$InternalCSS = @"
<style>
TABLE {
	border-width: 1px;
	border-style: solid;
	border-color: black;
	border-collapse: collapse;
}
TH {
	border-width: 1px;
	padding: 3px;
	border-style: solid;
	border-color: black;
	background-color: #6495ED;
	color: white;
}
TD {
	border-width: 1px;
	padding: 3px;
	border-style: solid;
	border-color: black;
}
</style>
"@

		$StartingHTML = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>' + "`r`n" + $InternalCSS + "`r`n" + '<title>HTML TABLE</title>
</head><body>'
		$EndingHTML = '</body></html>'
	}

	process
	{
		$FinalStatuses = 'Dependency Check Failed', 'Executed', 'Execution Failed', 'Publication Planned', 'Package Missing', 'Sending impossible', 'Step Missing', 'Unassignment Paused', 'Update Paused', 'Verification Failed'
		$WaitTimeMinutes = 0

		Write-Information "Current status is:"
		Write-Information "$($Assignment.RefreshStatus() | Out-String)"

		$AssignmentsWaitingOn = $Assignment | Where-Object Status -NotIn $FinalStatuses

		while ($AssignmentsWaitingOn -ne $null)
		{
			if ($WaitTimeMinutes -ge $MaxWaitTimeMinutes)
			{
				Write-Warning "These assignments failed to fail or succeed within $MaxWaitTimeMinutes minutes:"
				Write-Warning ($AssignmentsWaitingOn | Format-Table ID, OpRuleName, DeviceName, Status -AutoSize | Out-String)
				break
			}

			$OLDWaitingOn = $AssignmentsWaitingOn

			$OLDStatuses = $OLDWaitingOn | ForEach-Object { "$($_.ID)_$($_.Status)" }
			Write-Debug "Old statuses are:`r`n$($OLDStatuses | Format-List | Out-String)"

			$AssignmentsWaitingOn = $AssignmentsWaitingOn.RefreshStatus() | Where-Object Status -NotIn $FinalStatuses

			$NEWStatuses = $AssignmentsWaitingOn | ForEach-Object { "$($_.ID)_$($_.Status)" }
			Write-Debug "New statuses are:`r`n$($OLDStatuses | Format-List | Out-String)"

			if ($AssignmentsWaitingOn -eq $null) { break }

			if ((Compare-Object $OLDStatuses $NEWStatuses) -eq $null) { Write-Information "No updates, wait time is $WaitTimeMinutes minutes" }
			else
			{
				Write-Information "Wait time is $WaitTimeMinutes minutes, waiting on these assignments:"
				Write-Information "`r`n$($AssignmentsWaitingOn | Out-String)`r`n"
			}

			$WaitTimeMinutes = $WaitTimeMinutes + ($RefreshIntervalSeconds/60)
			Start-Sleep $RefreshIntervalSeconds
		}

		$UniqueStatuses = $Assignment.RefreshStatus() | Select-Object -ExpandProperty Status -Unique
		if (($UniqueStatuses.Count -eq 1) -and ($UniqueStatuses -eq 'Executed'))
		{
			Write-Output "The OpRule assignments completed successfully"

			if ($EmailMe)
			{
				$Message = @()
				$Message += $StartingHTML
				$Message += "<p>The OpRule assignments completed successfully:</p>"
				$Message += $Assignment | ConvertTo-Html -Property ID, OpRuleName, DeviceName, Status -Fragment
				$Message += $EndingHTML
				Send-MailMessage -From "do_not_reply@$CompanyDomainName" -To $EmailAddress -Subject 'SUCCESS - OpRule Assignments' -SmtpServer "internalrelay.$CompanyDomainName" -Body ($Message | Out-String) -BodyAsHtml -WarningAction SilentlyContinue
			}
		}
		else
		{
			$NonExecuted = $Assignment | Where-Object Status -NE 'Executed'
			$NonExecuted.RefreshAllProperties()
			Write-Warning 'These OpRule assignments failed:'
			Write-Warning ($NonExecuted | Format-Table ID, OpRuleName, DeviceName, Status, ErrorCode, FailedStep | Out-String).Trim()

			if ($EmailMe)
			{
				$Message = @()
				$Message += $StartingHTML
				$Message += "<p>These OpRule assignments failed:</p>"
				$Message += $Assignment | ConvertTo-Html -Property ID, OpRuleName, DeviceName, Status, ErrorCode, FailedStep -Fragment
				$Message += $EndingHTML
				Send-MailMessage -From "do_not_reply@$CompanyDomainName" -To $EmailAddress -Subject 'FAILURE - OpRule Assignments' -SmtpServer "internalrelay.$CompanyDomainName" -Body ($Message | Out-String) -BodyAsHtml -WarningAction SilentlyContinue
			}
		}
	}
}

<#
	.SYNOPSIS
		Add a device to an OpRule

	.PARAMETER Device
		The device to use

	.PARAMETER OpRule
		The operational rule to use

	.PARAMETER Active
		This adds the device to the OpRule in an active state, elsewise the device is assigned in a paused state.
		If this is chosen and the device is already assigned to the OpRule, the OpRule will be reassigned to the device

	.EXAMPLE
		PS C:\> Add-DevicetoOpRule -Device 'VDPKG0010' -OpRule 'OPRULE_JET_JETTools_R1'

	.EXAMPLE
		PS C:\> Add-DevicetoOpRule -Device 'VDPKG0011' -OpRule 'OPRULE_JTS_CStools_R4' -Active
#>
function Add-DevicetoOpRule
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[Device[]]$Device,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[OpRule]$OpRule,
		[switch]$Active
	)

	begin { $RawOpRuleAssignments = Get-OpRuleAssignment -OpRule $OpRule -RawData }
	process
	{
		foreach ($DeviceObject in $Device)
		{
			if ($DeviceObject.ID -in $RawOpRuleAssignments.Device.ID)
			{
				$AssignmentID = ($RawOpRuleAssignments | Where-Object { $_.Device.ID -eq $DeviceObject.ID }).ID
				$Assignment = [OpRuleAssignment]::New($OpRule, $AssignmentID)
				Write-Warning "$($DeviceObject.FormattedName) is already assigned to $($OpRule.FormattedName), with a status of $($Assignment.Status)"
				if ($Active.IsPresent)
				{
					Write-Warning "Reassigning $($DeviceObject.FormattedName) to $($OpRule.FormattedName), because the Active switch was chosen"
					$Assignment.UpdateStatus('Reassignment Waiting')
				}
			}
			else
			{
				Write-Verbose "Adding $($DeviceObject.FormattedName) to $($OpRule.FormattedName)"
				if ($Active.IsPresent) { $Result = Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/device/$($DeviceObject.ID)" -Method PUT }
				else { $Result = Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/device/$($DeviceObject.ID)`?activation=manual" -Method PUT }

				$AssignmentID = $Result.Assignment.ID

				if ($AssignmentID -eq $null) { Throw "Failed to assign $($DeviceObject.FormattedName) to $($OpRule.FormattedName)" }
				else
				{
					$Assignment = [OpRuleAssignment]::New($OpRule, $AssignmentID)
					Write-Verbose "Successfully asssigned $($DeviceObject.FormattedName) to $($OpRule.FormattedName) with an assignment ID of $AssignmentID"
				}
			}
			Write-Output $Assignment
		}
	}
}

<#
	.SYNOPSIS
		Adds a device to a Device Group

	.PARAMETER Device
		The device to use

	.PARAMETER DeviceGroup
		The device group to use

	.EXAMPLE
		PS C:\> Add-DevicetoDeviceGroup -Device 'VDPKG0009' -DeviceGroup 'APPGRP_Adobe_Reader_CUR'

	.INPUTS
		BCMAPI.Device
		BCMAPI.Object.DeviceGroup
#>
function Add-DevicetoDeviceGroup
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Device[]]$Device,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[DeviceGroup]$DeviceGroup
	)

	process
	{
		foreach ($DeviceObject in $Device)
		{
			Write-Verbose "Adding $($DeviceObject.FormattedName) to $($DeviceGroup.FormattedName)"
			$Assignment = Use-BCMRestAPI "/group/subgroup/$($DeviceGroup.ID)/device/$($DeviceObject.ID)" -Method PUT

			if ($Assignment.ErrorCode -eq 0) { Write-Verbose "Successfully added $($DeviceObject.FormattedName) to $($DeviceGroup.FormattedName)" }
			elseif ($Assignment -eq $null) { Write-Warning "$($DeviceObject.FormattedName) is already in $($DeviceGroup.FormattedName)" }
			else { Throw "Failed to add $($DeviceObject.FormattedName) to $($DeviceGroup.FormattedName), see $Assignment" }
		}
	}
}

<#
	.SYNOPSIS
		Gathers the assignments of Device Groups to OpRules

	.DESCRIPTION
		A detailed description of the Get-DeviceGroupAssignedtoOpRule function.

	.PARAMETER OpRule
		The OpRule to use

	.PARAMETER DeviceGroupOnly
		Use this if you want an DeviceGroup object returned instead of a OpRuleDeviceGroupAssignment object

	.PARAMETER DeviceGroupIDOnly
		Use this if you want the device group IDs returned instead of a OpRuleDeviceGroupAssignment object

	.EXAMPLE
		PS C:\> Get-DeviceGroupAssignedtoOpRule -OpRule 'OPRULE_Google_Chrome-Enterprise_R15'

	.INPUTS
		BCMAPI.Object.OpRule
#>
function Get-DeviceGroupAssignedtoOpRule
{
	[CmdletBinding()]
	[OutputType([OpRuleDeviceGroupAssignment], [DeviceGroup], [int])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[OpRule[]]$OpRule,
		[switch]$DeviceGroupOnly,
		[switch]$DeviceGroupIDOnly
	)

	process
	{
		foreach ($Rule in $OpRule)
		{
			Write-Verbose "Looking for device groups assigned to $($Rule.FormattedName)"
			$Result = (Use-BCMRestAPI "/oprule/rule/$($Rule.ID)/device/group/assignments?brief=true").Assignments
			if ($Result.Count -eq 0) { Write-Warning "There are no Device Groups assigned to $($Rule.FormattedName)" }
			elseif ($DeviceGroupIDOnly.IsPresent) { Write-Output $Result.DeviceGroup.ID }
			elseif ($DeviceGroupOnly.IsPresent)
			{
				$Result.DeviceGroup.ID | ForEach-Object { [DeviceGroup]::New([int]$_) | Write-Output }
			}
			else
			{
				$Result.ID | ForEach-Object { [OpRuleDeviceGroupAssignment]::New($Rule, $_) | Write-Output }
			}
		}
	}
}

<#
	.SYNOPSIS
		Adds a device group to an operational rule

	.PARAMETER DeviceGroup
		The device group to use

	.PARAMETER OpRule
		The operational rule to use

	.PARAMETER Active
		This adds the device group to the OpRule in an active state, elsewise the device group is assigned in a paused state.

	.EXAMPLE
		PS C:\> Add-DeviceGrouptoOpRule -DeviceGroup "APPGRP_$ShortCompanyName_WindowsPathEnumerate_CUR" -OpRule "OPRULE_$ShortCompanyName_WindowsPathEnumerate_R1"

	.EXAMPLE
		PS C:\> Add-DeviceGrouptoOpRule -DeviceGroup 'APPGRP_JTS_UnquotedPathsFix_CUR' -OpRule 'OPRULE_JTS_UnquotedPathsFix_R1' -Active

	.INPUTS
		BCMAPI.Object.DeviceGroup
		BCMAPI.Object.OpRule

	.NOTES
		01.20.2021 - Alex Larner - Updated to set new assignment to upload status after every execution
#>
function Add-DeviceGrouptoOpRule
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[DeviceGroup[]]$DeviceGroup,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[OpRule]$OpRule,
		[switch]$Active
	)

	process
	{
		foreach ($Group in $DeviceGroup)
		{
			if ($Active.IsPresent) { $Result = Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/device/group/$($Group.ID)" -Method PUT }
			else { $Result = Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/device/group/$($Group.ID)`?activation=manual" -Method PUT }

			if ($Result.Assignment.ID -ne $null)
			{
				Write-Verbose "Successfully assigned $($OpRule.FormattedName) to $($Group.FormattedName)"

				Write-Verbose "Setting new assignment to upload status after every execution"
				$Assignment = [OpRuleDeviceGroupAssignment]::New($OpRule, $Result.Assignment.ID)
				Update-OpRuleDeviceGroupAssignment -Assignment $Assignment -UploadStatusAfterEveryExecution $true
			}
			else { Write-Error "Failed to assign $($OpRule.FormattedName) to $($Group.FormattedName), with this response:`n`r$Result" }
		}
	}
}

<#
	.SYNOPSIS
		Remove a device group operational rule assignment

	.PARAMETER Assignment
		The device group operational rule assignment to use

	.EXAMPLE
		PS C:\> Remove-DeviceGroupfromOpRule -Assignment $Assignment

	.INPUTS
		BCMAPI.Assignment.OpRuleDeviceGroupAssignment
#>
function Remove-DeviceGroupfromOpRule
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[OpRuleDeviceGroupAssignment[]]$Assignment
	)

	process
	{
		Write-Verbose "Unassigning $($Assignment.DeviceGroupName) from $($Assignment.OpRuleName)"
		$Result = Use-BCMRestAPI "/oprule/rule/device/group/assignment/$($Assignment.ID)" -Method DELETE

		if ($Result.ErrorCode -eq 0) { Write-Verbose "Successfully unassigned $($Assignment.DeviceGroupName) from $($Assignment.OpRuleName)" }
		else { Write-Warning "Failed to unassign with this result:`n`r$Result" }
	}
}

function Update-OpRuleDeviceGroupAssignment
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[OpRuleDeviceGroupAssignment[]]$Assignment,
		[int]$AssignEnableTime,
		[bool]$AssignmentActivation,
		[bool]$BypassTransferWindow,
		[bool]$InstallationType,
		[bool]$RunAsCurrentUser,
		[bool]$RunWhileExecutionFails,
		[int]$ScheduleID,
		[int]$SpecialCase,
		[bool]$UploadIntermediaryStatusValues,
		[bool]$UploadStatusAfterEveryExecution,
		[bool]$WakeupDevices
	)
	begin
	{
		$FrontendBackendTranslation = @{
			AssignEnableTime = 'assignEnableTime'
			AssignmentActivation = 'isActive'
			BypassTransferWindow = 'bypassTransferWindows'
			InstallationType = 'networkInstall'
			RunAsCurrentUser = 'runAsCurrentUser'
			RunWhileExecutionFails = 'executeWhileFails'
			ScheduleID	     = 'scheduleId'
			SpecialCase = 'specialCase'
			UploadIntermediaryStatusValues = 'uploadStatus'
			UploadStatusAfterEveryExecution = 'uploadStatusEveryExec'
			WakeupDevices    = 'wakeupDevices'
		}

		$Params = $PSBoundParameters
		$PSBoundParameters.Keys | Where-Object { $_ -notin $FrontendBackendTranslation.Keys } | ForEach-Object { $Params.Remove($_) | Out-Null }

		$Body = [pscustomobject]@{ }
		foreach ($UsedParameter in $Params.Keys)
		{
			$Body | Add-Member -MemberType NoteProperty -Name $FrontendBackendTranslation[$UsedParameter] -Value (Get-Variable $UsedParameter).Value
		}
		$JSONBody = $Body | ConvertTo-Json
		Write-Debug "JSON Body for API call:`r`n$JSONBody"
	}
	process
	{
		foreach ($Assign in $Assignment)
		{
			$Result = Use-BCMRestAPI "/oprule/rule/device/group/assignment/$($Assign.ID)" -Method PUT -Body $JSONBody
			if ($Result.ErrorCode -ne 0) { Write-Output $Result }
		}
	}
}

<#
	.SYNOPSIS
		Create a new blank OpRule with no steps

	.PARAMETER Name
		The name to use for the new OpRule

	.PARAMETER OpRuleFolder
		The operational rule folder to place the new operational rule in
		Default is the '_OPRULES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS' folder

	.EXAMPLE
		PS C:\> New-OpRule -Name 'OPRULE_Sample_Test_R1'

	.EXAMPLE
		PS C:\> New-OpRule -Name 'OPRULE_Sample_Test_R1' -OpRuleFolder 'Engineers'

	.INPUTS
		BCMAPI.Object.OpRuleFolder
		String
#>
function New-OpRule
{
	[CmdletBinding()]
	[OutputType([OpRule])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string[]]$Name,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[OpRuleFolder]$OpRuleFolder = (Get-BCMCommonObject _OPRULES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS -ObjectType 'Operational Rule Folder')
	)

	process
	{
		foreach ($NewOpRuleName in $Name)
		{
			$Body = "{
				`"name`":`"$NewOpRuleName`",
				`"type`":`"Operational Rule`"
			}"

			$Result = Use-BCMRestAPI -URL "/oprule/folder/$($OpRuleFolder.ID)/rule" -Body $Body -Method PUT

			if ($Result.Rule.ID -ne $null)
			{
				Write-Verbose "$NewOpRuleName was created with an OpRule ID of $($Result.Rule.ID)"
				Write-Output ([OpRule]::New([int]$Result.Rule.ID))
			}
			else { throw "$NewOpRuleName was not created: $Result" }
		}
	}
}

<#
	.SYNOPSIS
		Removes a device from a device group

	.PARAMETER Device
		The device to remove

	.PARAMETER DeviceGroup
		The device group to be removed from.

	.EXAMPLE
		PS C:\> Remove-DevicefromDeviceGroup -Device 'VDPKG0011' -DeviceGroup 'APPGRP_Adobe_AcrobatProDC_CUR'

	.NOTES
		If the API call fails due to a bad input, i.e. Device doesn't exist, Device Group doesn't exist, Device isn't in the Device Group, the API result will just be blank. There will not be an error code returned.

	.INPUTS
		BCMAPI.Device
		BCMAPI.Object.DeviceGroup
#>
function Remove-DevicefromDeviceGroup
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[Device[]]$Device,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[DeviceGroup]$DeviceGroup
	)

	process
	{
		foreach ($DeviceObject in $Device)
		{
			Write-Verbose "Removing $($DeviceObject.FormattedName) from $($DeviceGroup.FormattedName)"
			$Result = Use-BCMRestAPI "/group/subgroup/$($DeviceGroup.ID)/device/$($DeviceObject.ID)" -Method DELETE

			if ($Result.ErrorCode -eq 0) { Write-Verbose "Successfully removed $($DeviceObject.FormattedName) from $($DeviceGroup.FormattedName)" }
			else { Write-Warning "Failed to remove $($DeviceObject.FormattedName) from $($DeviceGroup.FormattedName)" }
		}
	}
}

<#
	.SYNOPSIS
		Removes the assignment of a Device to an OpRule

	.PARAMETER Assignment
		The operational rule assignment to remove

	.PARAMETER Activation
		Whether or not the unaassignment is to be effective immediately (automatic), or in a paused state (manual)
		Allowable values are: automatic and manual

	.EXAMPLE
		PS C:\> Remove-OpRuleAssignment -Assignment $OpRuleAssignment

	.EXAMPLE
		PS C:\> Remove-OpRuleAssignment -Assignment $OpRuleAssignment -Activation manual

	.INPUTS
		BCMAPI.Assignment.OpRuleAssignment
#>
function Remove-OpRuleAssignment
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[OpRuleAssignment[]]$Assignment,
		[ValidateSet('automatic', 'manual')]
		[string]$Activation = 'automatic'
	)

	process
	{
		foreach ($OpRuleAssignment in $Assignment)
		{
			$Result = Use-BCMRestAPI "/oprule/rule/device/assignment/$($OpRuleAssignment.ID)?activation=$Activation" -Method DELETE
			if ($Result.ErrorCode -eq 0) { Write-Verbose "Successfully removed $($OpRuleAssignment.Device.FormattedName) from $($OpRuleAssignment.OpRule.FormattedName)" }
			else { Write-Warning "Failed to remove $($OpRuleAssignment.Device.FormattedName) from $($OpRuleAssignment.OpRule.FormattedName)" }
		}
	}
}

<#
	.SYNOPSIS
		Removes ALL deprecated devices from ALL OpRules

	.DESCRIPTION
		Gathers all the devices in the 'All Deprecated Devices' compliance group
		Gathers all the OpRule assignments from ALL OpRules (This will take a long time)
		Filters down the assignments to those just for the deprecated devices, and removes them

	.EXAMPLE
		PS C:\> Remove-DeprecatedDeviceFromOpRule
#>
function Remove-DeprecatedDeviceFromOpRule
{
	[CmdletBinding(ConfirmImpact = 'High')]
	param ()

	$DeprecatedDG = Get-BCMCommonObject -Name 'All Deprecated Devices' -ObjectType 'Device Group'
	$DeprecatedIDs = Get-DeviceGroupDevices $DeprecatedDG -IDOnly

	Write-Verbose "Gathering all OpRules"
	$AllOpRuleIDs = Get-BCMID -Name '%' -ObjectType 'Operational Rule'

	Write-Verbose "Gathering all OpRule assignments"
	$AllOpRuleAssignments = $AllOpRuleIDs | ForEach-Object {
		Write-Debug "Gathering assignments under OpRule ID $_"
		(Use-BCMRestAPI "/oprule/rule/$_/device/assignments?brief=true&count=0").Assignments
	}

	Write-Verbose "Deleting OpRule assignments"
	$AllOpRuleAssignments | Where-Object { $_.Device.ID -in $DeprecatedIDs } | Select-Object -ExpandProperty ID | ForEach-Object {
		Write-Debug "Deleting Assignment ID $_"
		Use-BCMRestAPI "/oprule/rule/device/assignment/$_" -Method DELETE
	}
}

<#
	.SYNOPSIS
		Creates a VM based on the details in a CSV

	.DESCRIPTION
		Builds a VM using the settings in a CSV
		Adds the 'smbios.assettag'
		Adds the correct network adapter
		Starts the VM

	.PARAMETER FactoryBuildTemplate
		This must be a CSV that contains these columns:
		DeviceName (The name of the new device)
		Folder (The folder for the new VMs to be created in, i.e. 'Factory')
		VMHost (The full host name, including ".$CompanyDomainName")
		Datastore (The datastore to create the new device on, i.e. 'vdihost7002a-ilio-f1')
		vCenter (The vCenter to create the VM on, i.e. 'vdvcentervd001a')
		Network (The network for the VM's network adapter, i.e. $NewVMNetworkAdapterName)
		Template (The VM template to create the new VMs off of, i.e. $AlmostVanillaOSVMTemplateName)

	.EXAMPLE
		PS C:\> Build-VM -FactoryBuildTemplate "$ITNetworkShare\AutomatedFactory\Logs\VM Build CSVs\VMBuild_2020-02-04__17-31-22_amfap0p.csv"

	.INPUTS
		String
#>
function Build-VM
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateScript({ (Test-Path $_) -and ((Split-Path $_ -Leaf) -Like '*.csv') })]
		[string]$FactoryBuildTemplate
	)

	#Connect-VIServer ((Import-Csv $FactoryBuildTemplate).vCenter | Select-Object -Unique) -ErrorAction Stop | Out-Null

	ForEach ($Device in Import-Csv $FactoryBuildTemplate)
	{
		$VMFolder = Get-Folder $Device.Folder -Server $Device.vCenter
		if (-not ($VMFolder)) { throw "Folder $($Device.Folder) does not exist on $($Device.vCenter)" }
		elseif ($VMFolder.Count -gt 1) { throw "There are $($VMFolder.Count) folders called $($Device.Folder) on $($Device.vCenter)" }

		Write-Verbose "Building $($Device.DeviceName) on $($Device.Datastore) on $($Device.VMHost)"
		#This takes about 4 minutes per machine
		$VM = New-VM -VMHost $Device.VMHost -Name $Device.DeviceName -Location $VMFolder -Datastore $Device.Datastore -Server $Device.vCenter -Template $Device.Template
		New-AdvancedSetting -Entity $Device.DeviceName -Name "smbios.assettag" -Value $Device.DeviceName -Confirm:$False | Out-Null
		$Portgroup = Get-VDPortgroup -Server $Device.vCenter -Name $Device.Network
		$VM | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $Portgroup -Confirm:$False | Out-Null
		$VM | Start-VM | Out-Null
	}
	Return (Get-VM (Import-Csv $FactoryBuildTemplate).DeviceName)
}

<#
	.SYNOPSIS
		Wait for a new computer to appear in BCM or Active Directory

	.PARAMETER ComputerName
		The name of the device to look for

	.PARAMETER System
		The system to look for the device in: 'Active Directory' or 'BMC Client Management'

	.PARAMETER MaxWaitTimeMinutes
		The maximum amount of time that you want to wait for the device to appear

	.PARAMETER RefreshIntervalSeconds
		The amount of seconds between checks for the device

	.EXAMPLE
		PS C:\> Wait-Computer -ComputerName VD0030000 -System 'Active Directory'

	.EXAMPLE
		PS C:\> Wait-Computer -ComputerName VD0030000 -System 'Active Directory' -MaxWaitTimeMinutes 60

	.EXAMPLE
		PS C:\> Wait-Computer -ComputerName VD0030000 -System 'BMC Client Management' -RefreshIntervalSeconds 120

	.NOTES
		This does not use the Active Directory module, instead it adds the 'System.DirectoryServices.AccountManagement' assembly to do the Active Directory lookup

	.INPUTS
		Int
		String
#>
function Wait-Computer
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string[]]$ComputerName,
		[Parameter(Mandatory = $true)]
		[ValidateSet('Active Directory', 'BMC Client Management')]
		$System,
		[int]$MaxWaitTimeMinutes = 45,
		[int]$RefreshIntervalSeconds = 60
	)

	$ComputerObject = @()

	switch ($System)
	{
		'Active Directory' {
			Add-Type -AssemblyName System.DirectoryServices.AccountManagement
			$ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
			$Context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ContextType, $CompanyDomainName, "DC=$RootDomain,DC=com"
			$ComputerName | ForEach-Object {
				$FoundObject = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($Context, $_)
				if ($FoundObject) { $ComputerObject += $FoundObject }
			}
		}
		'BMC Client Management' {
			#$DeviceObjectType = Get-BCMObject -Name '_DB_OBJECTTYPE_DEVICE_' -ObjectType ObjectType
			#$DeviceNameAttribute = Get-BCMObjectTypeAttribute -ObjectType $DeviceObjectType -BackEndName '_DB_ATTR_NAME_'
			#Get-BCMObjectInstance -Value $ComputerName -ObjectType $DeviceObjectType -Attribute $DeviceNameAttribute -Operator Equals -Source Topology | ForEach-Object { $ComputerObject += $_ }

			Get-BCMCommonObject -Name $ComputerName -ObjectType Device | ForEach-Object {
				if ($_.LifeCycleStatus -eq 'Retired') { Write-Warning "$($_.FormattedName) is deprecated" }
				else
				{
					if ($_ -ne $null) { $ComputerObject += $_ }
				}
			}
		}
	}

	if ($ComputerObject) { Write-Verbose "Found $($ComputerObject.Count) of $($ComputerName.Count) devices:`r`n$($ComputerObject.Name | Format-List | Out-String)" }

	$WaitTimeMinutes = 0
	while ($ComputerObject.Count -ne $ComputerName.Count)
	{
		$WaitingOn = $ComputerName | Where-Object { $_ -notin $ComputerObject.Name }

		$Found = switch ($System)
		{
			'Active Directory' { $WaitingOn | ForEach-Object { [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($Context, $_) } | Where-Object { $_ -ne $null } }
			'BMC Client Management' {
				#Get-BCMObjectInstance -Value $WaitingOn -ObjectType $DeviceObjectType -Attribute $DeviceNameAttribute -Operator Equals -Source Topology
				Get-BCMCommonObject -Name $WaitingOn -ObjectType Device | Where-Object LifeCycleStatus -NE 'Retired'
			}
		}

		if ($Found -ne $null)
		{
			Write-Verbose "Found:`r`n$($Found.Name | Format-List | Out-String)"
			$Found | ForEach-Object { $ComputerObject += $_ }
			<#
			if ($Found.Count -eq $WaitingOn.Count)
			{
				Write-Information "SUCCESS: All the devices have been found:`r`n$($ComputerObject | Format-Table | Out-String)" -InformationAction Continue
				Return
			}
			#>
		}

		if ($WaitTimeMinutes -ge $MaxWaitTimeMinutes)
		{
			$ErrorMessage = "These devices failed to appear in $System within $MaxWaitTimeMinutes minutes:`r`n$($WaitingOn | Format-List | Out-String)"
			Send-FactoryAlert -Subject "Failed to Find New Devices in $System" -Body $ErrorMessage
			#Throw $ErrorMessage
			break
		}
		Write-Verbose "Wait Time is: $WaitTimeMinutes Minutes, waiting for these devices to appear in $System`:`r`n$($WaitingOn | Format-List | Out-String)"
		$WaitTimeMinutes = [Math]::Round($WaitTimeMinutes + ($RefreshIntervalSeconds/60), 2)
		Start-Sleep $RefreshIntervalSeconds
	}
	Return $ComputerObject
}

<#
	.SYNOPSIS
		Adds a device to an Active Directory group

	.PARAMETER ComputerName
		The name of the device to add to the group

	.PARAMETER ADGroupName
		The name of the Active Directory group to add devices to

	.EXAMPLE
		PS C:\> Add-DevicetoADGroup -ComputerName 'VDPKG0011' -ADGroupName "$ShortCompanyName - Client Services RDP Policy (1.1)"

	.NOTES
		Does not use the Active Directory PowerShell Module, instead this adds the 'System.DirectoryServices.AccountManagement' assembly and uses that

	.INPUTS
		String
#>
function Add-DevicetoADGroup
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ComputerName,
		[Parameter(Mandatory = $true)]
		[string]$ADGroupName
	)

	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
	$Context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ContextType, $CompanyDomainName, "DC=$RootDomain,DC=com"

	$ComputerObject = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($Context, $ComputerName)
	if ($ComputerObject -eq $null) { Throw "$ComputerName does not exist" }

	$ADGroupObject = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($Context, $ADGroupName)
	if ($ADGroupObject -eq $null) { Throw "$ADGroupName does not exist" }

	Switch ($ComputerObject.IsMemberOf($ADGroupObject))
	{
		$True { "Device $ComputerName is already a member of the group $ADGroupName." }
		$False {
			$ADGroupObject.Members.Add($ComputerObject)

			$ADGroupObject.Save()

			Switch ($ComputerObject.IsMemberOf($ADGroupObject))
			{
				$True { "Device $ComputerName successfully added to the group $ADGroupName." }
				$False { Throw "Unable to add device $ComputerName to the group $ADGroupName." }
			}
		}
	}
}

<#
	.SYNOPSIS
		Gets the highest numbered VMName matching a specified regex pattern

	.DESCRIPTION
		Gathers all the devices in BMC & vSphere
		Filters them down by the regex
		If the latest VM names don't match between BCM & vSphere, a warning is generated and a factory alert is sent, then the highest VM name of the two is chosen

	.PARAMETER RegexPattern
		The regex to filter the machine names with

	.EXAMPLE
		PS C:\> Get-LatestVMName -RegexPattern $FactoryVMNameRegex

	.INPUTS
		Regex
#>
function Get-LatestVMName
{
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[regex]$RegexPattern
	)

	$DeviceNameAttribute = Get-BCMObjectTypeAttribute -ObjectType _DB_OBJECTTYPE_DEVICE_ -Name '_DB_ATTR_NAME_'

	$AllvSphereDevices = Get-VM | Sort-Object Name
	$AllBCMDevices = Get-BCMObjectInstance -Value '%' -ObjectType _DB_OBJECTTYPE_DEVICE_ -Attribute $DeviceNameAttribute -Source Topology

	$AllvSphereDeviceNames = $AllvSphereDevices | Select-Object -ExpandProperty Name | Select-Object -Unique
	$AllBCMDeviceNames = $AllBCMDevices | ForEach-Object {
		if ($_.Name.Contains('/')) { $_.Name.Split('/')[-1] }
		else { $_.Name }
	} | Sort-Object

	if ($RegexPattern)
	{
		$AllBCMDeviceNames = $AllBCMDeviceNames | Where-Object { $_ -match $RegexPattern }
		$AllvSphereDeviceNames = $AllvSphereDeviceNames | Where-Object { $_ -match $RegexPattern }

		if (($AllBCMDeviceNames -eq $null) -and ($AllvSphereDeviceNames -eq $null))
		{
			throw "No VMs exist that match the pattern $([string]$RegexPattern)"
		}
	}

	$LatestBCMVMName = $AllBCMDeviceNames | Select-Object -Last 1
	Write-Verbose "Latest BCM VM name is $LatestBCMVMName"

	$LatestvSphereVMName = $AllvSphereDeviceNames | Select-Object -Last 1
	Write-Verbose "Latest vSphere VM name is $LatestvSphereVMName"

	$LatestVMName = $LatestBCMVMName, $LatestvSphereVMName | Sort-Object | Select-Object -Last 1

	if ($LatestBCMVMName -ne $LatestvSphereVMName)
	{
		$WarningMessage = "Latest VM Name in BMC ($LatestBCMVMName) and vSphere ($LatestvSphereVMName) do not match. Going with highest VM name ($LatestVMName)."

		Write-Warning $WarningMessage
		Send-FactoryAlert -Subject 'Lastest VM Names Do Not Match' -Body $WarningMessage
	}
	else
	{
		Write-Verbose "Latest VM name is $LatestVMName"
	}
	Write-Output $LatestVMName
}

<#
	.SYNOPSIS
		Sends an email with the subject prepended with "Factory Alert"

	.DESCRIPTION
		A detailed description of the Send-FactoryAlert function.

	.PARAMETER Body
		The body of text for the email

	.PARAMETER Subject
		A description of the Subject parameter.

	.PARAMETER SubjectPrefix
		The prefix to prepend the subject with

	.PARAMETER Sender
		The email address to send

	.PARAMETER Recipient
		The email address for the recipient

	.PARAMETER LogPath
		The path to the relevant factory log, to be reference at the end of the email

	.EXAMPLE
		PS C:\> Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores'

	.EXAMPLE
		PS C:\> Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -SubjectPrefix 'AUTOMATED FACTORY ALERT'

	.EXAMPLE
		PS C:\> Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -Sender "John.Smith@$CompanyDomainName"

	.EXAMPLE
		PS C:\> Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -Recipient "Jane.Doe@$CompanyDomainName"

	.EXAMPLE
		PS C:\> Send-FactoryAlert -Body 'No datastores are attached to vdihost7002c' -Subject 'Missing Factory Host Datastores' -LogPath "$ITNetworkShare\AutomatedFactory\Logs\Trim VM Build Script\TrimVMBuild_amfap0p_2020-02-07__14-45-02.log"

	.INPUTS
		String
#>
function Send-FactoryAlert
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$Body,
		[Parameter(Mandatory = $true)]
		[string]$Subject,
		[string]$SubjectPrefix = 'FACTORY ALERT',
		[string]$Sender = "do_not_reply@$CompanyDomainName",
		[string[]]$Recipient = ($MainUsersEmail, $MainUsersManagersEmail),
		[string]$LogPath
	)

	if ($LogPath)
	{
		$Body = @"
$Body

See more details at "$LogPath"
"@
	}

	Send-MailMessage -To $Recipient -SmtpServer "internalrelay.$CompanyDomainName" -Body $Body -From $Sender -Subject ($SubjectPrefix + ': ' + $Subject) -WarningAction SilentlyContinue
}

<#
	.SYNOPSIS
		Returns the BCM Life Cycle Status of a machine

	.PARAMETER Device
		The device to use

	.EXAMPLE
		PS C:\> Get-LifeCycleStatus -Device 'VDPKG0011'

	.INPUTS
		BCMAPI.Device
#>
function Get-LifeCycleStatus
{
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[Device[]]$Device
	)

	Process
	{
		foreach ($Machine in $Device)
		{
			Write-Verbose "Life Cycle Status for $($Machine.FormattedName) is:"
			(Use-BCMRestAPI "/device/$($Machine.ID)/financial").LifeCycleStatus | Write-Output
		}
	}
}

<#
	.SYNOPSIS
		Updates the BCM life cycle status of a device

	.PARAMETER Device
		The device to use

	.PARAMETER LifeCycleStatus
		The new Life Cycle Status

	.EXAMPLE
		PS C:\> Update-LifeCycleStatus -Device 'VDPKG0011' -LifeCycleStatus 'Production'

	.INPUTS
		BCMAPI.Device
		String
#>
function Update-LifeCycleStatus
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[Device[]]$Device,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$LifeCycleStatus
	)

	begin
	{
		Write-Verbose 'Gathering list of allowable Life Cycle Statuses'
		$AllowableStatuses = (Use-BCMRestAPI '/financial/lifecyclestatus').LifeCycleStatus.Status | Sort-Object
		if ($AllowableStatuses.Count -eq 0) { throw "Failed to collect list of allowable statuses" }
	}
	process
	{
		foreach ($Machine in $Device)
		{
			if ($LifeCycleStatus -notin $AllowableStatuses) { throw "$LifeCycleStatus not in list of allowable statuses. Allowable Statuses are:`n`r$($AllowableStatuses -join ', ')" }
			else
			{
				Write-Verbose "Updating Life Cycle Status on $($Machine.FormattedName) to $LifeCycleStatus"
				$Result = Use-BCMRestAPI "/device/$($Machine.ID)/financial" -Method PUT -Body "{ `"LifeCycleStatus`": `"$LifeCycleStatus`" }"
				if ($Result.ErrorCode -eq 0) { Write-Verbose 'Successfully updated Life Cycle Status' }
			}
		}
	}
}

<#
	.SYNOPSIS
		Tests to see if the Factory Device Groups & Factory OpRules exist and are assigned to each other

	.PARAMETER FactoryBuildType
		The Factory Build type to test.
		Allowable values are 'Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'DataScience', 'JNAM', 'OPS', 'SIGDeveloper'

	.EXAMPLE
		PS C:\> Test-FactoryBuildType -FactoryBuildType 'Base'

	.INPUTS
		String
#>
function Test-FactoryBuildType
{
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		[Parameter(ValueFromPipeline = $true)]
		[ValidateSet('Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'DataScience', 'JNAM', 'OPS', 'SIGDeveloper')]
		[string]$FactoryBuildType
	)

	begin
	{
		$FactoryDefinitions = "$ITNetworkShare\AutomatedFactory\FactoryDefinitions.csv"
		if (-not (Test-Path $FactoryDefinitions)) { Throw "$FactoryDefinitions does not exist" }
	}

	process
	{
		Write-Verbose "Gathering Factory OpRule & Device Group objects"
		$FactoryBuild = Import-Csv $FactoryDefinitions |
		Where-Object $FactoryBuildType -NE '' |
		Select-Object *,
					  @{ l = 'OpRuleName'; e = { $_.OpRule } },
					  @{ l = 'OpRule'; e = { Get-BCMCommonObject -Name $_.OpRule -ObjectType 'Operational Rule' } },
					  @{ l = 'DeviceGroupName'; e = { $_.APPGRP } },
					  @{ l = 'DeviceGroup'; e = { Get-BCMCommonObject -Name $_.APPGRP -ObjectType 'Device Group' } } `
					  -ExcludeProperty OpRule, APPGRP |
		Sort-Object OpRuleName

		[switch]$OpRulesExist = $true
		[switch]$DeviceGroupsExist = $true
		[switch]$OpRuleDeviceGroupAssignmentsExist = $true

		$Missing = [pscustomobject]@{
			OpRule = @()
			DeviceGroup = @()
			Assignment = @()
		}

		$FactoryBuild | ForEach-Object {
			if ($_.OpRule -eq $null)
			{
				Write-Warning "$($_.OpRuleName) does not exist"
				$Missing.OpRule += $_.OpRuleName
			}
			else { Write-Verbose "$($_.OpRuleName) exists" }

			if ($_.DeviceGroup -eq $null)
			{
				Write-Warning "$($_.DeviceGroupName) does not exist"
				$Missing.DeviceGroup += $_.DeviceGroupName
			}

			if (($_.OpRule -ne $null) -and ($_.DeviceGroup -ne $null))
			{
				Write-Verbose "$($_.DeviceGroupName) exists"

				$AssignedDeviceGroupIDs = Get-DeviceGroupAssignedtoOpRule -OpRule $_.OpRule -DeviceGroupIDOnly

				if ($AssignedDeviceGroupIDs)
				{
					if ($_.DeviceGroup.ID -notin $AssignedDeviceGroupIDs)
					{
						Write-Warning "$($_.DeviceGroup.FormattedName) is not assigned to $($_.OpRule.FormattedName)"
						$Missing.Assignment += "$($_.DeviceGroupName) & $($_.OpRuleName)"
					}
					else { Write-Verbose "$($_.DeviceGroup.FormattedName) is assigned to $($_.OpRule.FormattedName)" }
					#I did not put a special warning in for when there are no Device Groups assigned to the OpRule as Get-DeviceGroupAssignedtoOpRule already does that
				}
				else { $Missing.Assignment += "$($_.DeviceGroupName) & $($_.OpRuleName)" }
			}
		}
	}
	end
	{
		if (($Missing.OpRule.Count -eq 0) -and ($Missing.DeviceGroup.Count -eq 0) -and ($Missing.Assignment.Count -eq 0))
		{
			Write-Verbose "All $FactoryBuildType build OpRules & Device Groups exist and the Device Groups are assigned to the correct OpRules"
			Return $true
		}
		else
		{
			$Body = ''
			if ($Missing.OpRule.Count -ne 0) { $Body = $Body + "These OpRules are missing from $BMCEnvironment BMC:`r`n" + ($Missing.OpRule -join "`r`n") }
			if ($Missing.DeviceGroup.Count -ne 0) { $Body = $Body + "`r`n`r`nThese Device Groups are missing from $BMCEnvironment BMC:`r`n" + ($Missing.DeviceGroup -join "`r`n") }
			if ($Missing.Assignment.Count -ne 0) { $Body = $Body + "`r`n`r`nThese Device Groups are not assigned to these OpRules in $BMCEnvironment BMC:`r`n" + ($Missing.Assignment -join "`r`n") }

			$Subject = "$FactoryBuildType build OpRules & Device Groups Failed Validation"

			Send-FactoryAlert -Body $Body -Subject $Subject
			throw $Subject
			Return $false
		}
	}
}

<#
	.SYNOPSIS
		Creates a CSV of a Device's Factory Run

	.DESCRIPTION
		Exports a CSV of the Factory Run containing the:
		OpRule order, OpRule name, Device Group name, OpRule assignment Status, Factory phase, OpRule attempt count, OpRule assignment duration, OpRule assignment start time, OpRule assignment end time

	.PARAMETER DeviceFactoryRun
		The device factory run to use

	.EXAMPLE
		PS C:\> New-FactoryRunReport -DeviceFactoryRun $DeviceFactoryRun

	.INPUTS
		DeviceFactoryRun
#>
function New-FactoryRunReport
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[DeviceFactoryRun[]]$DeviceFactoryRun
	)

	Process
	{
		foreach ($Run in $DeviceFactoryRuns)
		{
			$Run.FactoryBuildAssignment |
			Select-Object Order,
						  @{ l = 'OpRule'; e = { $_.OpRuleAssignment.OpRuleName } },
						  @{ l = 'DeviceGroup'; e = { $_.OpRuleAssignment.DeviceGroupName } },
						  @{ l = 'Status'; e = { $_.OpRuleAssignment.Status } },
						  Phase, Attempts, Duration, StartTime, EndTime |
			Export-Csv $Run.LogPath -Force
		}
	}
}

<#
	.SYNOPSIS
		Runs a group of devices through a factory build type

	.DESCRIPTION
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

	.PARAMETER DeviceCSVPath
		The path to the CSV containing the device name and factory build to apply

	.PARAMETER FactoryDefinitions
		The path to the Factory Definitions CSV

	.PARAMETER Reassign
		Reassign the device if it has the specified OpRule assignment status
		Allowable values are: 'All', 'ExecutionFailed', 'None', 'NonSuccessful'

	.PARAMETER RefreshInterval
		The amount of time between checks for OpRule status updates

	.PARAMETER MaxOpRuleRetries
		The amount of OpRule attempts to make for each OpRule on each device if it is not successfull

	.EXAMPLE
		PS C:\> Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-06__14-11-02_xbz1219.csv"

	.EXAMPLE
		PS C:\> Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-10__11-23-27_amfap0p.csv" -FactoryDefinitions "$ITNetworkShare\AutomatedFactory\Factory Definitions Archive\FactoryDefinitions_R33.csv"

	.EXAMPLE
		PS C:\> Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-03__08-39-41_xbz1219.csv" -Reassign 'All'

	.EXAMPLE
		PS C:\> Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-01-31__09-46-08_xbz1219.csv" -RefreshInterval 60

	.EXAMPLE
		PS C:\> Build-FactoryDevice -DeviceCSVPath "$ITNetworkShare\AutomatedFactory\Logs\BMC Factory Run CSVs\FactoryBuild_2020-02-04__19-04-51_amfap0p.csv" -MaxOpRuleRetries 2

	.NOTES
		This creates a log in "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script" with a title that includes the function start time, initiator's username, and BMC environment being used

	.INPUTS
		String
		Int
#>
function Build-FactoryDevice
{
	[CmdletBinding()]
	[OutputType([pscustomobject])]
	param
	(
		[ValidateScript({ (Test-Path $_) -and ((Split-Path $_ -Extension) -eq '.csv') })]
		[string]$DeviceCSVPath,
		[ValidateScript({ (Test-Path $_) -and ((Split-Path $_ -Extension) -eq '.csv') })]
		[string]$FactoryDefinitions = "$ITNetworkShare\AutomatedFactory\FactoryDefinitions.csv",
		[ValidateSet('All', 'ExecutionFailed', 'None', 'NonSuccessful')]
		[string]$Reassign = 'None',
		[int]$RefreshInterval = 30,
		[int]$MaxOpRuleRetries = 3,
		[switch]$NovSphere
	)

	$logDir = "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script"
	if (-Not (Test-Path $logDir)) { New-Item $logDir -Force | Out-Null }
	$logName = "FactoryRun_$(Get-Date -Format 'yyyy-MM-dd__HH-mm-ss')_$env:USERNAME`_$BMCEnvironment`.log"
	$logFile = Join-Path $logDir $logName
	New-Item -Path $LogFile -ItemType File -Force | Out-Null

	Write-Log -Message "Importing $DeviceCSVPath" -LogFile $LogFile -Stream Verbose
	$DeviceCSV = Import-CSV $DeviceCSVPath
	$BuildTypesNeeded = $DeviceCSV | Select-Object -ExpandProperty BuildType -Unique

	$CMDBUpdateFolder = "\\$CMDBUpdateServerName\CMDBstatus"

	$ReassignableStatuses = switch ($Reassign)
	{
		All {
			'Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Executed', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule'
		}
		ExecutionFailed {
			'Execution Failed', 'Assignment Paused'
		}
		None {
			'Assignment Paused'
		}
		NonSuccessful {
			'Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule'
		}
	}

	$FinalStatuses = 'Dependency Check Failed', 'Executed', 'Execution Failed', 'Not Received', 'Publication Planned', 'Package Missing', 'Sending impossible', 'Step Missing', 'Unassignment Paused', 'Update Paused', 'Verification Failed'

	Write-Log -Message "Validating relevant factory OpRules and Device Groups" -LogFile $LogFile -Stream Verbose
	$Validated = $BuildTypesNeeded | ForEach-Object { Test-FactoryBuildType $_ } | Select-Object -Unique
	if (($Validated.count -ne 1) -or ($Validated -eq $false)) { throw "Failed to pass Factory Build OpRule & Device Group validation" }

	Write-Log -Message "Gathering relevant factory OpRule and Device Group properties" -LogFile $LogFile -Stream Verbose
	$FactoryBuild = Import-Csv $FactoryDefinitions |
	Select-Object *,
				  @{ l = 'OpRuleName'; e = { $_.OpRule } },
				  @{ l = 'OpRule'; e = { Get-BCMCommonObject -Name $_.OpRule -ObjectType 'Operational Rule' } },
				  @{ l = 'DeviceGroupName'; e = { $_.APPGRP } },
				  @{ l = 'DeviceGroup'; e = { Get-BCMCommonObject -Name $_.APPGRP -ObjectType 'Device Group' } } `
				  -ExcludeProperty OpRule, APPGRP |
	Sort-Object OpRuleName

	#region Add Devices to Device Groups and collect OpRule assignments

	Write-Log -Message "Gathering device properties" -LogFile $LogFile -Stream Verbose
	$DeviceFactoryRuns = $DeviceCSV | ForEach-Object { [DeviceFactoryRun]::New((Get-BCMCommonObject -Name $_.Device -ObjectType Device), $_.BuildType, 1, $MaxOpRuleRetries) }


	if (-Not($NovSphere.IsPresent))
	{
	foreach ($Run in $DeviceFactoryRuns)
	{
		Write-Log "Setting the `"FactoryStatus`" custom attribute on $($Run.Device.Name) to `"$($Run.BuildType)_Staging`"" -Stream Verbose -LogFile $LogFile
		Set-Annotation -Entity (Get-VM $Run.Device.Name) -CustomAttribute FactoryStatus -Value "$($Run.BuildType)_Staging"
	}
	}

	foreach ($BuildType in $BuildTypesNeeded)
	{
		Write-Log -Message "Filtering to $BuildType factory OpRule and Device Groups" -LogFile $LogFile -Stream Verbose
		$RelevantRuns = $DeviceFactoryRuns | Where-Object BuildType -EQ $BuildType
		$RelevantSteps = $FactoryBuild | Where-Object { $_.$BuildType -ne '' }
		$StepNumber = 0
		foreach ($Step in ($RelevantSteps | Sort-Object $BuildType))
		{
			$StepNumber++

			Write-Log -Message "Adding devices to the device group $($Step.DeviceGroup.FormattedName) for step $StepNumber of the $BuildType factory build" -LogFile $LogFile -Stream Verbose

			Add-DevicetoDeviceGroup -Device $RelevantRuns.Device -DeviceGroup $Step.DeviceGroup -WarningAction SilentlyContinue
			$NewAssignments = Get-OpRuleAssignment -OpRule $Step.OpRule -Device $RelevantRuns.Device -DeviceGroup $Step.DeviceGroup -WarningAction SilentlyContinue

			if ($NewAssignments.Count -ne $RelevantRuns.Device.Count)
			{
				$MissingDevicesCheckCounter = 0
				$MissingDevices = $RelevantRuns.Device | Where-Object ID -NotIn $NewAssignments.DeviceID

				while ($MissingDevices -ne $null)
				{
					$MissingDevicesCheckCounter++

					#This is because it almost always finds them on the second try
					if ($MissingDevicesCheckCounter -ne 1) { Write-Log -Message "$($MissingDevices.FormattedName -join ', ') are missing assignments to $($Step.OpRule.FormattedName), looking for updated assignments" -LogFile $LogFile -Stream Warning }
					$NewAssignments = Get-OpRuleAssignment -OpRule $Step.OpRule -Device $RelevantRuns.Device -DeviceGroup $Step.DeviceGroup
					$MissingDevices = $RelevantRuns.Device | Where-Object ID -NotIn $NewAssignments.DeviceID

					if ($MissingDevicesCheckCounter -gt 4) { Write-Log -Message "$($MissingDevices.FormattedName -join ', ') are still missing assignments to $($Step.OpRule.FormattedName) after $MissingDevicesCheckCounter checks" -LogFile $LogFile -Stream Error -ErrorAs Throw }

					Start-Sleep 5
				}
			}

			foreach ($Run in $RelevantRuns)
			{
				$RelevantAssignment = $NewAssignments | Where-Object DeviceID -EQ $Run.Device.ID
				$Run.FactoryBuildAssignment += [FactoryBuildAssignment]::New($StepNumber, $RelevantAssignment, $Step.$BuildType, $Step.MaxRuntimeInMinutes)
			}
		}
	}
	#endregion Add Devices to Device Groups and collect OpRule assignments


	if (-Not ($NovSphere.IsPresent))
	{
		foreach ($Run in $DeviceFactoryRuns)
		{
			Write-Log "Setting the `"FactoryStatus`" custom attribute on $($Run.Device.Name) to `"$($Run.BuildType)_InProgress`"" -Stream Verbose -LogFile $LogFile
			Set-Annotation -Entity (Get-VM $Run.Device.Name) -CustomAttribute FactoryStatus -Value "$($Run.BuildType)_InProgress"
		}
	}

	New-FactoryRunReport $DeviceFactoryRuns

	Write-Log -Message "Starting Factory Builds" -LogFile $LogFile -Stream Verbose
	$DeviceFactoryRuns | Where-Object Stopped -EQ $false | ForEach-Object {
		if ($_.CurrentAssignment.OpRuleAssignment.Status -in $ReassignableStatuses)
		{
			$_.CurrentAssignment.OpRuleAssignment.UpdateStatus('Reassignment Waiting') | Out-Null
			$_.CurrentAssignment.StartTime = (Get-Date).ToUniversalTime()
			$_.CurrentAssignment.Attempts++
		}
	}

	while ($false -in $DeviceFactoryRuns.Stopped)
	{
		$CurrentStatus = $DeviceFactoryRuns | ForEach-Object {
			$StartTime = if ($_.CurrentAssignment.StartTime -eq (Get-Date 0)) { '' }
			else { $_.CurrentAssignment.StartTime }
			$EndTime = if ($_.CurrentAssignment.EndTime -eq (Get-Date 0)) { '' }
			else { $_.CurrentAssignment.EndTime }
			[pscustomobject]@{
				Position = "$($_.CurrentPosition) of $($_.FactoryBuildAssignment | Select-Object -ExpandProperty Order -Last 1)"
				Device   = $_.CurrentAssignment.OpRuleAssignment.Device.FormattedName
				OpRule   = $_.CurrentAssignment.OpRuleAssignment.OpRule.FormattedName
				Status   = $_.CurrentAssignment.OpRuleAssignment.Status
				Duration = "$([math]::Round($_.CurrentAssignment.Duration.TotalMinutes, 2)) minutes"
				StartTime = $StartTime
				EndTime  = $EndTime
				OpRuleAttempts = "$($_.CurrentAssignment.Attempts) of $($_.MaxOpRuleRetries)"
				Phase    = "$($_.CurrentPhase) of $($_.FactoryBuildAssignment | Select-Object -ExpandProperty Phase -Last 1)"
				BuildType = $_.BuildType
				NextAssignmentInNewPhase = $_.NextAssignmentInNewPhase
				NonExecutedInCurrentPhase = $_.NonExecutedInCurrentPhase
				Stopped  = $_.Stopped
			}
		}
		$StatusCSVPath = "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Status CSVs\$($logName.Replace('log', 'csv'))"
		$CurrentStatus | Export-Csv -Path $StatusCSVPath -Force

		New-FactoryRunReport $DeviceFactoryRuns

		Write-Information "Ongoing Builds are:`n`r$($CurrentStatus | Where-Object Stopped -EQ $false | Format-Table -AutoSize | Out-String)"
		#Write-Log -Message "Ongoing Builds are:`n`r$($CurrentStatus | Where-Object Stopped -EQ $false | Format-Table -AutoSize | Out-String)" -LogFile $LogFile -Stream Information

		foreach ($Run in ($DeviceFactoryRuns | Where-Object Stopped -EQ $false))
		{
			Write-Log -Message "Updating status of current assignment ($($Run.CurrentAssignment.OpRuleAssignment.OpRule.FormattedName)) on $($Run.Device.FormattedName)" -LogFile $LogFile -Stream Verbose
			$Run.CurrentAssignment.OpRuleAssignment.RefreshStatus() | Out-Null

			do
			{
				$RepeatStatusEval = $false
				if (($Run.CurrentAssignment.OpRuleAssignment.Status -in $FinalStatuses) -or ($Run.CurrentAssignment.Duration.TotalMinutes -gt $Run.CurrentAssignment.MaxRuntimeInMinutes))
				{
					$Run.CurrentAssignment.EndTime = (Get-Date).ToUniversalTime()

					if ($Run.CurrentAssignment.OpRuleAssignment.Status -in $FinalStatuses) { Write-Log -Message "$($Run.CurrentAssignment.OpRuleAssignment.OpRule.FormattedName) has a final status. Its status is $($Run.CurrentAssignment.OpRuleAssignment.Status)" -LogFile $LogFile -Stream Verbose }
					else { Write-Log -Message "$($Run.Device.FormattedName) has exceeded its max runtime for $($Run.CurrentAssignment.OpRuleAssignment.OpRule.FormattedName) ($($Run.CurrentAssignment.MaxRuntimeInMinutes) minutes) with a duration of $($Run.CurrentAssignment.Duration.TotalMinutes) minutes" -LogFile $LogFile -Stream Warning }

					if (($Run.CurrentAssignment.Attempts -eq $Run.MaxOpRuleRetries) -or ($Run.CurrentAssignment.OpRuleAssignment.Status -in 'Executed', 'Update Sent'))
					{
						Write-Log -Message "$($Run.Device.FormattedName) $($Run.CurrentAssignment.OpRuleAssignment.OpRule.FormattedName) attempts are $($Run.CurrentAssignment.Attempts) out of $($Run.MaxOpRuleRetries)" -LogFile $LogFile -Stream Verbose
						if ($Run.NextAssignment -eq $null)
						{
							Write-Log -Message "$($Run.Device.FormattedName) has been through all the $($Run.BuildType) build assignments, setting 'Stopped' to true" -LogFile $LogFile
							$Run.Stopped = $true

							if ($Run.NonExecutedInCurrentPhase)
							{
								Write-Log "$($Run.Device.FormattedName) has failures in the final phase" -LogFile $LogFile -Stream Error
								if ($NovSphere.IsPresent)
								{
									Write-Log "Setting the LifeCycle Status on $($Run.Device.Name) to Build_Failed" -Stream Verbose -LogFile $LogFile
									Update-LifeCycleStatus -Device $Run.Device -LifeCycleStatus 'Build_Failed'
								}
								else
								{
									Write-Log "Setting the `"FactoryStatus`" custom attribute on $($Run.Device.Name) to `"$($Run.BuildType)_Failed`"" -Stream Verbose -LogFile $LogFile
									Set-Annotation -Entity (Get-VM $Run.Device.Name) -CustomAttribute FactoryStatus -Value "$($Run.BuildType)_Failed"
								}
							}
							else
							{
								Write-Log "$($Run.Device.FormattedName) has successfully completed the $($Run.BuildType) build" -LogFile $LogFile
								if ($NovSphere.IsPresent)
								{
									Write-Log "Setting the LifeCycle Status on $($Run.Device.Name) to Hot Pool" -Stream Verbose -LogFile $LogFile
									Update-LifeCycleStatus -Device $Run.Device -LifeCycleStatus 'Hot Pool'

									Write-Log "Creating CBMD update csv in $CMDBUpdateFolder, to update the CMDB status of the new devices to 1" -Stream Verbose -LogFile $LogFile
									try { Update-CMDBStatus $Run.Device.Name }
									catch
									{
										Send-FactoryAlert -Subject 'CMDB Update CSV Creation Failed' -Body "Failed to create CMDB update CSV in $CMDBUpdateFolder for $($Run.Device.Name), to set it to a CMDB status of 1"
										Write-Log "Failed to create CMDB Update in $CMDBUpdateFolder for $($Run.Device.Name)" -Stream Error -LogFile $logFile
									}
								}
								else
								{
									Write-Log "Setting the `"FactoryStatus`" custom attribute on $($Run.Device.Name) to `"$($Run.BuildType)_Success`"" -Stream Verbose -LogFile $LogFile
									Set-Annotation -Entity (Get-VM $Run.Device.Name) -CustomAttribute FactoryStatus -Value "$($Run.BuildType)_Success"
									if ($BMCEnvironment -eq 'PROD')
									{
										Update-LifeCycleStatus -Device $Run.Device -LifeCycleStatus 'Build_Patch'
									}
								}
							}
						}
						elseif (($Run.NextAssignmentinNewPhase) -and ($Run.NonExecutedInCurrentPhase))
						{
							Write-Log -Message "$($Run.Device.FormattedName) has finished phase $($Run.CurrentPhase) of the $($Run.BuildType) build, but there are failures in the phase. Setting 'Stopped' to true" -LogFile $LogFile -Stream Warning
							$Run.Stopped = $true

							if ($NovSphere.IsPresent)
							{
								Write-Log "Setting the LifeCycle Status on $($Run.Device.Name) to Build_Failed" -Stream Verbose -LogFile $LogFile
								Update-LifeCycleStatus -Device $Run.Device -LifeCycleStatus 'Build_Failed'
							}
							else
							{
							Write-Log "Setting the `"FactoryStatus`" custom attribute on $($Run.Device.Name) to `"$($Run.BuildType)_Failed`"" -Stream Verbose -LogFile $LogFile
							Set-Annotation -Entity (Get-VM $Run.Device.Name) -CustomAttribute FactoryStatus -Value "$($Run.BuildType)_Failed"
						}
						}
						else
						{
							if ($Run.CurrentAssignment.OpRuleAssignment.Status -eq 'Update Sent')
							{
								Write-Log -Message "$($Run.Device.FormattedName)'s current assignment has timed out while stuck in Update Sent. The next assignment exists and the current phase either does not contain any 'Non-Executed' assignments or the next assignment is in the same phase. Going to the next assignment." -LogFile $LogFile -Stream Verbose
							}
							else { Write-Log -Message "$($Run.Device.FormattedName) has finished its current assignment. The next assignment exists and the current phase either does not contain any 'Non-Executed' assignments or the next assignment is in the same phase. Going to the next assignment." -LogFile $LogFile -Stream Verbose }
							$Run.GoToNextAssignment()
							if ($Run.CurrentAssignment.OpRuleAssignment.Status -in $ReassignableStatuses)
							{
								$Run.CurrentAssignment.OpRuleAssignment.UpdateStatus('Reassignment Waiting') | Out-Null
								$Run.CurrentAssignment.StartTime = (Get-Date).ToUniversalTime()
								$Run.CurrentAssignment.Attempts++
							}
							$RepeatStatusEval = $true
						}
					}
					else
					{
						Write-Log -Message "$($Run.Device.FormattedName) has not executed $($Run.CurrentAssignment.OpRuleAssignment.OpRule.FormattedName) successfully and its max attempts limit of $($Run.MaxOpRuleRetries) has not yet been reached." -LogFile $LogFile -Stream Verbose
						$Run.CurrentAssignment.OpRuleAssignment.UpdateStatus('Reassignment Waiting') | Out-Null
						$Run.CurrentAssignment.StartTime = (Get-Date).ToUniversalTime()
						$Run.CurrentAssignment.EndTime = Get-Date 0
						$Run.CurrentAssignment.Attempts++
					}
				}
				else
				{
					Continue
				}
			}
			while ($RepeatStatusEval -eq $true)
		}

		if ((($DeviceFactoryRuns.Stopped | Select-Object -Unique).count -eq 1) -and (($DeviceFactoryRuns.Stopped | Select-Object -Unique) -eq $true))
		{
			New-FactoryRunReport $DeviceFactoryRuns
			$CurrentStatus | Export-Csv -Path $StatusCSVPath -Force
			Write-Log "All Factory Builds have completed" -LogFile $LogFile
		}
		else { Start-Sleep $RefreshInterval }
	}
}

<#
	.SYNOPSIS
		Gathers the latest factory run csv log for a given build type for a given machine

	.DESCRIPTION
		This function:
			Gathers the csv files directly (no recursion) in the path specified in the FactoryRunLogFolder parameter
			For each device:
				The logs containing the device name and specified BuildType are gathered
				The most recent csv is chosen if there are multiple csvs for that device
				The csv is then imported as objects and the steps are filtered down to the ones with the OpRule status grouping specified in the StatusFilter parameter

	.PARAMETER Name
		The name of the device to gather the log for

	.PARAMETER BuildType
		The build type to filter on for the device/s.
		Options are Base, Base_Laptop, Base_DesktopandThinClient, Base_Packaging, Base_PhysicalServer, Base_VirtualServer, Cocoon, CycleHarvester, DataScience, JNAM, OPS, SIGDeveloper

	.PARAMETER StatusFilter
		The OpRule status grouping to filter the factory steps down to

	.PARAMETER FactoryRunLogFolder
		A description of the FactoryRunLogFolder parameter.
		Options are:
			All: Assigned, Assignment Paused, Assignment Planned, Assignment Sent, Assignment Waiting, Available, Deleted, Dependency Check Failed, Dependency Check Requested, Dependency Check Successful, Disabled, Executed, Execution Failed, Not Received, Obsolete, Package Missing, Package Requested, Package Sent, Publication Planned, Publication Sent, Publication Waiting, Published, Ready to run, Reassignment Waiting, Reboot Pending, Sending impossible, Step Missing, Step Requested, Step Sent, Unassigned, Unassignment Paused, Unassignment Sent, Unassignment Waiting, Uninstalled, Update Paused, Update Planned, Update Sent, Update Waiting, Updated, Verification Failed, Verification Requested, Verified, Waiting for Operational Rule

			Failed: Dependency Check Failed, Execution Failed, Package Missing, Verification Failed

			Final: Dependency Check Failed, Executed, Execution Failed, Not Received, Publication Planned, Package Missing, Sending impossible, Step Missing, Unassignment Paused, Update Paused, Verification Failed

			NonSuccessful: Assigned, Assignment Paused, Assignment Planned, Assignment Sent, Assignment Waiting, Available, Deleted, Dependency Check Failed, Dependency Check Requested, Dependency Check Successful, Disabled, Execution Failed, Not Received, Obsolete, Package Missing, Package Requested, Package Sent, Publication Planned, Publication Sent, Publication Waiting, Published, Ready to run, Reassignment Waiting, Reboot Pending, Sending impossible, Step Missing, Step Requested, Step Sent, Unassigned, Unassignment Paused, Unassignment Sent, Unassignment Waiting, Uninstalled, Update Paused, Update Planned, Update Sent, Update Waiting, Updated, Verification Failed, Verification Requested, Verified, Waiting for Operational Rule

			Successful: Executed

	.EXAMPLE
		Get-DeviceFactoryRunSummary -Name VD0021868

	.EXAMPLE
		Get-DeviceFactoryRunSummary -Name VD0022169 -BuildType OPS

	.EXAMPLE
		Get-DeviceFactoryRunSummary -Name VD0022169 -BuildType OPS -StatusFilter Failed

	.EXAMPLE
		Get-DeviceFactoryRunSummary -Name VD0022169 -BuildType OPS -StatusFilter Failed -FactoryRunLogFolder "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Device Factory Run Summary CSVs"

	.NOTES
		01.20.2021 - Alex Larner - Created function
#>
function Get-DeviceFactoryRunSummary
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[String[]]$Name,
		[Parameter(Position = 1)]
		[ValidateSet('Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'DataScience', 'JNAM', 'OPS', 'SIGDeveloper')]
		[string]$BuildType = 'Base',
		[ValidateSet('All', 'Failed', 'Final', 'NonSuccessful', 'Successful')]
		[string]$StatusFilter = 'NonSuccessful',
		[ValidateScript({ Test-Path $_ })]
		[string]$FactoryRunLogFolder = "$ITNetworkShare\AutomatedFactory\Logs\Factory Run Script\Device Factory Run Summary CSVs"
	)

	begin
	{
		$FactoryRunLogs = Get-ChildItem $FactoryRunLogFolder -Filter '*.csv'

		$RelevantStatuses = switch ($StatusFilter)
		{
			All {
				'Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Executed', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule'
			}
			Failed {
				'Dependency Check Failed', 'Execution Failed', 'Package Missing', 'Verification Failed'
			}
			Final
			{
				'Dependency Check Failed', 'Executed', 'Execution Failed', 'Not Received', 'Publication Planned', 'Package Missing', 'Sending impossible', 'Step Missing', 'Unassignment Paused', 'Update Paused', 'Verification Failed'
			}
			NonSuccessful {
				'Assigned', 'Assignment Paused', 'Assignment Planned', 'Assignment Sent', 'Assignment Waiting', 'Available', 'Deleted', 'Dependency Check Failed', 'Dependency Check Requested', 'Dependency Check Successful', 'Disabled', 'Execution Failed', 'Not Received', 'Obsolete', 'Package Missing', 'Package Requested', 'Package Sent', 'Publication Planned', 'Publication Sent', 'Publication Waiting', 'Published', 'Ready to run', 'Reassignment Waiting', 'Reboot Pending', 'Sending impossible', 'Step Missing', 'Step Requested', 'Step Sent', 'Unassigned', 'Unassignment Paused', 'Unassignment Sent', 'Unassignment Waiting', 'Uninstalled', 'Update Paused', 'Update Planned', 'Update Sent', 'Update Waiting', 'Updated', 'Verification Failed', 'Verification Requested', 'Verified', 'Waiting for Operational Rule'
			}
			Successful
			{
				'Executed'
			}
		}
	}
	process
	{
		foreach ($DeviceName in $Name)
		{
			$FailedLog = $FactoryRunLogs | Where-Object Name -like "$DeviceName`_$BuildType*"

			if ($FailedLog.Count -eq 0)
			{
				Write-Warning "Failed to find CSV for $DeviceName's $BuildType Factory Run"
			}
			else
			{
				if ($FailedLog.Count -gt 1)
				{
					Write-Warning "Found multiple CSVs for $DeviceName's $BuildType Factory Run. Going with the most recent one"
					$FailedLog = $FailedLog | Sort-Object LastWriteTime | Select-Object -Last 1
				}
				Write-Debug "Found log $($FailedLog.Name) for $DeviceName"
				Write-Output ($FailedLog | Import-Csv | Where-Object Status -In $RelevantStatuses | Select-Object @{ l = 'Device'; e = { $DeviceName } }, *)
			}
		}
	}
}

<#
	.SYNOPSIS
		Remove devices from all the device groups of a specified factory build

	.PARAMETER Device
		The BCM device to use

	.PARAMETER BuildType
		The build type to remove the device from its device groups
		Allowable values are 'All', 'Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'JNAM', 'OPS', 'SIGDeveloper'

	.PARAMETER FactoryDefinitions
		The path to the factory definitions spreadsheet. The path must exist and have an extension of .csv.

	.EXAMPLE
		PS C:\> Remove-DevicefromFactoryDeviceGroups -Device VDPKG0001

	.EXAMPLE
		PS C:\> Remove-DevicefromFactoryDeviceGroups -Device VDPKG0001 -BuildType Base

	.EXAMPLE
		PS C:\> Remove-DevicefromFactoryDeviceGroups -Device VDPKG0001 -FactoryDefinitions "$ITNetworkShare\AutomatedFactory\Factory Definitions Archive\FactoryDefinitions_R34.csv"

	.NOTES
		This would generally only be used on IT Systems Engineer test machines

	.INPUTS
		BCMAPI.Device
		String
#>
function Remove-DevicefromFactoryDeviceGroups
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[Device[]]$Device,
		[Parameter(Position = 1)]
		[ValidateSet('All', 'Base', 'Base_Laptop', 'Base_DesktopandThinClient', 'Base_Packaging', 'Base_PhysicalServer', 'Base_VirtualServer', 'Cocoon', 'CycleHarvester', 'DataScience', 'JNAM', 'OPS', 'SIGDeveloper')]
		[string]$BuildType = 'All',
		[ValidateScript({ (Test-Path $_) -and ((Split-Path $_ -Extension) -eq '.csv') })]
		[string]$FactoryDefinitions = "$ITNetworkShare\AutomatedFactory\FactoryDefinitions.csv"
	)

	$FactoryBuild = Import-Csv $FactoryDefinitions
	if ($BuildType -ne 'All') { $FactoryBuild = $FactoryBuild | Where-Object $BuildType -ne '' }

	Get-BCMCommonObject -Name $FactoryBuild.APPGRP -ObjectType 'Device Group' | ForEach-Object { $_.RemoveDevice($Device) }
}

<#
	.SYNOPSIS
		Creates a CMDB update csv in the specified folder

	.PARAMETER DeviceNames
		The names of the new devices to use

	.PARAMETER CMDBstatus
		The CMDB status number to update the devices with

	.PARAMETER CMDBUpdateFolder
		The folder to place the update CSV in

	.EXAMPLE
		PS C:\> Update-CMDBStatus -DeviceNames 'VDPKG0001'

	.EXAMPLE
		PS C:\> Update-CMDBStatus -DeviceNames 'VDPKG0001' -CMDBStatus 3

	.EXAMPLE
		PS C:\> Update-CMDBStatus -DeviceNames 'VDPKG0001' -CMDBUpdateFolder "\\$CompanyDomainName\apps\Prod\JTS\Factory"

	.NOTES
		2020.12.15 - Updated function to handle the type entries for physical devices
#>
function Update-CMDBStatus
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string[]]$DeviceNames,
		[int]$CMDBstatus = 5,
		[string]$CMDBUpdateFolder = "\\$CMDBUpdateServerName\CMDBstatus"
	)

	if (-Not (Test-Path $CMDBUpdateFolder))
	{
		Write-Error "$CMDBUpdateFolder does not exit"
	}

	Write-Verbose "Creating CMBD Update csv in $CMDBUpdateFolder"
	$NewFileName = "$CMDBUpdateFolder\FB_$(get-date -Format yyyyMMdd_HH_mm).csv"
	$CSV = @()

	$DeviceNames | ForEach-Object {
		$CSV += [pscustomobject]@{
			Device = $_
			type   = switch -wildcard ($_)
			{
				$DesktopDeviceNameWildcardPrefix { 'CPD' }
				$LaptopDeviceNameWildcardPrefix { 'CPL' }
				$ThinClientDeviceNameWildcardPrefix { 'CPS' }
				'VD*' { 'CVV' }
				$OldLaptopDeviceNameWildcardPrefix { 'CPL' }
				default { Send-FactoryAlert -Subject 'Unknown device name prefix' -Body "$_ has an unknown device name prefix. Cannot determine appropriate CMDB type." }
			}
			CMDBstatus = $CMDBstatus
		}
	}
	$CSV | Export-Csv $NewFileName -NoTypeInformation -Force -ErrorAction Stop

	Write-Verbose "Created $NewFileName"
}

<#
	.SYNOPSIS
		Returns the error text related to an error code

	.PARAMETER ErrorID
		The ID to look up

	.EXAMPLE
		PS C:\> Get-BMCErrorCodeText -ErrorID 47

	.INPUTS
		Int
#>
function Get-BMCErrorCodeText
{
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[int]$ErrorID
	)

	$Translation = Use-BCMRestAPI "/i18n/error/$ErrorID"
	if ($Translation.Fault -ne $null) { throw "Failed to find error code text for error ID $ErrorID, with an error ID of $($Translation.Fault.Code)" }
	Return $Translation.Text
}

<#
	.SYNOPSIS
		Returns a step type object from the StepTypes variable

	.PARAMETER ID
		The ID of the step type
		This is particular to the revision of the step and therefore can be different between BCM revisions

	.PARAMETER Name
		The backend BMC database name, from the name property of the step type object

	.PARAMETER FrontEndName
		The front end name of the step type, generally the same name as in the GUI

	.EXAMPLE
		PS C:\> Get-StepType -ID 1613

	.EXAMPLE
		PS C:\> Get-StepType -Name '_DB_STEPNAME_WAIT_'

	.EXAMPLE
		PS C:\> Get-StepType -FrontEndName 'Execute Program'

	.EXAMPLE
		PS C:\> Get-StepType -FrontEndName 'Registry*'

	.INPUTS
		String
		Int
#>
function Get-StepType
{
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	[OutputType([StepType])]
	param
	(
		[Parameter(ParameterSetName = 'ByID',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[int[]]$ID,
		[Parameter(ParameterSetName = 'ByName',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$Name,
		[Parameter(ParameterSetName = 'ByFrontEndName',
				   Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$FrontEndName
	)

	begin
	{
		$Index = $StepTypes
		$SearchTerm = switch ($PsCmdlet.ParameterSetName)
		{
			'ByName' { $Name }
			'ByFrontEndName' { $FrontEndName }
			'ByID' { $ID }
		}
	}
	process
	{
		foreach ($Term in $SearchTerm)
		{
			if ([WildcardPattern]::ContainsWildcardCharacters($Term)) { $Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -Like $Term }
			else
			{
				$Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -eq $Term

				if ($Result.Count -gt 1)
				{
					if ($PsCmdlet.ParameterSetName -eq 'ByID') { throw "More than one step type was found with the ID $Term" }
					else { Write-Warning "More than one step type was found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term" }
				}
			}

			if (-not ($Result)) { Write-Verbose "No step types were found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term" }
			else { Write-Output $Result }
		}
	}
}

<#
	.SYNOPSIS
		Gathers the parameters for a given step type

	.DESCRIPTION
		Gathers the parameters and casts them into a Step Parameter object

	.PARAMETER StepType
		The step type object to use
		If this is the only parameter used, all the parameters for the object type will be returned.

	.PARAMETER ID
		The ID of the step type parameter
		This is unique to the step type and the parameter (i.e. the ID for the Executable Path parameter of an Execute Program step will be different from the Name property of a Executable Path parameter of an Execute Program as User step)
		This can also be different between BCM revisions

	.PARAMETER Label
		The value of the label property on the step parameter
		Use this only if you want to filter the parameters down to ones with a particular label

	.PARAMETER FrontEndLabel
		The front end label of the parameter, generally the same name as in the GUI
		Use this only if you want to filter the parameters down to ones with a particular front end label

	.EXAMPLE
		PS C:\> Get-StepTypeParameter -StepType $StepType

	.EXAMPLE
		PS C:\> Get-StepTypeParameter -StepType _DB_STEPNAME_DELETEDIRECTORY_ -ID 5025

	.EXAMPLE
		PS C:\> Get-StepTypeParameter -StepType '_DB_STEPNAME_REGISTRYMANAGEMENT_' -Label '_DB_STEPPARAM_REGISTRYKEY_'

	.EXAMPLE
		PS C:\> Get-StepTypeParameter -StepType '_DB_STEPNAME_RUNPROGRAM_' -FrontEndLabel 'Executable Path'

	.EXAMPLE
		PS C:\> Get-StepTypeParameter -StepType '_DB_STEPNAME_COPYFILE_' -FrontEndLabel '*Path*'

	.INPUTS
		BCMAPI.StepType
		Int
		String

	.NOTES
		The Label property is used because the Name property does not use the usual BCM backend name, and does not translate properly to the front end name using BCMs own internal translation.
		Why BMC decided to make the name property values on these objects different from the majority of their object types, remains to be seen.
#>
function Get-StepTypeParameter
{
	[CmdletBinding(DefaultParameterSetName = 'All')]
	[OutputType([StepTypeParameter])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[StepType[]]$StepType,
		[Parameter(ParameterSetName = 'ByID',
				   Mandatory = $true,
				   Position = 1)]
		[ValidateNotNullOrEmpty()]
		[int[]]$ID,
		[Parameter(ParameterSetName = 'ByLabel',
				   Mandatory = $true,
				   Position = 1)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$Label,
		[Parameter(ParameterSetName = 'ByFrontEndLabel',
				   Mandatory = $true,
				   Position = 1)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$FrontEndLabel
	)

	process
	{
		foreach ($Type in $StepType)
		{
			Write-Verbose "Gathering parameters for $($Type.FrontEndFormattedName)"
			$Index = (Use-BCMRestAPI "/oprule/step/$($Type.ID)").Step.Params

			switch ($PsCmdlet.ParameterSetName)
			{
				'All'{
					$SearchTerm = $null
					$Index | ForEach-Object { Write-Output ([StepTypeParameter]::New($_)) }
				}
				'ByLabel' {
					$SearchTerm = $Label
				}
				'ByFrontEndLabel' {
					$SearchTerm = $FrontEndLabel
					$Index = $Index | ForEach-Object { [StepTypeParameter]::New($_) }
				}
				'ByID' {
					$SearchTerm = $ID
				}
			}

			foreach ($Term in $SearchTerm)
			{
				if ([WildcardPattern]::ContainsWildcardCharacters($Term)) { $Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -Like $Term }
				else
				{
					$Result = $Index | Where-Object $PsCmdlet.ParameterSetName.Substring(2) -eq $Term

					if ($Result.Count -gt 1)
					{
						if ($PsCmdlet.ParameterSetName -eq 'ByID') { throw "More than one parameter was found with the ID $Term under the step type $($Type.FrontEndFormattedName)" }
						else { Write-Warning "More than one parameter was found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term under the step type $($Type.FrontEndFormattedName)" }
					}
				}

				if (-not ($Result)) { Write-Verbose "No parameters were found with the $($PsCmdlet.ParameterSetName.Substring(2)) $Term under the step type $($Type.FrontEndFormattedName)" }

				if ($PsCmdlet.ParameterSetName -eq 'ByFrontEndLabel') { Write-Output $Result }
				else { $Result | ForEach-Object { Write-Output ([StepTypeParameter]::New($_)) } }
			}
		}
	}
}

<#
	.SYNOPSIS
		Gathers the steps assigned to an OpRule

	.DESCRIPTION
		A detailed description of the Get-OpRuleStep function.

	.PARAMETER OpRule
		The OpRule to gather the steps of

	.PARAMETER StepNumber
		A description of the StepNumber parameter.

	.PARAMETER LastStep
		A description of the LastStep parameter.

	.PARAMETER RawResult
		A description of the RawResult parameter.

	.EXAMPLE
		PS C:\> Get-OpRuleStep -OpRule OPRULE_Adobe_AcrobatProDC_R3

	.EXAMPLE
		PS C:\> Get-OpRuleStep -OpRule OPRULE_Adobe_AcrobatProDC_R3 -RawResult

	.EXAMPLE
		PS C:\> Get-OpRuleStep -OpRule OPRULE_Adobe_AcrobatProDC_R3 -StepNumber 1,5,7

	.EXAMPLE
		PS C:\> Get-OpRuleStep -OpRule OPRULE_Adobe_Reader_R25 -LastStep

	.NOTES
		Additional information about the function.
#>
function Get-OpRuleStep
{
	[CmdletBinding(DefaultParameterSetName = 'All')]
	[OutputType([StepAssignment])]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[OpRule[]]$OpRule,
		[Parameter(Position = 1)]
		[switch]$RawResult,
		[Parameter(ParameterSetName = 'ByNumber',
				   Position = 2)]
		[int[]]$StepNumber,
		[Parameter(ParameterSetName = 'Last',
				   Position = 2)]
		[switch]$LastStep
	)

	process
	{
		foreach ($Rule in $OpRule)
		{
			$Result = (Use-BCMRestAPI "/oprule/rule/$($Rule.ID)/step/assignments").Assignments
			if ($Result.Count -eq 0)
			{
				Write-Warning "There are no steps in $($Rule.FormattedName)"
				Return
			}
			else
			{
				if ($StepNumber) { $Result = $Result | Where-Object Position -in $StepNumber }
				elseif ($LastStep) { $Result = $Result[-1] }

				if ($RawResult) { Write-Output $Result }
				else
				{
					$Result | ForEach-Object { [StepAssignment]::New($_.ID, $Rule) | Write-Output }
				}
			}
		}
	}
}

<#
	.SYNOPSIS
		Update the attribute of a BCM object instance

	.PARAMETER ObjectType
		The object type of the object that you want to update.
		Use Get-BCMObjectType to get the object for this

	.PARAMETER Instance
		The Object instance to update. This can be any object type under BCMAPI, because the object just needs to have an ID property.
		Only one object type should be used for this

	.PARAMETER ObjectTypeAttribute
		The attribute of the object to update.
		This is not just the name of the object but the unique BCM object for the attribute for that particular object type
		i.e. The object for the Name attribute of an OpRule is distinct from the object for the Name attribute of a Device Group

	.PARAMETER Value
		The new value to update the object's attribute with

	.EXAMPLE
		PS C:\> Update-ObjectInstanceAttribute -ObjectType $ObjectType -Instance $Instance -ObjectTypeAttribute $ObjectTypeAttribute -Value $Value

	.NOTES
		This is a very unstable function as the BCM API is very inconsistent with the required input formatting between object types
#>
function Update-ObjectInstanceAttribute
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ObjectType]$ObjectType,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[BCMAPI[]]$Instance,
		[Parameter(Mandatory = $true)]
		[ObjectTypeAttribute]$ObjectTypeAttribute,
		[Parameter(Mandatory = $true)]
		$Value
	)

	#i.e. Update-ObjectInstanceAttribute -ObjectType $StepAssignmentObjectType -Instance $ScriptedStep -AttributeName $ObjectTypeAttribute -Value '_DB_STEPACTION_GOTO_'

	<#
		Consider replacing the instance and attribute name parameters with a hashtable
			So you can update multiple attributes at once
				i.e. (_DB_ATTR_OPSTEP_STEPACTIONSUCCESS_ & _DB_ATTR_OPSTEP_GOTOSUCCESSSTEP_)
		Considerer prompting with supplied enum names like the prompts in New-StepParameter
	#>
	begin
	{
		if ($Instance.count -gt 1)
		{
			#I am doing this down here instead of in a ValidateScript on the parameters, because that method was not returning a correct count of Instance
			$UniqueObjectTypes = $Instance | ForEach-Object { $_.GetType().Name } | Select-Object -Unique
			if ($UniqueObjectTypes.Count -gt 1) { throw "More than one object type was provided in the Instance parameter:`r`n$($UniqueObjectTypes -join ', ')" }
		}

		$Body = [pscustomobject]@{
			$ObjectTypeAttribute.Name = $Value
		}
	}

	process
	{
		foreach ($BMCAPIObject in $Instance)
		{
			$Result = Use-BCMRestAPI "/object/$($ObjectType.ID)/inst/$($BMCAPIObject.ID)/attrs" -Method PUT -Body ($Body | ConvertTo-Json)
			if ($Result.ErrorCode -ne 0) { throw "Failed to update $($ObjectTypeAttribute.FrontEndName) to `"$Value`" on $($BMCAPIObject.ID)" }
			else { Write-Verbose "Successfully updated $($ObjectTypeAttribute.FrontEndName) to `"$Value`" on $($BMCAPIObject.GetType().Name) $($BMCAPIObject.ID)" }
		}
	}
}

<#
	.SYNOPSIS
		Update the result logic of an OpRule step

	.PARAMETER StepAssignment
		The step assignment to update

	.PARAMETER ResultType
		The result logic of the step to update, on "Fail" or on "Success"

	.PARAMETER Action
		What to do on step fail or success
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER GoToStep
		The step to go to on fail or success

	.EXAMPLE
		PS C:\> Update-OpRuleStepResultCondition -StepAssignment $StepAssignment -ResultType Fail -Action Fail

	.EXAMPLE
		PS C:\> Update-OpRuleStepResultCondition -StepAssignment $StepAssignment -ResultType Success -GoToStep 5

	.INPUTS
		BCMAPI.StepAssignment
		Int
		String
#>
function Update-OpRuleStepResultCondition
{
	[CmdletBinding(DefaultParameterSetName = 'Simple')]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[StepAssignment[]]$StepAssignment,
		[Parameter(Mandatory = $true)]
		[ValidateSet('Fail', 'Success')]
		[string]$ResultType,
		[Parameter(ParameterSetName = 'Simple',
				   Mandatory = $true)]
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$Action,
		[Parameter(ParameterSetName = 'GoTo',
				   Mandatory = $true)]
		[int]$GoToStep
	)

	$OpRuleStepObjectType = Get-BCMObjectType -Name _DB_OBJECTTYPE_OPERATIONALSTEP_

	if ($ResultType -eq 'Fail')
	{
		$OpRuleStepResultConditionAttribute = Get-BCMObjectTypeAttribute -ObjectType $OpRuleStepObjectType -Name _DB_ATTR_OPSTEP_STOPONERROR_
		$OpRuleStepResultStepAttribute = Get-BCMObjectTypeAttribute -ObjectType $OpRuleStepObjectType -Name _DB_ATTR_OPSTEP_GOTOFAILSTEP_
	}
	else
	{
		$OpRuleStepResultConditionAttribute = Get-BCMObjectTypeAttribute -ObjectType $OpRuleStepObjectType -Name _DB_ATTR_OPSTEP_STEPACTIONSUCCESS_
		$OpRuleStepResultStepAttribute = Get-BCMObjectTypeAttribute -ObjectType $OpRuleStepObjectType -Name _DB_ATTR_OPSTEP_GOTOSUCCESSSTEP_
	}

	if ($PSCmdlet.ParameterSetName -eq 'Simple') { Update-ObjectInstanceAttribute -ObjectType $OpRuleStepObjectType -ObjectTypeAttribute $OpRuleStepResultConditionAttribute -Instance $StepAssignment -Value $OpRuleStepResultConditionTranslation[$Action] }
	else
	{
		Update-ObjectInstanceAttribute -ObjectType $OpRuleStepObjectType -ObjectTypeAttribute $OpRuleStepResultConditionAttribute -Instance $StepAssignment -Value $OpRuleStepResultConditionTranslation['GoTo']

		foreach ($Assign in $StepAssignment)
		{
			if ($GoToStep -le $Assign.StepNumber) { Write-Error "Go To step number ($GoToStep) cannot be lower than or equal to the step number ($($Assign.StepNumber))" }
			else { Update-ObjectInstanceAttribute -ObjectType $OpRuleStepObjectType -ObjectTypeAttribute $OpRuleStepResultStepAttribute -Instance $Assign -Value $GoToStep }
		}
	}
}

<#
	.SYNOPSIS
		Add a step to an OpRule

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER StepType
		The step type to add to the OpRule

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Verification
		The setting for the step verification

		Allowable values are:
			FailContinue (Loop while verification fails)

			FailFail (Rule execution fails if the verification fails.)

			FailSucceed (Rule successfully executes if the verification fails)

			SuccessContinue (Loop while verification succeeds)

			SuccessFail (Rule execution fails if the verification succeeds.)

			SuccessSucceed (Rule successfully executes if the verification succeeds)

			None (Do not perform verification)

	.PARAMETER Notes
		The notes to add to the step

	.PARAMETER StepParameters
		The parameters for the new step.
		If this is not used, then the new step is created with all the default values and sample text.

	.EXAMPLE
		PS C:\> Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType

	.EXAMPLE
		PS C:\> Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -OnFail Succeed

	.EXAMPLE
		PS C:\> Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -OnSuccess Succeed

	.EXAMPLE
		PS C:\> Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -Verification FailSucceed

	.EXAMPLE
		PS C:\> Add-SteptoOpRule -OpRule OPRULE_Alex_RESTAPI-Test_R1 -StepType $StepType -StepParameters $StepParameters -Notes 'This step is here because xyz'

	.NOTES
		There is no way to set the succeed or fail condition to go to to a step. To do that you have to use this function to create the command, then use Update-OpRuleStepResultCondition to set the success or fail condition to "Go to Step _"

	.INPUTS
		BCMAPI.Object.OpRule
		BCMAPI.StepType
		BCMAPI.StepParameter
		String
#>
function Add-SteptoOpRule
{
	[CmdletBinding()]
	[OutputType([StepAssignment])]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[StepType]$StepType,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[ValidateSet('FailContinue', 'FailSucceed', 'SuccessContinue', 'SuccessSucceed', 'None')]
		[string]$Verification = 'None',
		[string]$Notes = '',
		[StepParameter[]]$StepParameters
	)

	$StopCondition = $OpRuleStepResultConditionTranslation[$OnFail]

	$OpRuleVerificationConditionTranslation = @{
		#From Get-Enums VerificationActions or (Use-BMCRestAPI '/enum/group?name=VerificationActions').Group.Members.Name

		#Loop while verification fails
		FailContinue    = '_DB_STEPACTION_VERIFLOOPONERROR_'
		#Rule execution failed if the verification fails.
		FailFail	    = '_DB_STEPACTION_VERIFSTOPONERROR_FAILED_'
		#Rule successfully executed if the verification fails
		FailSucceed	    = '_DB_STEPACTION_VERIFSTOPONERROR_'
		#Loop while verification succeeds
		SuccessContinue = '_DB_STEPACTION_VERIFLOOPONSUCCESS_'
		#Rule execution failed if the verification succeeded.
		SuccessFail	    = '_DB_STEPACTION_VERIFSTOPONSUCCESS_FAILED_'
		#Rule successfully executed if the verification succeeded
		SuccessSucceed  = '_DB_STEPACTION_VERIFSTOPONSUCCESS_'
		#Do not perform verification
		None		    = '_DB_STEPACTION_VERIFNONE_'
	}
	$VerificationCondition = $OpRuleVerificationConditionTranslation[$Verification]

	$ParamsforBody = $StepParameters | ForEach-Object {
		$NewValue = if ($_.Value -is [bool])
		{
			([string]$_.Value).ToLower()
		}
		else
		{
			$_.Value
		}
		[pscustomobject]@{
			id = $_.ID
			value = $NewValue
			#The property names ARE case-sensitive
		}
	}

	$Body = [pscustomobject]@{
		stopCondition		  = $StopCondition
		verificationCondition = $VerificationCondition
		#The parameters might need to be ordered
		params			      = $ParamsforBody
	}

	$Result = Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/step/$($StepType.ID)" -Body ($Body | ConvertTo-Json) -Method PUT

	$StepAssignmentID = $Result.Assignment.ID
	if ($StepAssignmentID -eq $null)
	{
		if ($Result.Fault.Code)
		{
			$ErrorText = Get-BMCErrorCodeText $Result.Fault.Code
			Throw "Failed to add step to OpRule with with error code $($Result.Fault.Code):`r`n$ErrorText"
		}
		else
		{
			Throw "Failed to add step to OpRule with this result: $($Result.Fault)"
		}
	}
	else
	{
		$NewStep = [StepAssignment]::New($StepAssignmentID, $OpRule)
		Update-OpRuleStepResultCondition -StepAssignment $NewStep -ResultType Success -Action $OnSuccess
		Write-Verbose "Successfully added step to $($OpRule.FormattedName) with an assignment ID of $StepAssignmentID"
		Write-Output ([StepAssignment]::New($StepAssignmentID, $OpRule))
	}
}

<#
	.SYNOPSIS
		Adds a package to an OpRule

	.PARAMETER Package
		The package to add
		If adding by name, make sure to include the extension ('.cst' or '.msi') in the name

	.PARAMETER OpRule
		The OpRule to add the packages to

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.EXAMPLE
		PS C:\> Add-PackagetoOpRule -Package 'PKG_OpenText_Exstream_16-3-5_R1.cst' -OpRule 'OPRULE_OpenText_Exstream_R4'

	.EXAMPLE
		PS C:\> Add-PackagetoOpRule -Package 'PKG_OpenText_Exstream_16-3-5_R1.cst' -OpRule 'OPRULE_OpenText_Exstream_R4' -OnSuccess 'Fail'

	.EXAMPLE
		PS C:\> Add-PackagetoOpRule -Package 'PKG_OpenText_Exstream_16-3-5_R1.cst' -OpRule 'OPRULE_OpenText_Exstream_R4' -OnFail 'Continue'
#>
function Add-PackagetoOpRule
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[Package[]]$Package,
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail'
	)

	process
	{
		foreach ($PackageObject in $Package)
		{
			$Result = Use-BCMRestAPI "/oprule/rule/$($OpRule.ID)/package/$($PackageObject.ID)" -Method PUT
			if ($Result.ErrorCode -eq 0) { Write-Verbose "Successfully added $($PackageObject.FormattedName) to $($OpRule.FormattedName)" -InformationAction Continue }
			else { throw "Failed to add $($PackageObject.FormattedName) to $($OpRule.FormattedName) with an error code of $($Result.ErrorCode)" }
		}
		Update-OpRuleStepResultCondition -StepAssignment (Get-OpRuleStep $OpRule -LastStep) -ResultType Success -Action $OnSuccess
		Update-OpRuleStepResultCondition -StepAssignment (Get-OpRuleStep $OpRule -LastStep) -ResultType Fail -Action $OnFail
	}
}

<#
	.SYNOPSIS
		Create the needed step parameter objects for a given step type

	.DESCRIPTION
		This can be run in one of two ways:
			Guided, where you are prompted for the value for each needed parameter
			Provided, where you provide the hash table with the backend parameter name and the value

	.PARAMETER StepType
		The step type to add the parameters for

	.PARAMETER Values
		A hashtable containing the backend property names and their values

	.EXAMPLE
		PS C:\> New-StepParameter -StepType $StepType

	.EXAMPLE
		PS C:\> New-StepParameter -StepType $StepType -Values @{
			_DB_STEPPARAM_TARGETPATHURL_	   = 'C:\Windows\Temp\media\blah.txt'
			_DB_STEPPARAM_FORCEDELETEREADONLY_ = $true
			_DB_STEPPARAM_ONLYDELETECONTENT_   = $false
		}

	.INPUTS
		BCMAPI.StepType
		Hashtable
#>
function New-StepParameter
{
	[CmdletBinding(DefaultParameterSetName = 'Guided')]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[StepType]$StepType,
		[Parameter(ParameterSetName = 'Provided',
				   Mandatory = $true)]
		[Hashtable]$Values
	)

	process
	{
		$StepTypeParameters = Get-StepTypeParameter $StepType

		Write-Debug "Parameter Set Name is $($PSCmdlet.ParameterSetName)"

		if ($PSCmdlet.ParameterSetName -eq 'Guided')
		{
			foreach ($Parameter in $StepTypeParameters)
			{
				Write-Host "$($Parameter.FrontEndLabel) is type $($Parameter.Type). Please provide value:"
				switch ($Parameter.Type)
				{
					Boolean {
						switch (Read-Host 'T or F?')
						{
							T { $Value = 'true'; Break }
							F { $Value = 'false'; Break }
							Default { Throw 'Invalid Response' }
						}
					}
					`Enum {
						Write-Information "Allowable values are:" -InformationAction Continue
						$Enums = Get-Enums $Parameter.EnumName
						$i = -1
						Write-Information ($Enums | ForEach-Object { $i++; "[$i] $_" } | Out-String).Trim()
						$Value = $Enums[[int](Read-Host 'Choose a value by the number')]
					}
					default
					{
						$Value = [string](Read-Host)
					}
				}
				Write-Output ([StepParameter]::New($Parameter, $Value))
			}
		}
		else
		{
			foreach ($Param in $StepTypeParameters)
			{
				$CorrespondingValue = $Values.($Param.Label)
				if ($CorrespondingValue -eq $null) { throw "No value exists for $($Param.FrontEndLabel)" }
				else { Write-Output ([StepParameter]::New($Param, $CorrespondingValue)) }
			}
		}
	}
}

<#
	.SYNOPSIS
		Add an execute program step to an OpRule

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER RunCommand
		The Run Command for the step

	.PARAMETER WaitforEndofExecution
		Forces the step to wait until the command has finished executing before going to the next step

	.PARAMETER BackgroundMode
		Runs the command in background mode

	.PARAMETER RunProgramInItsContext
		Runs the command in its context

	.PARAMETER ValidReturnCodes
		The return codes from the run command to count as successes

	.PARAMETER UseAShell
		Runs the command in a shell

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad'

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -WaitforEndofExecution $false

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -BackgroundMode $false

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -RunProgramInItsContext $false

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -ValidReturnCodes 0, 1603

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -UseAShell $true

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -OnFail Succeed

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -OnSuccess Fail

	.EXAMPLE
		PS C:\> Add-ExecuteProgramStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -RunCommand 'notepad' -Notes 'This was created from the API'

	.INPUTS
		BCMAPI.Object.OpRule
		Bool
		Int
		String
#>
function Add-ExecuteProgramStep
{
	[CmdletBinding()]
	[OutputType([StepAssignment])]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[string]$RunCommand,
		[bool]$WaitforEndofExecution = $true,
		[bool]$BackgroundMode = $true,
		[bool]$RunProgramInItsContext = $true,
		[int[]]$ValidReturnCodes = 0,
		[bool]$UseAShell = $false,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[string]$Notes = ''
	)

	$StepType = Get-StepType -Name '_DB_STEPNAME_RUNPROGRAM_'

	$Values = @{
		_DB_STEPPARAM_PROGRAMPATH_	    = $RunCommand
		_DB_STEPPARAM_WAITENDOFRUN_	    = $WaitforEndofExecution
		_DB_STEPPARAM_BLINDMODE_	    = $BackgroundMode
		_DB_STEPPARAM_PROGRAMCONTEXT_   = $RunProgramInItsContext
		_DB_STEPPARAM_VALIDERETURNCODE_ = $ValidReturnCodes -join ','
		_DB_STEPPARAM_SHELLPARSER_	    = $UseAShell
	}

	$Parameters = New-StepParameter -StepType $StepType -Values $Values

	Add-SteptoOpRule -OpRule $OpRule -StepType $StepType -StepParameters $Parameters -OnFail $OnFail -OnSuccess $OnSuccess -Notes $Notes
}

<#
	.SYNOPSIS
		Adds a delete directory step to an OpRule

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER TargetPath
		The path of the directory of files to delete

	.PARAMETER DeleteReadOnly
		Deletes the read only files as well

	.PARAMETER DeleteDirectoryContentOnly
		Deletes just the content of the given directory

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET'

	.EXAMPLE
		PS C:\> Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -DeleteReadOnly $false

	.EXAMPLE
		PS C:\> Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -DeleteDirectoryContentOnly $true

	.EXAMPLE
		PS C:\> Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -OnFail 'Continue'

	.EXAMPLE
		PS C:\> Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -OnSuccess 'Fail'

	.EXAMPLE
		PS C:\> Add-DeleteDirectoryStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -TargetPath 'C:\Windows\Temp\Media\BMC\JET' -Notes 'This step made by the API'

	.INPUTS
		BCMAPI.Object.OpRule
		Bool
		String
#>
function Add-DeleteDirectoryStep
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[string]$TargetPath,
		[bool]$DeleteReadOnly = $true,
		[bool]$DeleteDirectoryContentOnly = $false,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[string]$Notes = ''
	)

	$StepType = Get-StepType -Name '_DB_STEPNAME_DELETEDIRECTORY_'

	$Values = @{
		_DB_STEPPARAM_TARGETPATHURL_	   = $TargetPath
		_DB_STEPPARAM_FORCEDELETEREADONLY_ = $DeleteReadOnly
		_DB_STEPPARAM_ONLYDELETECONTENT_   = $DeleteDirectoryContentOnly
	}

	$Parameters = New-StepParameter -StepType $StepType -Values $Values

	Add-SteptoOpRule -OpRule $OpRule -StepType $StepType -StepParameters $Parameters -OnFail $OnFail -OnSuccess $OnSuccess -Notes $Notes
}

<#
	.SYNOPSIS
		Adds a registry management step

	PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER Key
		The full registry key path

	.PARAMETER Operation
		The registry key operation to do
		Allowable values are: 'Add/Modify', 'Delete'

	.PARAMETER ValueName
		The value name for the registry key property
		If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

	.PARAMETER Value
		The value for the registry key property
		If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

	.PARAMETER ValueType
		The type of the registry key value.
		Allowable values are: 'String', 'Binary', 'DWORD', 'ExpandableString', 'Multi-String', 'QWORD'

	.PARAMETER BinaryValueInHexFormat
		Formats the binary value in hex notation

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test'

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -Operation Delete

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -OnFail Continue

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -OnSuccess Fail

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -Notes 'This step made by the API'

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'DisplayName'

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'UninstallString' -Value 'cmd.exe /c'

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'UninstallString' -Value '12345' -ValueType 'DWORD'

	.EXAMPLE
		PS C:\> Add-RegistryManagementStep -OpRule 'OPRULE_Alex_RESTAPI-Test_R1' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OPRULE_Alex_RESTAPI-Test' -ValueName 'UninstallString' -Value '0' -ValueType 'Binary' -BinaryValueInHexFormat

	.INPUTS
		BCMAPI.Object.OpRule
		String
#>
function Add-RegistryManagementStep
{
	[CmdletBinding(DefaultParameterSetName = 'KeyValue')]
	[OutputType([StepAssignment])]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[string]$Key,
		[ValidateSet('Add/Modify', 'Delete')]
		[string]$Operation = 'Add/Modify',
		[Parameter(ParameterSetName = 'KeyValue')]
		[string]$ValueName = 'Open this step and delete this text',
		[Parameter(ParameterSetName = 'KeyValue')]
		[string]$Value = 'Open this step and delete this text',
		[Parameter(ParameterSetName = 'KeyValue')]
		[ValidateSet('String', 'Binary', 'DWORD', 'ExpandableString', 'Multi-String', 'QWORD')]
		[string]$ValueType = 'String',
		[Parameter(ParameterSetName = 'KeyValue')]
		[switch]$BinaryValueInHexFormat,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[string]$Notes = ''
	)

	$StepType = Get-StepType -Name '_DB_STEPNAME_REGISTRYMANAGEMENT_'

	$OperationTranslationTable = @{
		'Add/Modify' = '_MISC_ADDMODIFY_'
		'Delete'	 = '_MISC_DELETE_'
	}

	$ValueTypeTranslationTable = @{
		'String'		   = 'RegSz'
		'Binary'		   = 'RegBinary'
		'DWORD'		       = 'RegDword'
		'ExpandableString' = 'RegExpandSz'
		'Multi-String'	   = 'RegMultiSz'
		'QWORD'		       = 'RegQword'
	}

	$Values = @{
		_DB_STEPPARAM_REGISTRYOPERATION_ = $OperationTranslationTable[$Operation]
		_DB_STEPPARAM_REGISTRYKEY_	     = $Key
		_DB_STEPPARAM_REGISTRYVALUENAME_ = $ValueName
		_DB_STEPPARAM_REGISTRYVALUE_	 = $Value
		_DB_STEPPARAM_REGISTRYVALUETYPE_ = $ValueTypeTranslationTable[$ValueType]
		_DB_STEPPARAM_ISREGBINARYHEXAVALUE_ = if ($BinaryValueInHexFormat.IsPresent) { $true } else { '' }
	}

	$Parameters = New-StepParameter -StepType $StepType -Values $Values

	Add-SteptoOpRule -OpRule $OpRule -StepType $StepType -StepParameters $Parameters -OnFail $OnFail -OnSuccess $OnSuccess -Notes $Notes
}

<#
	.SYNOPSIS
		Adds the steps for the registry keys for the OpRule markers in Programs & Features

	.PARAMETER OpRule
		The OpRule to add the steps to

	.EXAMPLE
		PS C:\> Add-OpRuleMarkerSteps -OpRule 'OPRULE_Alex_RESTAPI-Test_R1'

	.INPUTS
		BCMAPI.Object.OpRule
#>
function Add-OpRuleMarkerSteps
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule[]]$OpRule
	)

	process
	{
		foreach ($Rule in $OpRule)
		{
			$RuleRevision = $Rule.Name.Split('_')[-1]
			$RevisionCharacterStart = $Rule.Name.IndexOf($RuleRevision)
			$TrimmedOpRuleName = $Rule.Name.Substring(0, $RevisionCharacterStart - 1)
			$RegistryKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$TrimmedOpRuleName"

			Add-RegistryManagementStep -OpRule $Rule -Key $RegistryKey -ValueName 'DisplayName' -Value $TrimmedOpRuleName
			Add-RegistryManagementStep -OpRule $Rule -Key $RegistryKey -ValueName 'UninstallString' -Value 'cmd.exe /c'
			Add-RegistryManagementStep -OpRule $Rule -Key $RegistryKey -ValueName 'DisplayVersion' -Value $RuleRevision
			Add-RegistryManagementStep -OpRule $Rule -Key $RegistryKey -ValueName 'Publisher' -Value $ITDepartmentName
		}
	}
}

<#
	.SYNOPSIS
		Adds an execute program step with the run command for the Universal Version Checker

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER VersionCheckerRevision
		The revision number of the universal version checker

	.PARAMETER FiletoCheck
		The path of the file to do the version check on

	.PARAMETER VersionNumber
		The version number for the version check

	.PARAMETER VersionType
		The version property on the file object (from "(Get-ItemProperty $FilePath).VersionInfo") to check off of.
		Allowable values: 'FileVersion', 'ProductVersion', 'FileVersionRaw', 'ProductVersionRaw'

	.PARAMETER ReplaceComma
		If the file's version number uses commas instead of periods, use this for replace them so the version number can be recognized as a version number object

	.PARAMETER ForcePath
		This forces the file to only be looked for in the path specified.
		By default the version checker looks for the file in both "Program Files" & "Program Files (x86)"

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275'

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '1.2.3.4' -VersionType 'FileVersionRaw'

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -ReplaceComma

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -ForcePath

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -ForcePath

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -OnFail 'Continue'

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -OnSuccess 'Fail'

	.EXAMPLE
		PS C:\> Add-UniversalVersionCheckerStep -OpRule 'OPRULE_Adobe_Reader_R27' -VersionCheckerRevision '10' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe' -VersionNumber '15.7.20033.133275' -Notes 'Made with BCM Rest API'
#>
function Add-UniversalVersionCheckerStep
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[int]$VersionCheckerRevision = 11,
		[Parameter(Mandatory = $true)]
		[string]$FiletoCheck,
		[Parameter(Mandatory = $true)]
		[string]$VersionNumber,
		[ValidateSet('FileVersion', 'ProductVersion', 'FileVersionRaw', 'ProductVersionRaw')]
		[string]$VersionType = 'FileVersion',
		[switch]$ReplaceComma,
		[switch]$ForcePath,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[string]$Notes = ''
	)

	if ($VersionType -ne 'FileVersion')
	{
		$RunCommand = "powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File C:\Windows\Temp\Media\BMC\JET\PKG_JET_Universal_VC_R$VersionCheckerRevision.ps1 -TargetVersion $VersionNumber -Path `"$FiletoCheck`" -VersionType $VersionType"
	}
	else
	{
		$RunCommand = "powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File C:\Windows\Temp\Media\BMC\JET\PKG_JET_Universal_VC_R$VersionCheckerRevision.ps1 -TargetVersion $VersionNumber -Path `"$FiletoCheck`""
	}

	if ($ReplaceComma.IsPresent)
	{
		$RunCommand + ' -ReplaceComma'
	}
	if ($ForcePath.IsPresent)
	{
		$RunCommand + ' -ForcePath'
	}

	Add-ExecuteProgramStep -OpRule $OpRule -RunCommand $RunCommand -OnFail $OnFail -OnSuccess $OnSuccess -Notes $Notes
}

<#
	.SYNOPSIS
		Adds a check for file step to an OpRule

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER FilePath
		The path of the file to check for

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Verification
		The setting for the step verification

		Allowable values are:
			FailContinue (Loop while verification fails)

			FailFail (Rule execution fails if the verification fails.)

			FailSucceed (Rule successfully executes if the verification fails)

			SuccessContinue (Loop while verification succeeds)

			SuccessFail (Rule execution fails if the verification succeeds.)

			SuccessSucceed (Rule successfully executes if the verification succeeds)

			None (Do not perform verification)

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe'

	.EXAMPLE
		PS C:\> Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -OnFail 'Continue'

	.EXAMPLE
		PS C:\> Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -OnSuccess 'Fail'

	.EXAMPLE
		PS C:\> Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -Verification 'SuccessContinue'

	.EXAMPLE
		PS C:\> Add-CheckforFileStep -OpRule 'OPRULE_Alex_RestAPI-Test_R1' -FilePath 'C:\Windows\System32\notepad.exe' -Notes 'Created by BCM Rest API'
#>
function Add-CheckforFileStep
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[string]$FilePath,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[ValidateSet('FailContinue', 'FailSucceed', 'SuccessContinue', 'SuccessSucceed', 'None')]
		[string]$Verification = 'None',
		[string]$Notes
	)

	$StepType = Get-StepType -Name '_DB_STEPNAME_CHECKFORFILE_'

	$Values = @{
		_DB_STEPPARAM_FILENAME_ = $FilePath
	}

	$Parameters = New-StepParameter -StepType $StepType -Values $Values

	#This is not currently working. I don't know why. The step type ID and the parameter ID are correct
	Add-SteptoOpRule -OpRule $OpRule -StepType $StepType -StepParameters $Parameters -OnFail $OnFail -OnSuccess $OnSuccess -Verification $Verification -Notes $Notes
}

<#
	.SYNOPSIS
		Adds a check for string in file step

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER FilePath
		The path of the file to check inside of

	.PARAMETER String
		The string to check for inside the file

	.PARAMETER ErrorifFound
		Sets the step to error out if the string is found

	.PARAMETER MatchCase
		Forces the lookup to match the case of the given string

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Verification
		The setting for the step verification

		Allowable values are:
			FailContinue (Loop while verification fails)

			FailFail (Rule execution fails if the verification fails.)

			FailSucceed (Rule successfully executes if the verification fails)

			SuccessContinue (Loop while verification succeeds)

			SuccessFail (Rule execution fails if the verification succeeds.)

			SuccessSucceed (Rule successfully executes if the verification succeeds)

			None (Do not perform verification)

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">'

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -ErrorIfFound $true

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -MatchCase $true

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -OnFail 'Continue'

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -OnSuccess 'Fail'

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -Verification 'FailContinue'

	.EXAMPLE
		PS C:\> Add-CheckforStringinFileStep -OpRule $value1 -FilePath 'C:\ProgramData\EnterpriseMode\EnterpriseMode.XML' -String '<site-list version="63">' -Notes 'Made using the BCM Rest API'
#>
function Add-CheckforStringinFileStep
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[string]$FilePath,
		[Parameter(Mandatory = $true)]
		[string]$String,
		[bool]$ErrorIfFound = $false,
		[bool]$MatchCase = $false,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[ValidateSet('FailContinue', 'FailSucceed', 'SuccessContinue', 'SuccessSucceed', 'None')]
		[string]$Verification = 'None',
		[string]$Notes
	)

	$StepType = Get-StepType -Name '_DB_STEPNAME_STRINGINFILE_'

	$Values = @{
		_DB_STEPPARAM_FILENAME_	      = $FilePath
		_DB_STEPPARAM_SEARCHEDSTRING_ = $String
		_DB_STEPPARAM_ERRORIFFOUND_   = $ErrorifFound
		_DB_STEPPARAM_CASESENSITIVE_  = $MatchCase
	}

	$Parameters = New-StepParameter -StepType $StepType -Values $Values

	Add-SteptoOpRule -OpRule $OpRule -StepType $StepType -StepParameters $Parameters -OnFail $OnFail -OnSuccess $OnSuccess -Verification $Verification -Notes $Notes
}

<#
	.SYNOPSIS
		Adds a registry key verification step

	.PARAMETER OpRule
		The OpRule to add the step to

	.PARAMETER Key
		The full registry key path

	.PARAMETER Property
		The registry key property name to check for
		If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

	.PARAMETER Value
		The value of registry key property to check for.
		This must be used with the property
		If this is left blank, the step needs to be opened in the GUI, and the sample text deleted, because the API does not properly set a blank value.

	.PARAMETER BinaryKeyinHexNotation
		Interprets the hex notated value as a binary value

	.PARAMETER OnFail
		What to do if the step fails
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER OnSuccess
		What to do if the step succeeds
		Allowable values are: 'Continue', 'Fail', 'Succeed'

	.PARAMETER Verification
		The setting for the step verification

		Allowable values are:
			FailContinue (Loop while verification fails)

			FailFail (Rule execution fails if the verification fails.)

			FailSucceed (Rule successfully executes if the verification fails)

			SuccessContinue (Loop while verification succeeds)

			SuccessFail (Rule execution fails if the verification succeeds.)

			SuccessSucceed (Rule successfully executes if the verification succeeds)

			None (Do not perform verification)

	.PARAMETER Notes
		The notes to add to the step

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS'

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Property 'VMwareAgentToolsRebootCounter'

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Property 'VMwareAgentToolsRebootCounter' -Value 2

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Property 'VMwareAgentToolsRebootCounter' -Value 0 -BinaryKeyinHexNotation $true

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -OnFail Succeed

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -OnSuccess Fail

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Verification 'SuccessSucceed'

	.EXAMPLE
		PS C:\> Add-RegistryKeyVerificationStep -OpRule 'OPRULE_VMware_HorizonAgent-Tools_R14' -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\JTS' -Notes 'Created with the BCM API'
#>
function Add-RegistryKeyVerificationStep
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OpRule,
		[Parameter(Mandatory = $true)]
		[string]$Key,
		[string]$Property = 'Open the OpRule and hit OK to remove me',
		[string]$Value = 'Open the OpRule and hit OK to remove me',
		[bool]$BinaryKeyinHexNotation = $false,
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnFail = 'Fail',
		[ValidateSet('Continue', 'Fail', 'Succeed')]
		[string]$OnSuccess = 'Continue',
		[ValidateSet('FailContinue', 'FailSucceed', 'SuccessContinue', 'SuccessSucceed', 'None')]
		[string]$Verification = 'None',
		[string]$Notes
	)

	$StepType = Get-StepType -Name '_DB_STEPNAME_REGISTRYCHECK_'

	if (($Property -ne '') -and ($Property -ne 'Open the OpRule and hit OK to remove me'))
	{
		$CheckProperty = $true
	}
	else { $CheckProperty = $false }

	if (($Value -ne '') -and ($Value -ne 'Open the OpRule and hit OK to remove me'))
	{
		$CheckValue = $true
	}
	else { $CheckProperty = $false }

	$Values = @{
		_DB_STEPPARAM_REGISTRYKEYTOCHECK_   = $Key
		_DB_STEPPARAM_CHECKKEYNAME_		    = $CheckProperty
		_DB_STEPPARAM_REGISTRYVALUENAME_    = $Property
		_DB_STEPPARAM_CHECKKEYVALUE_	    = $CheckValue
		_DB_STEPPARAM_REGISTRYVALUE_	    = $Value
		_DB_STEPPARAM_IFREGBINARYHEXAVALUE_ = $BinaryKeyinHexNotation
	}

	$Parameters = New-StepParameter -StepType $StepType -Values $Values

	Add-SteptoOpRule -OpRule $OpRule -StepType $StepType -StepParameters $Parameters -OnFail $OnFail -OnSuccess $OnSuccess -Verification $Verification -Notes $Notes
}

<#
	.SYNOPSIS
		Creates a new standard OpRule in BMC

	.DESCRIPTION
		 Creates a new OpRule and adds these to it:
			Version Checker Package
			A version checker step
			The specified packages
			A second version checker step
			The 4 registry keys for the OpRule marker
			Two delete directory steps
				"C:\Windows\Temp\media\bmc\$Vendor"
				"C:\Windows\Temp\media\bmc\JET"

	.PARAMETER Vendor
		The name of the vendor of the application you are packaging
		This is used in the OpRule Name, OpRule Marker, and a delete directory step

	.PARAMETER Application
		The name of the application you are packaging
		This is used in the OpRule Name, OpRule Marker, and a delete directory step

	.PARAMETER OpRuleRevision
		The revision for the new OpRule
		This is used in the OpRule Name and OpRule Marker

	.PARAMETER VersionNumber
		The version number of the application's main exe
		This is used in the version checker in the execute program steps

	.PARAMETER FiletoCheck
		The file to check with the version checker in the execute program steps

	.PARAMETER UniversalVersionCheckerRevision
		The universal version checker package revision to use (PKG_JET_Universal_VC_R*)
		This is only used to add the package to the OpRule, and is not used in the creation of the execute program steps.

	.PARAMETER OpRuleFolder
		The OpRule folder to place the new OpRule in

	.PARAMETER Environment
		The environment of the application install, if the install is environment is specific.
		This is generally only needed if you are creating multiple editions of the OpRule for different environments.
		This is used in the OpRule Name and OpRule Marker
		Allowable values are: 'Physical', 'Virtual', 'Desktop', 'Laptop', 'VDI', 'Server'

	.PARAMETER Region
		The region of the application install, if the install is region is specific.
		This is generally only needed if you are creating multiple editions of the OpRule for different regions.
		This is used in the OpRule Name and OpRule Marker
		Allowable values are: 'DEV', 'MOD', 'PROD'

	.PARAMETER Edition
		The edition of the application install, if the install is edition is specific.
		This is generally only needed if you are creating multiple editions of the OpRule for different editions.
		This is used in the OpRule Name and OpRule Marker

	.PARAMETER PackagesToAdd
		The packages to add to the OpRule that install the application.
		These will be placed between the two version checker execute program steps

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'Adobe' -Application 'Reader' -OpRuleRevision 27 -VersionNumber '15.7.20033.133275' -FiletoCheck 'C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe'

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'Oracle' -Application 'JavaRuntimeEnvironment' -OpRuleRevision 13 -VersionNumber '8.0.2410.7' -FiletoCheck 'C:\Program Files\Java\jre1.8.*\bin\java.exe' -UniversalVersionCheckerRevision 9

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'Symantec' -Application 'SEP' -OpRuleRevision 14 -VersionNumber '14.2.5323.2000' -FiletoCheck 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\14.2.5323.2000.105\Bin\SMC.EXE' -OpRuleFolder 'Testing Operational Rules'

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'Rapid7' -Application 'Insight Agent' -OpRuleRevision 2 -VersionNumber '2.5.3.8' -FiletoCheck 'C:\Program Files\Rapid7\Insight Agent\components\insight_agent\2.5.3.8\ir_agent.exe' -Environment Laptop

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'ARC' -Application 'CASE' -OpRuleRevision 4 -VersionNumber '2019.6.1.0' -FiletoCheck 'C:\Program Files\Actuarial Resources Corporation\CASE 2019.06.01 - CASE_PROD\Case.exe' -Region 'PROD'

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'Google' -Application 'Chrome' -OpRuleRevision 16 -VersionNumber '80.0.3987.122' -FiletoCheck 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -Edition 'Enterprise'

	.EXAMPLE
		PS C:\> New-StandardOpRule -Vendor 'SovosETM' -Application 'WingsClient' -OpRuleRevision 2 -VersionNumber '2019.12.7313.21381' -FiletoCheck 'C:\Program Files (x86)\EagleTM\Wings\WingsClient.exe' -PackagesToAdd 'PKG_SovosETM_WingsClient_2019-12-7267-30384_UNINSTALL_R1.msi', 'PKG_SovosETM_WingsClient_2019-12-7313-21381_R1.msi'

	.INPUTS
		Int
		String
		BCMAPI.Object.OpRuleFolder
		BCMAPI.Object.Package.CustomPackage
#>
function New-StandardOpRule
{
	[CmdletBinding()]
	[OutputType([OpRule])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$Vendor,
		[Parameter(Mandatory = $true)]
		[string]$Application,
		[Parameter(Mandatory = $true)]
		[int]$OpRuleRevision,
		[Parameter(Mandatory = $true)]
		[string]$VersionNumber,
		[Parameter(Mandatory = $true)]
		[string]$FiletoCheck,
		[int]$UniversalVersionCheckerRevision = 11,
		[OpRuleFolder]$OpRuleFolder = (Get-BCMCommonObject -Name '_OPRULES_FOR_APPLICATION_DEPLOYMENT_DEVICE_GROUPS' -ObjectType 'Operational Rule Folder'),
		[ValidateSet('Physical', 'Virtual', 'Desktop', 'Laptop', 'VDI', 'Server')]
		[string]$Environment,
		[ValidateSet('DEV', 'MOD', 'PROD')]
		[string]$Region,
		[string]$Edition,
		[Package[]]$PackagesToAdd
	)

	$Conditionals = $Environment, $Region, $Edition | Where-Object { -not ([string]::IsNullOrEmpty($_)) }

	$Vendor = $Vendor.Replace(' ', '')
	$Application = $Application.Replace(' ', '')

	if ($Conditionals -eq $null) { $OpRuleName = 'OPRULE', $Vendor, $Application, "R$OpRuleRevision" }
	else { $OpRuleName = 'OPRULE', $Vendor, "$Application-$($Conditionals -join '-')", "R$OpRuleRevision" }

	$OpRule = New-OpRule -Name ($OpRuleName -join '_') -OpRuleFolder $OpRuleFolder

	Add-PackagetoOpRule -Package "PKG_JET_Universal_VC_R$UniversalVersionCheckerRevision.cst" -OpRule $OpRule

	Write-Verbose "Adding version checker step"
	$FirstVersionCheckerStep = Add-UniversalVersionCheckerStep -OpRule $OpRule -FiletoCheck $FiletoCheck -VersionNumber $VersionNumber

	if ($PackagesToAdd) { Add-PackagetoOpRule -Package $PackagesToAdd -OpRule $OpRule }

	Write-Verbose "Adding version checker step"
	Add-UniversalVersionCheckerStep -OpRule $OpRule -FiletoCheck $FiletoCheck -VersionNumber $VersionNumber | Out-Null

	Write-Verbose "Adding OpRule marker steps"
	$OpRuleMarkerSteps = Add-OpRuleMarkerSteps -OpRule $OpRule

	Write-Verbose "Setting first version checker step to go to the first OpRule marker step on success"
	Update-OpRuleStepResultCondition -StepAssignment $FirstVersionCheckerStep -ResultType Success -GoToStep $OpRuleMarkerSteps[0].StepNumber

	Write-Verbose "Setting first version checker step to continue on fail"
	Update-OpRuleStepResultCondition -StepAssignment $FirstVersionCheckerStep -ResultType Fail -Action Continue

	Write-Verbose "Adding delete directory steps"
	Add-DeleteDirectoryStep -OpRule $OpRule -TargetPath "C:\Windows\Temp\Media\BMC\$Vendor" | Out-Null
	Add-DeleteDirectoryStep -OpRule $OpRule -TargetPath "C:\Windows\Temp\Media\BMC\JET" | Out-Null

	Write-Output $OpRule
}

function Replace-OpRuleinDeviceGroup
{
	[CmdletBinding()]
	[OutputType([OpRuleDeviceGroupAssignment])]
	param
	(
		[Parameter(Mandatory = $true)]
		[OpRule]$OldOpRule,
		[Parameter(Mandatory = $true)]
		[OpRule]$NewOpRule,
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[DeviceGroup[]]$DeviceGroup,
		[switch]$AssignInActiveState
	)
	process
	{
		foreach ($Group in $DeviceGroup)
		{
			$OldAssignment = Get-DeviceGroupAssignedtoOpRule -OpRule $OldOpRule | Where-Object { $_.DeviceGroup.Name -eq $Group.Name }

			if ($OldAssignment)
			{
				Write-Verbose "Found OpRule Assignment $($OldAssignment.ID)"
				Remove-DeviceGroupfromOpRule -Assignment $OldAssignment

				if ($AssignInActiveState)
				{
					Add-DeviceGrouptoOpRule -DeviceGroup $Group -OpRule $NewOpRule -Active
				}
				else
				{
					Add-DeviceGrouptoOpRule -DeviceGroup $Group -OpRule $NewOpRule
				}
			}
			else
			{
				Write-Error "Failed to find an assignment of $($OldOpRule.Name) to $($Group.Name)"
			}
		}
	}
}

Write-Verbose 'Finished defining Extra functions'
#endregion Extra functions

#region vSphere Setup

if ($vCenterstoConnectTo -ne 'None')
{
	Write-Verbose 'Connecting to vCenters'

	$vCenterNames = @()

	switch ($vCenterstoConnectTo)
	{
		'All' {

			# Prod VD
			1 .. 4 | ForEach-Object { $vCenterNames += "vdvcentervd00$($_)a" }
			1 .. 4 | ForEach-Object { $vCenterNames += "vdvcentervd00$($_)c" }

			# Prod SP
			2 .. 2 | ForEach-Object { $vCenterNames += "vdvcentersp00$($_)a" }
			2 .. 2 | ForEach-Object { $vCenterNames += "vdvcentersp00$($_)c" }

			# Dev VD
			1, 2, 5 | ForEach-Object { $vCenterNames += "vdvcentervdd0$($_)a" }
			1, 2, 5 | ForEach-Object { $vCenterNames += "vdvcentervdd0$($_)c" }

			# Dev SP
			1 .. 1 | ForEach-Object { $vCenterNames += "vdvcenterspd0$($_)a" }
			1 .. 1 | ForEach-Object { $vCenterNames += "vdvcenterspd0$($_)c" }
		}
		'DEV' {
			# Dev VD
			1, 2, 5, 6 | ForEach-Object { $vCenterNames += "vdvcentervdd0$($_)a" }
			1, 2, 5, 6 | ForEach-Object { $vCenterNames += "vdvcentervdd0$($_)c" }

			# Dev SP
			1 .. 1 | ForEach-Object { $vCenterNames += "vdvcenterspd0$($_)a" }
			1 .. 1 | ForEach-Object { $vCenterNames += "vdvcenterspd0$($_)c" }
		}
		'Factory and Hot Pool' { $vCenterNames = 'vdvcentervd001a', 'vdvcentervd001c' }
		'PROD' {
			# Prod VD
			1 .. 4 | ForEach-Object { $vCenterNames += "vdvcentervd00$($_)a" }
			1 .. 4 | ForEach-Object { $vCenterNames += "vdvcentervd00$($_)c" }

			# Prod SP
			2 .. 2 | ForEach-Object { $vCenterNames += "vdvcentersp00$($_)a" }
			2 .. 2 | ForEach-Object { $vCenterNames += "vdvcentersp00$($_)c" }
		}
		'Support Clusters' {
			$vCenterNames = 'vdvcentersp002a', 'vdvcentersp002c', 'vdvcenterspd01a', 'vdvcenterspd01c'
		}
		default { "$_ is not a valid group of vCenters" }
	}

	$vCenters = foreach ($Name in $vCenterNames)
	{
		Write-Verbose "Connecting to $Name"
		try { Connect-VIServer -Server $Name -Credential $vSphereCredential -ErrorAction Stop -WarningAction SilentlyContinue }
		catch [System.TimeoutException] { throw "Connection timed out while connecting to $Name" }
		catch { Write-Error $_ -ErrorAction Stop }
	}

	Write-Verbose 'Finished connecting to vCenters'

	Write-Verbose 'Defining Factory vSphere objects'
	$FactoryServers = $vCenters | Where-Object Name -in 'vdvcentervd001a', 'vdvcentervd001c'
	$FactoryVMHosts = Get-VMHost "vdihost7002a.$CompanyDomainName", "vdihost7002c.$CompanyDomainName" -ErrorAction Stop
	$FactoryDatastores = Get-Datastore -RelatedObject $FactoryVMHosts -ErrorAction Stop | Where-Object Name -Like '*ilio*' | Sort-Object Name
	Write-Verbose 'Finished defining Factory objects'

	Write-Verbose 'Defining Hot Pool vSphere objects'
	$HotPoolServers = $FactoryServers
	$HotPoolHosts = Get-VMHost "vdihost7005a.$CompanyDomainName", "vdihost7005c.$CompanyDomainName"
	$HotPoolDatastores = Get-Datastore -RelatedObject $HotPoolHosts -ErrorAction Stop | Where-Object Name -Like '*ilio*' | Sort-Object Name
	Write-Verbose 'Finished defining Hot Pool vSphere objects'

	Write-Verbose 'Exporting vSphere variables'
	Export-ModuleMember -Variable vCenters, FactoryServers, FactoryVMHosts, FactoryDatastores, HotPoolServers, HotPoolHosts, HotPoolDatastores
	Write-Verbose 'Finished exporting vSphere variables'
}

#endregion vSphere Setup

#region Define IT Systems Engineer Test Machines

#Only define these variables if the Module is loaded as one of the IT Systems Engineers
if ($ADUsername -in $ITSystemsEngineerUsernames)
{
	Write-Verbose 'Defining IT Systems Engineer test machines'

	$ITSystemsEngineerTestMachines = Import-CSV "$ITNetworkShare\AutomatedFactory\Misc\IT Systems Engineer Test Machines.csv"

	if ($BMCEnvironment -in 'PROD', 'DEV', 'QA')
	{
		$All = $ITSystemsEngineerTestMachines | Where-Object BMC_Environment -EQ $BMCEnvironment | ForEach-Object { Get-BCMCommonObject -Name $_.VM -ObjectType Device }
		Write-Verbose "Defining machines by Owner"
		$ITSE1 = $All | Where-Object Name -in ($ITSystemsEngineerTestMachines | Where-Object Owner -EQ 'IT Systems Engineer Name 1').VM
		$ITSE2 = $All | Where-Object Name -In ($ITSystemsEngineerTestMachines | Where-Object Owner -EQ 'IT Systems Engineer Name 2').VM
		$ITSE3 = $All | Where-Object Name -In ($ITSystemsEngineerTestMachines | Where-Object Owner -EQ 'IT Systems Engineer Name 3').VM
		$ITSE4 = $All | Where-Object Name -In ($ITSystemsEngineerTestMachines | Where-Object Owner -EQ 'IT Systems Engineer Name 4').VM
	}
	Write-Verbose 'Finished defining IT Systems Engineer test machines'

	Write-Verbose 'Exporting IT Systems Engineer Test Machine variables'
	Export-ModuleMember -Variable All, ITSE1, ITSE2, ITSE3, ITSE4
	Write-Verbose 'Finished exporting IT Systems Engineer Test Machine variables'
}
#endregion Define IT Systems Engineer Test Machines
