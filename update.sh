#!/bin/bash
apt-get update
apt-get -f install --assume-yes pptp-linux openvpn

if ! id "admin" &> /dev/null; then
  delgroup admin
  adduser --disabled-password --gecos "" admin
  echo admin:admin | chpasswd
  usermod admin -g sudo
fi

if ! test -d /home/admin; then
  mkhomedir_helper admin
fi


if id -nG admin | grep -qw "sudo"; then
  rm -rf /tmp/latest.tar.gz
  rm -rf /tmp/dashboardinstall
  echo 'Downloading latest release...' > /var/dashboard/logs/dashboard-update.log
  wget --no-cache https://raw.githubusercontent.com/silviokennecke/PiscesQoLDashboard/main/latest.tar.gz -O /tmp/latest.tar.gz
  cd /tmp
  if test -f latest.tar.gz; then
    echo 'Extracting contents...' >> /var/dashboard/logs/dashboard-update.log
    tar -xzf latest.tar.gz
    cd dashboardinstall
    rm dashboard/logs/dashboard-update.log
    
    for f in dashboard/services/*; do
      if ! test -f /var/$f; then
        cp $f /var/dashboard/services
      fi
    done
    
    for f in dashboard/statuses/*; do
      if ! test -f /var/$f; then
        cp $f /var/dashboard/statuses
      fi
    done
    
    for f in dashboard/logs/*; do
      if ! test -f /var/$f; then
        cp $f /var/dashboard/logs
      fi
    done
    
    for f in dashboard/vpn/*; do
      if ! test -f /var/$f; then
        cp $f /var/dashboard/logs
      fi
    done
    
    rm -rf dashboard/services/*
    rm -rf dashboard/statuses/*
    rm -rf dashboard/logs/*
    rm nginx/.htpasswd
    
    cp -r monitor-scripts/* /etc/monitor-scripts/   
    cp -r dashboard/* /var/dashboard/
    cp -r systemd/* /etc/systemd/system/
    chown root:www-data /var/dashboard/vpn/*
    chmod 755 /etc/monitor-scripts/*
    chown root:www-data /var/dashboard/services/*
    chown root:www-data /var/dashboard/statuses/*
    chmod 775 /var/dashboard/vpn/*
    chmod 775 /var/dashboard/services/*
    chmod 775 /var/dashboard/statuses/*
    chown root:www-data /var/dashboard
    chmod 775 /var/dashboard
    
    echo 'Starting and enabling services...' >> /var/dashboard/logs/dashboard-update.log
    FILES="systemd/*.timer"
    for f in $FILES;
      do
        name=$(echo $f | sed 's/.timer//' | sed 's/systemd\///')
        systemctl start $name.timer
        systemctl enable $name.timer
        systemctl start $name.service
        
        echo "$name enabled" >> /var/dashboard/logs/dashboard-update.log
      done
    systemctl daemon-reload
    bash /etc/monitor-scripts/pubkeys.sh
    echo 'Success.' >> /var/dashboard/logs/dashboard-update.log
    echo 'stopped' > /var/dashboard/services/dashboard-update
  else
    echo 'No installation archive found.  No changes made.' >> /var/dashboard/logs/dashboard-update.log
    echo 'stopped' > /var/dashboard/services/dashboard-update
  fi
else
  echo 'Error checking if admin user exists.  No changes made.' >> /var/dashboard/logs/dashboard-update.log
  echo 'stopped' > /var/dashboard/services/dashboard-update
fi
