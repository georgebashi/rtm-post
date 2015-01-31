#!/bin/bash
# vim: set et sw=2 sts=2:

set -eu

if [ $# -eq 0 ]; then
  >&2 echo "Can't create a task without a name!"
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "You need jq installed! http://stedolan.github.io/jq/"; exit 1; }


# secrets
if [ -z "${RTM_API_KEY-}" -o -z "${RTM_SHARED_SECRET-}" ]; then
  >&2 echo "You must set the RTM_API_KEY and RTM_SHARED_SECRET environment variables."
  >&2 echo "You can sign up for these at https://www.rememberthemilk.com/services/api/keys.rtm"
  exit 1
fi

# urls
AUTH_URL="https://www.rememberthemilk.com/services/auth/"
REST_URL="https://api.rememberthemilk.com/services/rest/"

# md5 compat, probably broken on linux
function md5_str() {
  if builtin command -v md5 > /dev/null; then
    md5 -qs "$1"
  elif builtin command -v md5sum > /dev/null ; then
    echo -n "$1" | md5sum | awk '{print $1}'
  fi
}

# md5 a string with our shared secret in front
function sign() {
  md5_str "${RTM_SHARED_SECRET}$@"
}

# get the auth frob
function get_frob() {
  sig=$(sign "api_key${RTM_API_KEY}formatjsonmethodrtm.auth.getFrob")
  curl -s "${REST_URL}?format=json&method=rtm.auth.getFrob&api_key=${RTM_API_KEY}&api_sig=${sig}" | jq -r .rsp.frob -
}

# after the user has hit allow, turn the frob into a token
function get_token_from_frob() {
  sig=$(sign "api_key${RTM_API_KEY}formatjsonfrob${1}methodrtm.auth.getToken")
  curl -s "${REST_URL}?format=json&method=rtm.auth.getToken&frob=${1}&api_key=${RTM_API_KEY}&api_sig=${sig}" | jq -r .rsp.auth.token -
}

TOKEN=""

# do auth or read token
if [ ! -f $HOME/.rtm.token ]; then
  frob=$(get_frob)

  sig=$(sign "api_key${RTM_API_KEY}frob${frob}permswrite")
  echo "Auth needed, please hit ${AUTH_URL}?api_key=${RTM_API_KEY}&perms=write&frob=${frob}&api_sig=${sig}"
  echo
  read -p "Hit enter when done..."

  TOKEN=$(get_token_from_frob ${frob})
  echo "${TOKEN}" > $HOME/.rtm.token
  echo "Got token $TOKEN"
else
  TOKEN=$(cat $HOME/.rtm.token)
fi

# get a timeline / open a transcation
function get_timeline() {
  sig=$(sign "api_key${RTM_API_KEY}auth_token${TOKEN}formatjsonmethodrtm.timelines.create")
  curl -s "${REST_URL}?format=json&method=rtm.timelines.create&auth_token=${TOKEN}&api_key=${RTM_API_KEY}&api_sig=${sig}" | jq -r .rsp.timeline -
}
TIMELINE=$(get_timeline)

# encode the task string
TEXT=$@
TASK=$(python -c "import urllib; print urllib.quote('''$TEXT''')")

# write & print url
sig=$(sign "api_key${RTM_API_KEY}auth_token${TOKEN}formatjsonmethodrtm.tasks.addname${TEXT}parse1timeline${TIMELINE}")
curl -s "${REST_URL}?format=json&method=rtm.tasks.add&name=${TASK}&parse=1&timeline=${TIMELINE}&auth_token=${TOKEN}&api_key=${RTM_API_KEY}&api_sig=${sig}" | jq -r '"https://www.rememberthemilk.com/app/#list/" + .rsp.list.id + "/" + .rsp.list.taskseries.task.id' -
