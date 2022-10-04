#!/bin/bash
main() {
  CONT_SESSION_TOKEN=$(cat ./conjur_token | base64 | tr -d '\r\n')
  VAR_VALUE=$(curl -s -k -H "Content-Type: application/json" -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" https://$(hostname -f):8443/secrets/demo/variable/BotApp%2FsecretVar)
  echo "The retrieved value is: $VAR_VALUE"
}
main "$@"
exit
