enable-networkmanager:
  cmd.run:
    - name: systemctl enable NetworkManager

check-networkmanager:
  cmd.run:
    - name: systemctl status NetworkManager

start-networkmanager:
  cmd.run:
    - name: systemctl start NetworkManager

check-network-interface:
  cmd.run:
    - name: nmcli connection show eth0
