#!/bin/bash
if command -v termux-setup-storage; then
  echo For termux, please contact the RoboX-Userbot owner or wait for next updates. WE WILL SOON MAKE THIS BOT ABLE TO RUN ON EVERY HOST TYPE
  exit 1
fi

if [[ $UID != 0 ]]; then
  echo Please run this script as root
  exit 1
fi

apt update -y
apt install python3 python3-pip git ffmpeg wget gnupg -y || exit 2

su -c "python3 -m pip install -U pip" $SUDO_USER
su -c "python3 -m pip install -U wheel pillow" $SUDO_USER


if [[ -f ".env" ]] && [[ -f "RoboXUser.session" ]]; then
  echo "RoboX Userbot Is Already Working Or Please Remove Old Session Via >> rm RoboXUser.session"
  exit
fi

su -c "python3 -m pip install -U -r requirements.txt" $SUDO_USER || exit 2

echo
echo "Enter API_ID and API_HASH"
echo "You can get it here -> https://my.telegram.org/apps"
echo "Do Not Leave API_ID & API_HASH empty. Bot will not work without these vars!"
read -r -p "API_ID > " api_id

if [[ $api_id = "" ]]; then
  api_id=""
  api_hash=""
else
  read -r -p "API_HASH > " api_hash
fi

echo
echo "Choose database type:"
echo "[1] MongoDB db_url (Suggested.)"
echo "[2] MongoDB localhost"
echo "[3] Sqlite (default)"
read -r -p "> " db_type

echo
case $db_type in
  1)
    echo "Please enter db_url"
    read -r -p "> " db_url
    db_name=RoboX_Userbot
    db_type=mongodb
    ;;
  2)
    if systemctl status mongodb; then
      wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
      source /etc/os-release
      echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
      apt update
      apt install mongodb -y
      systemctl daemon-reload
      systemctl enable mongodb
    fi
    systemctl start mongodb

    db_url=mongodb://localhost:27017
    db_name=RoboX_Userbot
    db_type=mongodb
    ;;
  *)
    db_name=db.sqlite3
    db_type=sqlite3
    ;;
esac

cat > .env << EOL
API_ID=${api_id}
API_HASH=${api_hash}

# sqlite/sqlite3 or mongo/mongodb
DATABASE_TYPE=${db_type}
# file name for sqlite3, database name for mongodb
DATABASE_NAME=${db_name}

# only for mongodb
DATABASE_URL=${db_url}
EOL

chown -R $SUDO_USER:$SUDO_USER .

echo
echo "Choose installation type:"
echo "[1] PM2(Risky)"
echo "[2] Systemd service(Start itself If SERVER RESTARTED)"
echo "[3] Custom (default)"
read -r -p "> " install_type

su -c "python3 install.py ${install_type}" $SUDO_USER || exit 3

case $install_type in
  1)
    if ! command -v pm2; then
      curl -fsSL https://deb.nodesource.com/setup_17.x | bash
      apt install nodejs -y
      npm install pm2 -g
      su -c "pm2 startup" $SUDO_USER
      env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $SUDO_USER --hp /home/$SUDO_USER
    fi
    su -c "pm2 start main.py --name RoboX --interpreter python3" $SUDO_USER
    su -c "pm2 save" $SUDO_USER

    echo
    echo "============================"
    echo "RoboX-Userbot is working now!"
    echo "Installation type: PM2"
    echo "Start with: \"pm2 start RoboX\""
    echo "Stop with: \"pm2 stop RoboX\""
    echo "Process name: RoboX"
    echo "============================"
    echo "Credit Goes To > AYUSH, HARPREET, VIR."
    echo "============================"
    ;;
  2)
    cat > /etc/systemd/system/RoboX.service << EOL
[Unit]
Description=Service for RoboX Userbot

[Service]
Type=simple
ExecStart=$(which python3) ${PWD}/main.py
WorkingDirectory=${PWD}
Restart=always
User=${SUDO_USER}
Group=${SUDO_USER}

[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload
    systemctl start RoboX
    systemctl enable RoboX

    echo
    echo "============================"
    echo "RoboX-Userbot is working now!"
    echo "Installation type: Systemd service"
    echo "Start with: \"sudo systemctl start RoboX\""
    echo "Stop with: \"sudo systemctl stop RoboX\""
    echo "============================"
    echo "Credit Goes To > AYUSH, HARPREET, VIR."
    echo "============================"
    ;;
  *)
    echo
    echo "============================"
    echo "RoboX-Userbot is working now!"
    echo "Installation type: Custom"
    echo "Now Start with: \"bash start\""
    echo "============================"
    echo "Credit Goes To > AYUSH, HARPREET, VIR."
    echo "============================"
    ;;
esac

chown -R $SUDO_USER:$SUDO_USER .
