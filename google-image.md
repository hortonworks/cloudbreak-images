We're using [Terraform](terraform.io) to export the Google image into a bucket.

## Install Terraform

```
brew cask install terraform
```

## Configure credentials

[Google Cloud Platform credentials](https://console.developers.google.com/project/siq-haas/apiui/credential)

* `~/.config/gcloud/account.json`: Service Account > Generate new JSON key 
* `~/.config/gcloud/client_secret.json`: Client ID for native application > Download JSON

Checking the credentials 

```
terraform plan -var owner=$USER -var credential_dir=~/.config/gcloud/
```

## Upload ssh public key

This SSH key is used to remote exec the provisioning script

Upload the key [GCE Compute engine > Metadata > SSH tab](https://console.developers.google.com/project/siq-haas/compute/metadata/sshKeys)

## Export the image

```
terraform apply -var owner=$USER -var credential_dir=~/.config/gcloud/ -var ssh_key_file=~/.ssh/id_rsa
```