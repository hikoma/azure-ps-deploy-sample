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

# サブスクリプションを変更する
if ($SubscriptionName) {
    Select-AzureSubscription -SubscriptionName $SubscriptionName
}

# CurrentStorageAccountName は使わないので無効な値を入れておくハック
Get-AzureSubscription -Current | Set-AzureSubscription -CurrentStorageAccountName _

function Start-StagingDeploy {
    [CmdletBinding()]
    Param ()

    Process {
        # ストレージアカウントが存在しない場合は新規作成する
        try {
            Get-AzureStorageAccount -StorageAccountName $StorageAccountName | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
            Write-Host ('ストレージアカウント {0} を作成中' -f $StorageAccountName)
            New-AzureStorageAccount -StorageAccountName $StorageAccountName -Location $Location
        }

        # ストレージの接続コンテキストを作成
        $storageKey = Get-AzureStorageKey -StorageAccountName $StorageAccountName
        $storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName `
                                                  -StorageAccountKey $storageKey.Primary

        # Blob コンテナが存在しない場合は新規作成する
        try {
            Get-AzureStorageContainer -Context $storageContext -Container $BlobContainerName | Out-Null
        } catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException] {
            Write-Host ('Blob コンテナ {0} を作成中' -f $BlobContainerName)
            New-AzureStorageContainer -Context $storageContext -Container $BlobContainerName
        }

        # cspkg と cscfg をアップロード
        Write-Host ('{0} をアップロード中' -f $CloudServicePackage)
        $cspkg = Set-AzureStorageBlobContent -Context $storageContext -Container $BlobContainerName `
                                             -File $CloudServicePackage -Force

        Write-Host ('{0} をアップロード中' -f $CloudServiceConfiguration)
        $cscfg = Set-AzureStorageBlobContent -Context $storageContext -Container $BlobContainerName `
                                             -File $CloudServiceConfiguration -Force

        # クラウドサービスが存在しない場合は新規作成する
        try {
            Get-AzureService -ServiceName $CloudServiceName | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
            Write-Host ('クラウドサービス {0} を作成中' -f $CloudServiceName)
            New-AzureService -ServiceName $CloudServiceName -Location $Location
        }

        # 既にステージング環境にデプロイされている場合は削除する
        try {
            Remove-AzureDeployment -ServiceName $CloudServiceName -Slot Staging -Force | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
        }

        # ステージング環境にデプロイする
        Write-Host 'ステージング環境にデプロイ中'
        New-AzureDeployment -ServiceName $CloudServiceName -Slot Staging `
                            -Package $cspkg.ICloudBlob.Uri.AbsoluteUri `
                            -Configuration $CloudServiceConfiguration | Out-Null

        # インスタンスが起動するまで待つ
        Write-Host 'インスタンスの起動中'
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
                throw 'インスタンスの起動に失敗しました：' + ($errorList | Format-List | Out-String)
            }

            Start-Sleep -Seconds 10
        }
        Write-Host 'インスタンスの起動が完了しました'
        Write-Host ('{0} にアクセスして動作確認をしてください' -f $deployment.Url.AbsoluteUri)
    }
}

function Publish-StagingDeploy {
    [CmdletBinding()]
    Param ()

    Process {
        # ステージング環境と運用環境を入れ替える
        Write-Host 'ステージング環境と運用環境をスワップ中'
        Move-AzureDeployment -ServiceName $CloudServiceName | Out-Null

        # 運用環境の URL を表示
        $deployment = Get-AzureDeployment -ServiceName $CloudServiceName -Slot Production
        Write-Host ('{0} に公開されました' -f $deployment.Url.AbsoluteUri)

        # ステージング環境（以前の運用環境）を削除する
        Write-Host 'ステージング環境を削除中'
        try {
            Remove-AzureDeployment -ServiceName $CloudServiceName -Slot Staging -Force | Out-Null
        } catch {
            if ($_.Exception.ErrorCode -ne 'ResourceNotFound') {
                throw $_.Exception
            }
        }

        Write-Host 'デプロイ終了！'
    }
}

Start-StagingDeploy

# TODO: ステージング環境で動作確認を行う
Start-Sleep -Seconds 60

Publish-StagingDeploy
