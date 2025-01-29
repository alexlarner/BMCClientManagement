# BMCClientManagement

Creates PowerShell API wrapper around the [BMC Client Management 12.8 API](https://docs.bmc.com/docs/bcm128/files/en/821035629/821035631/1/1497960499812/BMC_Client_Management_WebAPI.pdf).

*[BMC Client Management](https://www.bmc.com/it-solutions/bmc-helix-client-management.html) is an endpoint management platform and an alternative to Config Manager/SCCM.*

## Usage

I used this to automate most of our software packaging & deployment and as the basis for the my "Automated Factory".

The "Automated Factory" automated the creation of all new user VMs in the company and the imaging/reimaging process of all laptops & desktops in the company, in a company that exclusively used VMs for all their work:

- It created 3 different builds (Base, Operations, and Sales) of VMs and always kept a specified number of each of them in stock in the “Factory” & “Parking Lot” areas
    - Applications in each of the Build types, number of VMs to always keep in stock, and VM stock count refill triggers were defined by CSVs, and could be changed by just adding/changing/deleting a row
- There were two different areas for VMs:
    - A “Factory” where “Base” build type VMs were created, built up to one of the other “trim” build types (Operations or Sales) as needed, and moved to the “Parking Lot” to refill as needed
    - A “Parking Lot” where VMs were ready for other IT teams to move off and assign to the new user
- It consisted of 4 different scripts (Build Base VM, Convert Base VM into other builds, Refill Parking Lot from Factory, and Factory Status) that ran independently and could keep running if the other scripts were not functioning
    - Those scripts utilized this API and VMware’s PowerShell API for vSphere ([PowerCLI](https://developer.broadcom.com/powercli))
- VMs were balanced between datacenters, hosts, and datastores
- It wrote logs documenting the status of each machine through the process
- It emailed regular status updates of the VM build type counts & statuses to management
- It had built over 3,000 VMs as of 2021
