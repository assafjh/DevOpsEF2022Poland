# Workshop guide: __Step 2__ Installing Conjur OSS

At this exercise we will install Conjur OSS (Open Source Software).
All work in this guide will be under the **conjur-oss** folder of this repo.
 
## Pre-Reqs

 1. Tools from step #1 installed.

## Install the Infra
### Configure SAN (Subject Alternative Names)
 At this exercise, Conjur OSS will use a self signed certificate, we will need to configure SAN:
1. Navigate to the folder: ```conf/tls```
2. Append to section **[ alt_names ]** (line #36) in file ```tls.conf```  your relevant DNS and IP.

#### Example
```conf
[ alt_names ]
DNS.1 = localhost
DNS.2 = proxy
DNS.3 = internalname.compute.amazonaws.com
DNS.4 = externalname.compute.internal
IP.1 = 127.0.0.1
IP.2 = 35.35.35.35
IP.3 = 172.1.0.0
```

**2. Pull the images**

```Bash
cd conjur-quickstart-main ; docker-compose pull
```

**3. Generate Masterkey: This key will be used to encrypt the Database.**

```Bash
docker-compose run --no-deps --rm conjur data-key generate > data_key
export CONJUR_DATA_KEY="$(< data_key)"
```

**4. Startup the servers**

```Bash
docker-compose up -d
```

**5. Create admin account**

```Bash
docker-compose exec conjur conjurctl account create demo > admin_data
```

**6. Install Conjur CLI**
- We will install the CLI using the RHEL8 binary. 
- For additional ways of installing the Conjur CLI, please refer to: [Conjur Docs - CLI](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/latest/en/Content/Developer/CLI/cli-setup.htm)
1. Download the binary to your VM:
	```bash
	wget https://github.com/cyberark/cyberark-conjur-cli/releases/download/v7.1.0/conjur-cli-rhel-8.tar.gz
	```
2. Extract the downloaded file.
	```bash
	tar -xvf conjur-cli-rhel-8.tar.gz
	```
3. Give execute permissions to the conjur executable:
	```bash
	chmod +x conjur
	```
4. Move the conjur executable to your machine's /usr/local/bin directory:
	```bash
	sudo mv conjur /usr/local/bin
	```
5. To verify the Conjur CLI version, run `conjur --version`


**6. Connect to Conjur server with the CLI and the admin account**

```bash
conjur init -s -u https://$(hostname -f):8433 -a demo
```
Output example:
```bash
Using self-signed certificates is not recommended and could lead to exposure of sensitive data.
 Continue? yes/no (Default: no): yes

The Conjur server's certificate SHA-1 fingerprint is:
8A:74:99:17:1F:B9:E5:D0:11:88:B6:02:AA:C5:C5:52:6A:33:77:8F

To verify this certificate, we recommend running the following command on the Conjur server:
openssl x509 -fingerprint -noout -in ~conjur/etc/ssl/conjur.pem

Trust this certificate? yes/no (Default: no): yes
Certificate written to /home/ec2-user/conjur-server.pem

Configuration written to /home/ec2-user/.conjurrc

Successfully initialized the Conjur CLI
To start using the Conjur CLI, log in to the Conjur server by running `conjur login`
```

## Defining policies

**1. Login to Conjur using the CLI**
- The admin user password is in the admin_data file generated earlier on
```Bash
conjur login -i admin
```

**2. Examine the policy/BotApp.yml file** and load it

```Bash
conjur policy update -b root -f policy/BotApp.yml > my_app_data
```

**3. Examin the my_app_data file and logout**

```Bash
conjur logout
```

## Store secrets

**1. Login as user Dave**
- Use the API key as a password from the my_app_data file for the user Dave
```bash
conjur login -i Dave@BotApp
```

**2. Generate a Secret**
- The below generates a 12-hex-character value.
```bash
secretVal=$(openssl rand -hex 12 | tr -d '\r\n')
```

**3. Store the secret**
```bash
conjur variable set -i BotApp/secretVar -v "${secretVal}"
```

**4. Verify you can retrieve the secret from a dummy app**
```bash
curl -d "<BotApp API Key>" -k https://$(hostname -f)/authn/demo/host%2FBotApp%2FmyDemoApp/authenticate > ./conjur_token
./program.sh
```