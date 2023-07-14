# sign-here

A straightforward tool that enables the creation of Provisioning Profiles and Certificates for deploying Apple based software. This tool
allows users to automate the creation of certificates and provisioning profiles in a simple to use API.

## Prerequisites

* Bazel (Tested with Bazel 6.0)
* OpenSSL (tested with LibreSSL 3.3.6)

## Limitations

sign-here cannot be used to generate certificates for Enterprise based accounts. This is a [known limitation
of the iTunes Connect API](https://developer.apple.com/forums/thread/117282).

## Getting Started

To start using `sign-here` immediately, simply clone down the repo and run the tool:

```terminal
git clone https://github.com/Tinder/sign-here.git
cd sign-here
bazel run //Sources/SignHereTool:sign-here
```

Actions such as `create-keychain` and `delete-keychain` do not require iTunes Connect API access thus
they do not require authentication information. For commands such as `create-provisioning-profile` and
`delete-provisioning-profile` iTunes Connect API access will be needed, you will need to follow the guides
for [generating tokens](https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests) and
[generating API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)
for the necessary credentials.

## CLI Interface

### create-keychain

```terminal
sign-here create-keychain --help
OVERVIEW: Use this command to create a keychain to populate with signing information in the `create-provisioning-profile` command

This command sets up a keychain that is ready to use for signing actions. This command is not required and you may setup your own keychain
for usage in the `create-provisioning-profile` command.

USAGE: sign-here create-keychain --keychain-name <keychain-name> --keychain-password <keychain-password>

OPTIONS:
  --keychain-name <keychain-name>
                          Name of the keychain to be created
  --keychain-password <keychain-password>
                          Password for the keychain to be created
  -h, --help              Show help information.

```

### delete-keychain

```terminal
sign-here delete-keychain --help
OVERVIEW: Use this command to delete a keychain from the system

This command can be used to delete a keychain from the system and restore sensible defaults for the keychain search list post deletion (i.e. setting login.keychain in the default search list)

USAGE: sign-here delete-keychain --keychain-name <keychain-name>

OPTIONS:
  --keychain-name <keychain-name>
                          Name of the keychain to be deleted
  -h, --help              Show help information.
```

### create-provisioning-profile

```terminal
sign-here create-provisioning-profile --help
OVERVIEW: Use this command to create a ready to use provisioning profile.

Use this command to create and save a mobile provisioning profile to a specified location. This command
takes care of all necessary signing work and iTunes Connect API calls to get a ready to use
mobile provisioning profile.

The output of this command is the iTunes Connect API ID of the created provisioning profile. This can
be used with the `delete-provisioning-profile` command to delete it if desired.

USAGE: sign-here create-provisioning-profile <options>

OPTIONS:
  --key-identifier <key-identifier>
                          The key identifier of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --issuer-id <issuer-id> The issuer id of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --private-key-path <private-key-path>
                          The path to a private key to use for generating PEM and P12 files. This key will be attached to any generated certificates or profiles
  --itunes-connect-key-path <itunes-connect-key-path>
                          The path to the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --keychain-name <keychain-name>
                          The name of the keychain to use to store fetched identities
  --keychain-password <keychain-password>
                          The password of the keychain specified by --keychain-name
  --bundle-identifier <bundle-identifier>
                          The bundle identifier of the app for which you want to generate a provisioning profile for
  --profile-type <profile-type>
                          The profile type which you wish to create (https://developer.apple.com/documentation/appstoreconnectapi/profilecreaterequest/data/attributes)
  --certificate-type <certificate-type>
                          The certificate type which you wish to create (https://developer.apple.com/documentation/appstoreconnectapi/certificatetype)
  --output-path <output-path>
                          Where to save the created provisioning profile
  --openssl-path <openssl-path>
                          Path to the openssl executable, this is used to generate CSR signing artifacts that are required when creating certificates
  --intermediary-apple-certificates <intermediary-apple-certificates>
                          Intermediary Apple Certificates that should also be added to the keychain (https://www.apple.com/certificateauthority/)
  --certificate-signing-request-subject <certificate-signing-request-subject>
                          Subject for the Certificate Signing Request when creating certificates.

                          OpenSSL documentation for this flag (https://www.openssl.org/docs/manmaster/man1/openssl-req.html):

                          Sets subject name for new request or supersedes the subject name when processing a certificate request.

                          The arg must be formatted as '/type0=value0/type1=value1/type2=....'. Special characters may be escaped by '\' (backslash), whitespace is retained. Empty values are
                          permitted, but the corresponding type will not be included in the request. Giving a single '/' will lead to an empty sequence of RDNs (a NULL-DN). Multi-valued RDNs can be
                          formed by placing a '+' character instead of a '/' between the AttributeValueAssertions (AVAs) that specify the members of the set. Example:

                          /DC=org/DC=OpenSSL/DC=users/UID=123456+CN=JohnDoe
  -h, --help              Show help information.
```

### delete-provisioning-profile

```terminal
sign-here delete-provisioning-profile --help
OVERVIEW: Use this command to delete a provisioning profile using its iTunes Connect API ID

This command can be used in conjunction with the `create-provisioning-profile` command to create and delete provisioning profiles.

USAGE: sign-here delete-provisioning-profile --provisioning-profile-id <provisioning-profile-id> --key-identifier <key-identifier> --issuer-id <issuer-id> --itunes-connect-key-path <itunes-connect-key-path>

OPTIONS:
  --provisioning-profile-id <provisioning-profile-id>
                          The iTunes Connect API ID of the provisioning profile to delete (https://developer.apple.com/documentation/appstoreconnectapi/profile)
  --key-identifier <key-identifier>
                          The key identifier of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --issuer-id <issuer-id> The issuer id of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --itunes-connect-key-path <itunes-connect-key-path>
                          The path to the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  -h, --help              Show help information.
```

### register-device 

```terminal
sign-here register-device --help
OVERVIEW: Use this command to register a device using its udid

USAGE: sign-here register-device --platform <platform> --name <name> --udid <udid> --key-identifier <key-identifier> --issuer-id <issuer-id> --itunes-connect-key-path <itunes-connect-key-path>

OPTIONS: 
  --platform <platform>
                          The operating system intended for the bundle: IOS or MAC_OS (https://developer.apple.com/documentation/appstoreconnectapi/bundleidplatform)"
  --name <name>
                          Your Name's Device (example: Johns iPhone 13)
  --udid <udid>
                          The device's UDID                                  
  --key-identifier <key-identifier>
                          The key identifier of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --issuer-id <issuer-id> The issuer id of the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  --itunes-connect-key-path <itunes-connect-key-path>
                          The path to the private key (https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
  -h, --help              Show help information.
```

## Installing

### Download pre-built binary

```terminal
curl -L https://github.com/Tinder/sign-here/releases/download/0.0.1/sign-here -o sign-here
chmod +x sign-here
./sign-here
```

### Build from source

WORKSPACE

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

com_github_tinder_sign_here_version = "0.0.1"
http_archive(
    name = "com_github_tinder_sign_here",
    url = "https://github.com/Tinder/sign-here/archive/refs/tags/%s.tar.gz" % com_github_tinder_sign_here_version,
    type = "tar.gz",
    sha256 = "b9a614f2221b484b9d615259afac3d4c80c4ce97558b30d9e7a9b53029e14290",
    strip_prefix = "sign-here-%s" % com_github_tinder_sign_here_version,
)

load(
    "@com_github_tinder_sign_here//:repositories.bzl",
    "sign_here_dependencies",
)

sign_here_dependencies()
```

### Running the tests

```terminal
bazel test //Tests/...
```

### License

---

```text
Copyright (c) 2023, Match Group, LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Match Group, LLC nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL MATCH GROUP, LLC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
