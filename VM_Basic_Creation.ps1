# Install-Module AzureRM

# CONEXION A LA CUENTA DE AZURE:
# ------------------------------

Login-AzureRmAccount

# GRUPO DE RECURSOS:
# ------------------

$RGNAME = "RG-MyVM"
$LOCATION = "East US"

Write-Host "Creando Grupo de Recursos..." -ForegroundColor Black -BackgroundColor Yellow

New-AzureRmResourceGroup -Name $RGNAME -Location $LOCATION


# RED VIRTUAL: RED Y SUBRED:
# --------------------------

$SUBNET_1_NAME = "MySubnet_1"
$SUBNET_1_ADDRESS_PREFIX = "10.0.1.0/24"
$VNET_NAME = "MyVNet_1"
$VNET_1_ADDRESS_PREFIX = "10.0.0.0/16"

$SUBNET = New-AzureRmVirtualNetworkSubnetConfig -Name $SUBNET_1_NAME -AddressPrefix $SUBNET_1_ADDRESS_PREFIX

Write-Host "Creando Red Virtual..." -ForegroundColor Black -BackgroundColor Yellow

$VNET = New-AzureRmVirtualNetwork -Name $VNET_NAME -ResourceGroupName = $RGNAME -Location $LOCATION -AddressPrefix $VNET_1_ADDRESS_PREFIX -Subnet $SUBNET

# CUENTA DE ALMACENAMIENTO:
# -------------------------

$SA_NAME = "MySA_2_"
$SA_SKU_NAME = "Standard_LRS"

Write-Host "Creando Cuenta de Almacenamiento para el OS_Disk..." -ForegroundColor Black -BackgroundColor Yellow

$SA = New-AzureRmStorageAccount -Name "$SA_NAME$(Get-Random)" -ResourceGroupName $RGNAME -Location $LOCATION -SkuName $SA_SKU_NAME

$SA_BLOB_ENDPOINT = SA.PrimaryEndpoints.Blob.ToString()

# GRUPO DE DISPONIBILIDAD:
# ------------------------

$AS_NAME = "MyAS"

Write-Host "Creando Grupo de Disponibilidad..." -ForegroundColor Black -BackgroundColor Yellow

$AS = New-AzureRmAvailabilitySet -Name $AS_NAME -ResourceGroupName $RGNAME -Location $LOCATION

# IP y DNS:
# ---------

$PUBLIC_IP_NAME = "MyVM_Public_IP"
$DNS_NAME = "MyVM_DNS_2_"

Write-Host "Creando IP Publica..." -ForegroundColor Black -BackgroundColor Yellow


$PUBLIC_IP = New-AzureRmPublicIpAddress -Name $PUBLIC_IP_NAME -ResourceGroupName $RGNAME -Location $LOCATION -AllocationMethod Dynamic -IdleTimeoutInMinutes 5 -DomainNameLabel "$DNS_NAME$(Get-Random)"

# GRUPO DE SEGURIDAD:
# -------------------

$NSG_RULES = New-AzureRmNetworkSecurityRuleConfig -Name "RDP_3389" -Description "Permitir_el_acceso_remoto" -Direction Inbound -Protocol Tcp -SourcePortRange * -SourceAddressPrefix * -DestinationPortRange "3389" -DestinationAddressPrefix * -Access Allow -Priority 100
$NSG_NAME = "MyNSG_3389"

Write-Host "Creando Grupo de Seguridad..." -ForegroundColor Black -BackgroundColor Yellow

$NSG = New-AzureRmNetworkSecurityGroup -Name $NSG_NAME -ResourceGroupName $RGNAME -Location $LOCATION -SecurityRules $NSG_RULES

# TARJETA DE RED:
# ---------------

$NIC_NAME = "MyNIC"

Write-Host "Creando Tarjeta de Red..." -ForegroundColor Black -BackgroundColor Yellow

$NIC = New-AzureRmNetworkInterface -Name $NIC_NAME -ResourceGroupName $RGNAME -Location $LOCATION -SubnetId $VNET.Subnets[0].Id -PublicIpAddressId $PUBLIC_IP.Id -NetworkSecurityGroupId $NSG.Id

# DEFINICION TAMAÑO Y NOMBRE MAQUINA VIRTUAL:
# -------------------------------------------

$VM_SIZE = "Standard_B1s"
$VM_NAME = "MyVM"

# CONFIGURACION DE LA MAQUINA VIRTUAL:
# ------------------------------------

Write-Host "Creando Configuración de la Maquina Virtual..." -ForegroundColor Black -BackgroundColor Yellow

$VM = New-AzureRmVMConfig -VMName $VM_NAME -VMSize $VM_SIZE -AvailabilitySetId $AS.Id
$VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NIC.Id

Write-Host "Esperando Credenciales para la Maquia Virtual..." -ForegroundColor Black -BackgroundColor Yellow

$CREDENCIALES = Get-Credential # usuario / P4$$w0rd1234

# DEFINICION DEL SISTEMA OPERATIVO Y SU IMAGEN:
# ---------------------------------------------

Write-Host "Creando Configuración del Sistema Operativo..." -ForegroundColor Black -BackgroundColor Yellow

Set-AzureRmVMOperatingSystem -Windows -ComputerName $VM_NAME -Credential $CREDENCIALES -ProvisionVMAgent -VM $VM
# Incluye el agente de Azure para poder obtener analiticas

$PUBLISHER_NAME = "MicrosoftWindowsServer"
$OFFER_NAME = "WindowsServer"
$SKU_NAME = "2016-Datacenter-Server-Core"

Set-AzureRmVMSourceImage -PublisherName $PUBLISHER_NAME -Offer $OFFER_NAME -Skus $SKU_NAME -Version "latest" -VM $VM

# DISCO DEL SISTEMA:
#-------------------

$OS_DISK_NAME = 'OS_Disk_' + $VM_NAME
$OS_DISK_URI = $SA_BLOB_ENDPOINT + "VHDs/" + $OS_DISK_NAME + ".vhd"

Write-Host "Creando Disco del Sistema Operativo..." -ForegroundColor Black -BackgroundColor Yellow

Set-AzureRmVMOSDisk -Name $OS_DISK_NAME -VhdUri $OS_DISK_URI -CreateOption fromImage -VM $VM

# PROVISIONAR LA MAQUINA:
#------------------------

Write-Host "Desplegando la Maquina Virtual..." -ForegroundColor Black -BackgroundColor Yellow
Write-Host "Esta operacion puede tardar varios minutos!" -ForegroundColor Black -BackgroundColor Yellow

New-AzureRmVM -ResourceGroupName $RGNAME -Location $LOCATION -VM $VM

Write-Host "Listo!" -ForegroundColor Black -BackgroundColor Yellow
Write-Host "Dirigite al portal de Azure y comprueba el despliegue!" -ForegroundColor Black -BackgroundColor Yellow