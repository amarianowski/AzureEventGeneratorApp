New-AzResourceGroup `
    -Name 'event-generator-app-rg' `
    -Location 'uksouth'

New-AzResourceGroupDeployment `
    -ResourceGroupName 'event-generator-app-rg' `
    -TemplateFile "$PSScriptRoot/main.bicep" `
    -Verbose
