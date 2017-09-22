# brkt-encryptor

A sample bosh release for deploying and running brkt-cli as a service within a bosh deployment

## Steps to build and test it against your local bosh deployment

This assumes that you are running this against the Bracket production environment (mgmt.brkt.com). For other environments, please consider using the `mgmt_url` and `service_domain` arguments.

1. Initialize your bosh deployment:
  `source <directory to environment>/<env_file>.sh`
2. Deploy the brkt-cli release:
  `bosh -d brkt-cli deploy manifest/brkt-cli.yml -n -v aws_access_key_id=<access key> -v aws_secret_access_key=<secret key> -v password=<Bracket Password>`
3. Run the brkt-cli errand:
  `bosh -d brkt-cli run-errand brkt-cli`

To SSH in and troubleshoot any failures:
`bosh -d brkt-cli ssh --gw-private-key=/path/to/pvt/key`

To create a release tarball:
`bosh create-release --tarball=brkt-encryptor.tgz --force`
