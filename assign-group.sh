#!/bin/sh
# Assuming TAG_FILE contains a value for the group key
# Alternative would be to simply define the group using GROUP_NAME="My group"

TAG_FILE=/etc/insights-client/tags.yaml
CREDS_FILE=/etc/insights-client/creds

GROUP_NAME=`sed -n -e 's/^group: //p' $TAG_FILE | tail -n 1 | jq -Rr '@uri'`
SYSTEM_ID=`sudo insights-client --diagnosis | jq -r '.id'`

# Generate token for console.redhat.com
TOKEN=`curl -s -d @"$CREDS_FILE" -d "grant_type=client_credentials" "https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token" -d "scope=api.console" | jq -r '.access_token'`

# Remove system from existing group
curl -s -X 'DELETE' "https://console.redhat.com/api/inventory/v1/groups/hosts/$SYSTEM_ID" -H 'accept: */*' -H "Authorization: Bearer $TOKEN"

# Get group id from group name
GROUP_ID=`curl -s -X 'GET' "https://console.redhat.com/api/inventory/v1/groups?name=$GROUP_NAME" -H 'accept: application/json' -H "Authorization: Bearer $TOKEN" | jq -r '.results[] | .id'`

# Associate system to group
curl -s -X 'POST' "https://console.redhat.com/api/inventory/v1/groups/$GROUP_ID/hosts" -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Bearer ${TOKEN}" -d "[ \"$SYSTEM_ID\" ]"
