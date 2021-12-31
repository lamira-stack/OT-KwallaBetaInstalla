#!/bin/bash

OS_VERSION=$(lsb_release -sr)
INSTALLER_NAME="OT-KwallaBetaInstalla"
GRAPHDB_FILE="/root/graphdb-free-9.10.1-dist.zip"
N1=$'\n'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#echo -e "${GREEN}ALREADY STOPPED${NC}"
#if [[ $? -eq 0 ]]; then
#    echo -e "${GREEN}SUCCESS${NC}"
#else
#    echo -e "${RED}FAILED${NC}"
#    $PROJECTDIR/data/send.sh "Delete $BACKUPDIR contents FAILED.${N1}$OUTPUT"
#    exit 1
#fi

echo -n "Checking that the OS is Ubuntu 20.04 ONLY: "

if [[ $OS_VERSION != 20.04 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "$INSTALLER_NAME requires Ubuntu 20.04. Destroy this VPS and remake using Ubuntu 20.04."
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Checking that the GraphDB file is present in /root: "

if [[ ! -f $GRAPHDB_FILE ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "The graphdb file needs to be downloaded to /root. Please create an account at https://www.ontotext.com/products/graphdb/graphdb-free/ and click the standalone version link in the email."
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

cd

#echo -n "Checking to make sure we are in /root directory: "

#CURRENT_DIR=$(pwd >/dev/null 2>&1)
#if [[ $CURRENT_DIR != /root ]]; then
#    echo -e "${RED}FAILED${NC}"
#    echo "You need to be root to install the beta. Please login as root (or sudo -i) and rerun the installer."
#    exit 1
#else
#    echo -e "${GREEN}SUCCESS${NC}"
#fi

echo -n "Updating Ubuntu package repository: "
OUTPUT=$(apt update >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error updating the Ubuntu repo."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Updating Ubuntu to latest version: "
OUTPUT=$(apt upgrade -y >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo -n "There was an error updating Ubuntu to the latest version."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Installing default-jre: "

OUTPUT=$(apt install default-jre unzip jq -y >/dev/null 2>&1)

if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error installing default-jre."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Unzipping GraphDB: "
OUTPUT=$(unzip -o $GRAPHDB_FILE >/dev/null 2>&1)

if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error unzipping GraphDB."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Starting GraphDB: "

OUTPUT=$(nohup /root/graphdb-free-9.10.1/bin/graphdb >/dev/null 2>&1 &)

if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error starting GraphDB."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Confirming GraphDB has started: "
GRAPH_STARTED=$(cat nohup.out | grep 'Started GraphDB' | wc -l >/dev/null 2>&1)

if [[$GRAPH_STARTED ! -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo -n "GraphDB failed to start."
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Downloading Node.js v14: "

OUTPUT=$(curl -sL https://deb.nodesource.com/setup_14.x -o setup_14.sh >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error downloading nodejs setup."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

sh ./setup_14.sh

echo -n "Downloading Node.js v14: "

OUTPUT=$(curl -sL https://deb.nodesource.com/setup_14.x >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error setting up nodejs."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Setting up Node.js v14: "

OUTPUT=$(sh setup_14.sh >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error setting up nodejs."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Installing aptitude: "

OUTPUT=$(apt update && apt install aptitude -y >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error installing aptitude."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Installing nodejs and npm: "

OUTPUT=$(aptitude install nodejs npm -y >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error installing nodejs/npm."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Installing forever: "

OUTPUT=$(npm install forever -g >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error installing forever."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Installing tcllib and mysql-server: "

OUTPUT=$(apt install tcllib mysql-server -y >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error installing tcllib and mysql-server."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Creating a local operational database: "

mysql -u root  -e "CREATE DATABASE operationaldb /*\!40100 DEFAULT CHARACTER SET utf8 */;"
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error creating the database (Step 1 of 3)."
    echo $OUTPUT
    exit 1
fi

mysql -u root -e "update mysql.user set plugin = 'mysql_native_password' where User='root';"
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error updating mysql.user set plugin (Step 2 of 3)."
    echo $OUTPUT
    exit 1
fi

mysql -u root -e "flush privileges;"
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error flushing privileges (Step 3 of 3)."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Commenting out max_binlog_size: "

OUTPUT=$(sed -i 's|max_binlog_size|#max_binlog_size|' /etc/mysql/mysql.conf.d/mysqld.cnf >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error commenting out max_binlog_size."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Disabling binary logs: "

OUTPUT=$(echo "disable_log_bin" >> /etc/mysql/mysql.conf.d/mysqld.cnf)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error disabling binary logs."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Restarting mysql: "

OUTPUT=$(systemctl restart mysql >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error restarting mysql."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Installing git: "

OUTPUT=$(apt install git -y >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error installing git."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Cloning the V6 git repo: "

OUTPUT=$(git clone https://github.com/OriginTrail/ot-node >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error cloning the V6 git repo."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Changing directory to ot-node: "

OUTPUT=$(cd ot-node >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error changing directory to ot-node."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Executing git checkout: "

OUTPUT=$(git checkout v6/release/testnet >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error executing git checkout."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Executing npm install: "

OUTPUT=$(npm install >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error executing npm install."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Opening firewall ports 22, 8900,9000: "

OUTPUT=$(ufw allow 22/tcp && ufw allow 8900 && ufw allow 9000 >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error opening the firewall ports."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Enabling the firewall: "

OUTPUT=$(yes | ufw enable >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error enabling the firewall."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Adding NODE_ENV=testnet to .env: "

OUTPUT=$(echo "NODE_ENV=testnet" > .env)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error adding the env variable."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo "Creating default noderc config${N1}"

read -p "Enter the operational wallet address: " NODE_WALLET
echo "Node wallet: $NODE_WALLET"

read -p "Enter the private key: " NODE_PRIVATE_KEY
echo "Node wallet: $NODE_PRIVATE_KEY"

cp .origintrail_noderc_example .origintrail_noderc

jq --arg newval "$NODE_WALLET" '.blockchain[].publicKey |= $newval' .origintrail_noderc >> origintrail_noderc_temp
mv origintrail_noderc_temp .origintrail_noderc

jq --arg newval "$NODE_PRIVATE_KEY" '.blockchain[].privateKey |= $newval' .origintrail_noderc >> origintrail_noderc_temp
mv origintrail_noderc_temp .origintrail_noderc

echo -n "Running DB migrations: "

OUTPUT=$(npx sequelize --config=./config/sequelizeConfig.js db:migrate >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error running the db migrations."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Starting the node: "

OUTPUT=$(forever start -a -o out.log -e out.log index.js >/dev/null 2>&1)
if [[ $? -eq 1 ]]; then
    echo -e "${RED}FAILED${NC}"
    echo "There was an error starting the node."
    echo $OUTPUT
    exit 1
else
    echo -e "${GREEN}SUCCESS${NC}"
fi

echo -n "Logs will be displayed. Press ctrl+c to exit the logs. The node WILL stay running after you return to the command prompt."
echo " "
read -p "Press enter to continue..."

tail -f -n100 out.log