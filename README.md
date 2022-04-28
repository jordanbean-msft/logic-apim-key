# logic-apim-key

This repo shows an example of how to use [Logic Apps]() to regenerate the primary key in an [Azure API Management]() instance. APIM doesn't provide a native way to rotate keys on a regular basis. Rotating API subscription keys is a good security practice since they are just a long password and should not be considered a secure method of authorizing API calls.

This repo also has an example of how to use [Logic Apps]() in combination with an [Azure Function]() and an [Azure Key Vault]() to generate custom API subscription keys, store them in Key Vault and then set the key in APIM.

This repo also shows you how to use [stateful Logic Apps]() to notify subscription owners that their API subscription keys are about to expire and ask them to approve or deny being the owner.

This repo also shows you how to build a simple web app that has a user interactively sign-in and then call an API protected via the OAuth2 [validate-jwt]() token policy. There is also an example of a daemon (background process with no user interactively signed in) accessing this same API.

In both cases, the APIM & backing API don't know or care about how the calling application authenticated & got an access token (either via [Authorization Code Flow]() or [Client Credential Flow]()). The same `validate-jwt` policy can be used for both.

## Pre-requisites

- Azure subscription & resource group
- [Azure CLI]()
- [dotnet CLI]()
- [.NET 6]()
- [Azure Function CLI]()
- [PowerShell]()
- [Logic Apps Visual Studio Code Extension]()

## Deployment

1.  Modify the `infra/env/dev.parameters.json` file as needed for your environment.

1.  Execute the following Azure CLI from the root directory of the repo (substituting your values as needed)

    ```shell
    az deployment group create -g rg-logic-apim-key-ussc-demo --template-file ./infra/main.bicep --parameter ./infra/env/dev.parameters.json --parameter publisherName=dwight publisherEmail=dwight.k.schrute@dunder-mifflin.com
    ```

1.  Deploy the Azure Function code (substituting your Azure Function name as needed).

    ```shell
    cd ./web/generate-new-subscription-key-function
    func azure functionapp publish func-logicApimKey-ussc-demo
    ```

1.  Zip up & deploy the Logic App workflows (substituting your values as needed). Change `Compress-Archive` if needed on Linux.

    ```shell
    Compress-Archive -Path ./logic-app/* -DestinationPath ./logic-app.zip -Update

    az logicapp deployment source config-zip --name logic-logicApimKey-ussc-demo --resource-group rg-logic-apim-key-ussc-demo --subscription <subscription-name> --src ./logic-app.zip
    ```

### Initialize Logic App Office 365 connections

You will need to open each Logic App workflow in the Azure portal and initialize it using your credentials to send email.

1.  Open the `Logic App` in your Resource Group.

1.  Click on the `Workflows` blade

1.  Select the `notify-subscription-owner` workflow

1.  Click on the `Designer` blade

1.  Select the `Send an email` command of the `Office 365 Outlook` action.

1.  Click on the `Change connection` link and sign-in to use your credentials to send emails.

1.  Repeat these steps for the other `Send an email` actions in this workflow & the other 2 workflows everywhere the `Send email` command is used.

### Create App registrations in Azure Active Directory

#### Create App Registration for backend API

1.  Take a note of the `Application Id` that is generated. You will need this value to correctly set up the APIM `validate-jwt` policy to look for the correct `audience`.

#### Create App Registration for client API

#### Create App Registration for client web app

### Validate-Jwt APIM policy

1.  Login to your APIM instance.

1.  Navigate to the `API` blade & select the `Echo API`

1.  Click on `All operations`

1.  Click on the `Edit` button on the `Inbound policies`

1.  Add the following XML policy (and customize the values as needed).You will need to customize the following values.

    - `audience` - This will be the `Application Id` from the `API permissions` blade in AAD for the API app registration you created. This is the value that needs to be check in each access token to ensure it is for this API.
    - `issuer` - This is the AAD tenant that issued the token.

    ```xml

    ```

## How to use Logic Apps to regenerate API subscription keys using native APIM capabilities

The Logic App will go through the following steps to regenerate the API subscription primary key when it is within 30 days of expiring and then notifying the owner.

1.  It will first query the APIM to see what API subscriptions are expiring in the next 30 days.

1.  It will then loop over each one and:

    1.  Regenerate the primary key using the native API for APIM.

    1.  Get the subscription owner ID & product name.

    1.  Send an email to the subscription owner notifying them of the change.

You can right-click on the `logic-app/rotate-subscription-key/workflow.json` file and select `Open in Designer` to see the GUI tool for building Logic Apps.

## How to use Logic Apps to regenerate API subscription keys via an Azure Function, store that new key in Azure Key Vault & set the new key in APIM

The Logic App will go through the following steps to generate a new API subscription primary key when it is within 30 days of expiring, saving it to Key Vault & then setting it in APIM, and then notifying the owner.

1.  It will first query the APIM to see what API subscriptions are expiring in the next 30 days.

1.  It will then loop over each one and:

    1.  Call the Azure Function to generate a new primary key

    1.  Save this new key to Azure Key Vault.

    1.  Set the the primary key using the native API for APIM.

    1.  Get the subscription owner ID & product name.

    1.  Send an email to the subscription owner notifying them of the change.

You can right-click on the `logic-app/set-subscription-key/workflow.json` file and select `Open in Designer` to see the GUI tool for building Logic Apps.

## How to notify API subscription owners and get their approval or denial

The Logic App will go through the following steps to notify the API subscription owner of the API subscription key expiring and wait on their response (using stateful Logic Apps).

1.  It will first query the APIM to see what API subscriptions are expiring in the next 30 days.

1.  It will then loop over each one and:

    1.  Get the subscription owner ID & product name.

    1.  Send an email to the subscription owner notifying them of the expiration and asking them to `Approve` or `Deny`.

    1.  The Logic App will then wait on their response.

    1.  Based upon the response, it will send a follow-up email with an `Approval` or `Denial` email.

You can right-click on the `logic-app/notify-subscription-owner/workflow.json` file and select `Open in Designer` to see the GUI tool for building Logic Apps.
