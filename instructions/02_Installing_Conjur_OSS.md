# Workshop guide: __Step 1__ Installing Conjur OSS



## Pre-Reqs

- A 8Gb of RAM CentOS 7 Machine with 4 CPUs
- Docker installed
- Docker Compose installed
- Disable SELinux

## Install the Infra

**1. Pull the kickstarter from Github**

    git clone https://github.com/cyberark/conjur-quickstart.git  
      or  
    wget https://github.com/cyberark/conjur-quickstart/archive/refs/heads/main.zip && unzip main.zip


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
**6. Connect to conjur server with the CLI and the admin account**
```
    docker-compose exec client conjur init -u conjur -a demo
```

## Defining policies

**1. Login to Conjur using the CLI**
```Bash
docker-compose exec client conjur authn login -u admin
the password is in the admin_data file generated earler on
```
**2. Examine the conf/policy/BotApp.yml file** and load it
```Bash
docker-compose exec client conjur policy load root policy/BotApp.yml > my_app_data
```
**3. Examin the my_app_data file and logout**
```Bash
docker-compose exec client conjur authn logout
```
## Store secrets
 
**1. Login as user Dave**
```
docker-compose exec client conjur authn login -u Dave@BotApp
Use the API key as a password from the my_app_data file for the user Dave
```

**2. Generate a Secret**
```Bash
secretVal=$(openssl rand -hex 12 | tr -d '\r\n')
This generates a 12-hex-character value.
```

**3. Store the secret**
```Bash
docker-compose exec client conjur variable values add BotApp/secretVar ${secretVal}
```

**4. Verify you can retrieve the secret from a dummy app**
```Bash
docker exec -it bot_app bash
curl -d "<BotApp API Key>" -k https://proxy/authn/demo/host%2FBotApp%2FmyDemoApp/authenticate > /tmp/conjur_token
/tmp/program.sh
```

