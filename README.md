About
========================================

PowerShell �� Azure �Ƀf�v���C����X�N���v�g�̃T���v���ł��B
Azure SDK 2.2 �Ō��؂��Ă��܂��B

�ڂ�����[�u���O](http://hikoma.hateblo.jp/entry/azure-ps-deploy-sample)�ɋL�ڂ���Ă��܂��B

Usage
========================================

Deploy.ps1
---------------------------------------

Azure �Ƀf�v���C����X�N���v�g�B

Deploy.ps1 �̃p�����[�^
* SubscriptionName
    * Add-AzureAccount �����T�u�X�N���v�V�������B��̏ꍇ�̓f�t�H���g�T�u�X�N���v�V�����𗘗p
* CloudServiceName
    * �f�v���C��̃N���E�h�T�[�r�X
* CloudServicePackage
    * cspkg �t�@�C���ւ̃p�X
* CloudServiceConfiguration
    * cscfg �t�@�C���ւ̃p�X
* StorageAccountName
    * �f�v���C�p�b�P�[�W��z�u����X�g���[�W�A�J�E���g
* BlobContainerName
    * �f�v���C�p�b�P�[�W��z�u���� Blob �R���e�i
* Location
    * �N���E�h�T�[�r�X�ƃX�g���[�W�A�J�E���g���쐬����ۂ̃��[�W�����B�f�t�H���g�� "East Asia"

PowerShellDeploySample.msbuild
---------------------------------------

�T���v���v���W�F�N�g PowerShellDeploySample ���r���h���ADeploy.ps1 ��@���ăf�v���C���� MSBuild �t�@�C���B

PowerShellDeploySample.msbuild �̃v���p�e�B
* SubscriptionName
    * Add-AzureAccount �����T�u�X�N���v�V�������B��̏ꍇ�̓f�t�H���g�T�u�X�N���v�V�����𗘗p
* CloudServiceName
    * �f�v���C��̃N���E�h�T�[�r�X
* StorageAccountName
    * �f�v���C�p�b�P�[�W��z�u����X�g���[�W�A�J�E���g
* BlobContainerName
    * �f�v���C�p�b�P�[�W��z�u���� Blob �R���e�i�B��̏ꍇ�� deploycontainer
* Location
    * �N���E�h�T�[�r�X�ƃX�g���[�W�A�J�E���g���쐬����ۂ̃��[�W�����B�f�t�H���g�� "East Asia"
