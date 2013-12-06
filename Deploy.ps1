#Requires -Version 3.0
#Requires -Modules Azure
Param (
    [Parameter()]
    [string] $SubscriptionName,

    [Parameter(Mandatory=$True)]
    [string] $CloudServiceName,

    [Parameter(Mandatory=$True)]
    [string] $CloudServicePackage,

    [Parameter(Mandatory=$True)]
    [string] $CloudServiceConfiguration,

    [Parameter(Mandatory=$True)]
    [string] $StorageAccountName,

    [Parameter(Mandatory=$True)]
    [string] $BlobContainerName,

    [Parameter()]
    [string] $Location = 'East Asia'
)

$ErrorActionPreference = 'Stop'

# �T�u�X�N���v�V������ύX����
if ($SubscriptionName) {
    Select-AzureSubscription -SubscriptionName $SubscriptionName
}

# CurrentStorageAccountName �͎g��Ȃ��̂Ŗ����Ȓl�����Ă����n�b�N
Get-AzureSubscription -Current | Set-AzureSubscription -CurrentStorageAccountName _

function Start-StagingDeploy {
    [CmdletBinding()]
    Param ()

    Process {
        # �X�g���[�W�A�J�E���g�����݂��Ȃ��ꍇ�͐V�K�쐬����
        try {
            Get-AzureStorageAccount -StorageAccountName $StorageAccountName | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
            Write-Host ('�X�g���[�W�A�J�E���g {0} ���쐬��' -f $StorageAccountName)
            New-AzureStorageAccount -StorageAccountName $StorageAccountName -Location $Location
        }

        # �X�g���[�W�̐ڑ��R���e�L�X�g���쐬
        $storageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
        $storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName `
                                                  -StorageAccountKey $storageKey.Primary

        # Blob �R���e�i�����݂��Ȃ��ꍇ�͐V�K�쐬����
        try {
            Get-AzureStorageContainer -Context $storageContext -Container $BlobContainerName | Out-Null
        } catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException] {
            Write-Host ('Blob �R���e�i {0} ���쐬��' -f $BlobContainerName)
            New-AzureStorageContainer -Context $storageContext -Container $BlobContainerName
        }

        # cspkg �� cscfg ���A�b�v���[�h
        Write-Host ('{0} ���A�b�v���[�h��' -f $CloudServicePackage)
        $cspkg = Set-AzureStorageBlobContent -Context $storageContext -Container $BlobContainerName `
                                             -File $CloudServicePackage -Force

        Write-Host ('{0} ���A�b�v���[�h��' -f $CloudServiceConfiguration)
        $cscfg = Set-AzureStorageBlobContent -Context $storageContext -Container $BlobContainerName `
                                             -File $CloudServiceConfiguration -Force

        # �N���E�h�T�[�r�X�����݂��Ȃ��ꍇ�͐V�K�쐬����
        try {
            Get-AzureService -ServiceName $CloudServiceName | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
            Write-Host ('�N���E�h�T�[�r�X {0} ���쐬��' -f $CloudServiceName)
            New-AzureService -ServiceName $CloudServiceName -Location $Location
        }

        # ���ɃX�e�[�W���O���Ƀf�v���C����Ă���ꍇ�͍폜����
        try {
            Remove-AzureDeployment -ServiceName $CloudServiceName -Slot Staging -Force | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
        }

        # �X�e�[�W���O���Ƀf�v���C����
        Write-Host '�X�e�[�W���O���Ƀf�v���C��'
        New-AzureDeployment -ServiceName $CloudServiceName -Slot Staging `
                            -Package $cspkg.ICloudBlob.Uri.AbsoluteUri `
                            -Configuration $CloudServiceConfiguration | Out-Null

        # �C���X�^���X���N������܂ő҂�
        Write-Host '�C���X�^���X�̋N����'
        while ($True) {
            $deployment = Get-AzureDeployment -ServiceName $CloudServiceName -Slot Staging
            if ($deployment.Status -ne 'Running') {
                continue
            }

            $notReadyList = $deployment.RoleInstanceList | Where-Object InstanceStatus -ne 'ReadyRole'
            if (!$notReadyList) {
                break
            }

            $errorStatusList = @('RestartingRole';'CyclingRole';'FailedStartingRole';'FailedStartingVM';'UnresponsiveRole')
            $errorList = $notReadyList | Where-Object InstanceStatus -in $errorStatusList
            if ($errorList) {
                throw '�C���X�^���X�̋N���Ɏ��s���܂����F' + ($errorList | Format-List | Out-String)
            }

            Start-Sleep -Seconds 10
        }
        Write-Host '�C���X�^���X�̋N�����������܂���'
        Write-Host ('{0} �ɃA�N�Z�X���ē���m�F�����Ă�������' -f $deployment.Url.AbsoluteUri)
    }
}

function Publish-StagingDeploy {
    [CmdletBinding()]
    Param ()

    Process {
        # �X�e�[�W���O���Ɖ^�p�������ւ���
        Write-Host '�X�e�[�W���O���Ɖ^�p�����X���b�v��'
        Move-AzureDeployment -ServiceName $CloudServiceName | Out-Null

        # �^�p���� URL ��\��
        $deployment = Get-AzureDeployment -ServiceName $CloudServiceName -Slot Production
        Write-Host ('{0} �Ɍ��J����܂���' -f $deployment.Url.AbsoluteUri)

        # �X�e�[�W���O���i�ȑO�̉^�p���j���폜����
        Write-Host '�X�e�[�W���O�����폜��'
        try {
            Remove-AzureDeployment -ServiceName $CloudServiceName -Slot Staging -Force | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
        }

        Write-Host '�f�v���C�I���I'
    }
}

Start-StagingDeploy

# TODO: �X�e�[�W���O���œ���m�F���s��
Start-Sleep -Seconds 60

Publish-StagingDeploy
