set_waagent_key_pair_type:
  file.replace:
    - name: /etc/waagent.conf
    - pattern: "Provisioning.SshHostKeyPairType.*"
    - repl: "Provisioning.SshHostKeyPairType=ecdsa"
    - onlyif: ls /etc/waagent.conf

set_waagent_decode_user_data:
  file.replace:
    - name: /etc/waagent.conf
    - pattern: "Provisioning.DecodeCustomData.*"
    - repl: "Provisioning.DecodeCustomData=y"
    - onlyif: ls /etc/waagent.conf

set_waagent_execute_user_data:
  file.replace:
    - name: /etc/waagent.conf
    - pattern: "Provisioning.ExecuteCustomData.*"
    - repl: "Provisioning.ExecuteCustomData=y"
    - onlyif: ls /etc/waagent.conf

deprovision_waagent:
  cmd.run:
    - name: waagent -deprovision -force -verbose
    - onlyif: ls /etc/waagent.conf