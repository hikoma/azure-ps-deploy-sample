About
========================================

PowerShell で Azure にデプロイするスクリプトのサンプルです。
Azure SDK 2.2 で検証しています。

詳しくは[ブログ](http://hikoma.hateblo.jp/entry/azure-ps-deploy-sample)に記載されています。

Usage
========================================

Deploy.ps1
---------------------------------------

Azure にデプロイするスクリプト。

Deploy.ps1 のパラメータ
* SubscriptionName
    * Add-AzureAccount したサブスクリプション名。空の場合はデフォルトサブスクリプションを利用
* CloudServiceName
    * デプロイ先のクラウドサービス
* CloudServicePackage
    * cspkg ファイルへのパス
* CloudServiceConfiguration
    * cscfg ファイルへのパス
* StorageAccountName
    * デプロイパッケージを配置するストレージアカウント
* BlobContainerName
    * デプロイパッケージを配置する Blob コンテナ
* Location
    * クラウドサービスとストレージアカウントを作成する際のリージョン。デフォルトは "East Asia"

PowerShellDeploySample.msbuild
---------------------------------------

サンプルプロジェクト PowerShellDeploySample をビルドし、Deploy.ps1 を叩いてデプロイする MSBuild ファイル。

PowerShellDeploySample.msbuild のプロパティ
* SubscriptionName
    * Add-AzureAccount したサブスクリプション名。空の場合はデフォルトサブスクリプションを利用
* CloudServiceName
    * デプロイ先のクラウドサービス
* StorageAccountName
    * デプロイパッケージを配置するストレージアカウント
* BlobContainerName
    * デプロイパッケージを配置する Blob コンテナ。空の場合は deploycontainer
* Location
    * クラウドサービスとストレージアカウントを作成する際のリージョン。デフォルトは "East Asia"
