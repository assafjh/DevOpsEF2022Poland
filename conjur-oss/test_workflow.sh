#!/bin/bash

set -euo pipefail

function announce() {
  echo "++++++++++++++++++++++++++++++++++++++"
  echo ""
  echo "$@"
  echo ""
  echo "++++++++++++++++++++++++++++++++++++++"
}

function cleanup() {
  exit_status=$?
  exit_command=$BASH_COMMAND

  # exit on error should collapse the docker-compose system
  # otherwise, leaving the system running
  if [[ exit_status -ne 0 ]]; then
    echo
    echo "WORKFLOW FAILED."

    echo
    echo "Cleanup"
    rm -f data_key admin_data my_app_data my_api_keys
    echo "Stopping and Removing Container System"
    docker-compose down
  fi

  exit $exit_status
}
trap cleanup EXIT ABRT QUIT

if [[ -n "$(docker-compose ps -q)" ]]; then
  echo "Conjur Quickstart OSS already built!"
  echo "Testing Quickstart workflow requires a fresh build."
  echo "Use 'docker-compose down' to remove current Quickstart build."
  exit 0
fi

announce "UNIT 1. Set Up a Conjur OSS Environment"

echo "Step 1: Pull the Docker image"
docker-compose pull
echo

echo "Step 2: Generate the data key"
docker-compose run --no-deps --rm conjur data-key generate > data_key
echo

echo "Step 3: Load data key as environment variable"
export CONJUR_DATA_KEY="$(< data_key)"
echo

echo "Step 4: Start the Conjur OSS environment"
docker-compose up -d
echo

docker-compose exec -T conjur conjurctl wait -r 30 -p 80
echo

echo "Step 5: Create admin account"
docker-compose exec -T conjur conjurctl account create demo > admin_data
echo

echo "Step 6: Deploy Conjur CLI"
wget -O conjur-cli-rhel-8.tar.gz https://github.com/cyberark/cyberark-conjur-cli/releases/download/v7.1.0/conjur-cli-rhel-8.tar.gz
tar -xvf conjur-cli-rhel-8.tar.gz
chmod +x conjur
sudo mv conjur /usr/local/bin
echo


echo "Step 7: Connect the Conjur client to the Conjur server"
conjur init --force -s -u https://$(hostname -f):8443 -a demo << EOF
yes
yes
yes
yes
EOF
echo

announce "UNIT 2. Define Policy"

echo "Step 1: Log in to Conjur as admin"
admin_api_key="$(cat admin_data | awk '/API key for admin/{print $NF}' | tr -d '\r')"
conjur login -i admin -p ${admin_api_key}
echo

echo "Step 2: Load the Sample Policy"
conjur policy update -b root -f policy/BotApp.yml > my_app_data
echo

echo "Step 3: Log out of Conjur as admin"
conjur logout
echo

announce "UNIT 3. Store a Secret in Conjur"

echo "Step 1: Log in as Dave"
cat my_app_data | awk '/"api_key":/{print $NF}' | tr -d '"' > my_api_keys
dave_api_key="$(cat my_api_keys | awk 'NR==1')"
conjur login -i Dave@BotApp -p ${dave_api_key}
echo

echo "Step 2: Generate Secret"
secretVal=$(openssl rand -hex 12 | tr -d '\r\n')
echo

echo "Step 3: Store Secret"
conjur variable set -i BotApp/secretVar -v "${secretVal}"
echo

announce "UNIT 4. Run the Demo App"

echo "Step 2: Generate Conjur Token in Bot App"
bot_api_key="$(cat my_api_keys | awk 'NR==2' | tr -d '\r')"
curl -d "${bot_api_key}" -k https://$(hostname -f):8443/authn/demo/host%2FBotApp%2FmyDemoApp/authenticate > ./conjur_token
echo

echo "Step 3: Fetch Secret"
fetched=$(./program.sh)
echo

echo "Step 4: Compare Generated and Fetched Secrets"
printf "Generated:\t${secretVal}\n"
printf "Fetched:\t${fetched##*: }\n"
if [[ $fetched =~ ${secretVal} ]]; then
  echo "Generated secret matches secret fetched by Bot App"
  echo "WORKFLOW PASSED."
else
  echo "Generated secret does not match the secret fetched by Bot App"
  exit 1
fi
