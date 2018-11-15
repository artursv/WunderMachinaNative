#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

VAULT_FILE=$WT_ANSIBLE_VAULT_FILE
MYSQL_ROOT_PASS=

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


show_help() {
cat <<EOF
Usage: ${0##*/} [-fm MYSQL_ROOT_PASS] [-t|s ANSIBLE_TAGS] [-p ANSIBLE_VAULT_FILE] [ENVIRONMENT]
      -f                    First run, use when provisioning new servers.
      -r                    Skip installing requirements from ansible/requirements.txt.
      -m MYSQL_ROOT_PASS    For first run you need to provide new mysql root password.
      -p ANSIBLE_VAULT_FILE Path to ansible vault password. This can also be provided with WT_ANSIBLE_VAULT_FILE environment variable.
      -t ANSIBLE_TAGS       Ansible tags to be provisioned.
      -s ANSIBLE_TAGS       Ansible tags to be skipped when provisioning.
         ENVIRONMENT        Environment to be provisioned.
EOF

}
self_update() {
  if command -v md5sum >/dev/null 2>&1; then
    MD5COMMAND="md5sum"
  else
    MD5COMMAND="md5 -r"
  fi

  SELF=$(basename $0)
  UPDATEURL="https://raw.githubusercontent.com/artursv/WunderToolsNative/$GITBRANCH/provision.sh"
  MD5SELF=$($MD5COMMAND $0 | awk '{print $1}')
  MD5LATEST=$(curl -s $UPDATEURL | $MD5COMMAND | awk '{print $1}')
  if [[ "$MD5SELF" != "$MD5LATEST" ]]; then
    read -p "There is update for this script available. Update now ([y]es / [n]o)?" -n 1 -r;
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cd $ROOT
      curl -s -o $SELF $UPDATEURL
      echo "Update complete, please rerun any command you were running previously."
      echo "See CHANGELOG for more info."
      echo "Also remember to add updated script to git."
      exit
    fi
  fi
  # Clone and update virtual environment configurations
  if [ ! -d "$ROOT/ansible" ]; then
    git clone  -b $ansible_branch $ansible_remote $ROOT/ansible
    if [ -n "$ansible_revision" ]; then
      cd $ROOT/ansible
      git reset --hard $ansible_revision
      cd $ROOT
    fi
  else
    if [ -z "$ansible_revision" ]; then
      cd $ROOT/ansible
      git pull
      git checkout $ansible_branch
      cd $ROOT
    fi
  fi
}

pushd `dirname $0` > /dev/null
ROOT=`pwd -P`
popd > /dev/null
# Parse project config
PROJECTCONF=$ROOT/project.yml
echo $PROJECTCONF
eval $(parse_yaml $PROJECTCONF)

if [ -z "$wundertools_branch" ]; then
  GITBRANCH="master"
else
  GITBRANCH=$wundertools_branch
fi


self_update

OPTIND=1
ANSIBLE_TAGS=""
EXTRA_OPTS=""

while getopts ":hfrp:m:t:s:" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    r)  SKIP_REQUIREMENTS=1
        ;;
    t)  ANSIBLE_TAGS=$OPTARG
        ;;
    s)  ANSIBLE_SKIP_TAGS=$OPTARG
        ;;
    esac
done

shift "$((OPTIND-1))"
ENVIRONMENT=$1

if [ -z $ENVIRONMENT ]; then
  show_help
  exit 1
fi

pushd `dirname $0` > /dev/null
ROOT=`pwd -P`
popd > /dev/null

PLAYBOOKPATH=$ROOT/local.yml

if [ ! $SKIP_REQUIREMENTS ] ; then
  # Check if pip is installed
  which -a pip >> /dev/null
  if [[ $? != 0 ]] ; then
      echo "ERROR: pip is not installed! Install it first."
      echo "OSX:    $ easy_install pip"
      echo "Ubuntu: $ sudo apt-get install python-setuptools python-dev build-essential && sudo easy_install pip"
      echo "Centos: $ yum -y install python-pip"
      exit 1
  else
    # Install virtualenv
    which -a pipenv >> /dev/null
    if [[ $? != 0 ]] ; then
      sudo pip install pipenv
    fi
    cd $ROOT/ansible
    VENV=`pipenv --venv`

    # Ensure ansible & ansible library versions with pip
    if [ -f $ROOT/ansible/Pipfile.lock ]; then
      pipenv install
    else
      pipenv install ansible
    fi
  fi
fi

# Install ansible-galaxy roles
if [ -f $ROOT/conf/requirements.yml ]; then
  pipenv run ansible-galaxy install -r $ROOT/conf/requirements.yml
fi

if [ $ANSIBLE_TAGS ]; then
    pipenv run ansible-playbook -K $EXTRA_OPTS $PLAYBOOKPATH --tags "common,$ANSIBLE_TAGS"
elif [ $ANSIBLE_SKIP_TAGS ]; then
    pipenv run ansible-playbook -K $EXTRA_OPTS $PLAYBOOKPATH --skip-tags "$ANSIBLE_SKIP_TAGS"
else
    pipenv run ansible-playbook -K $EXTRA_OPTS $PLAYBOOKPATH
fi
