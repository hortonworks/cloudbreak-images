#!/bin/bash

BASE_DIRECTORY=$(cd $(dirname $0); pwd -L)
DIRECTORY_NAME="ccm_debugging_report"
VAR_LOG_MESSAGES="/var/log/messages"
FD_LEAK_WORK_AROUND_SCRIPT_LOGS="/var/log/socket_wait_cleanup.log"

mkdir ${DIRECTORY_NAME} && cd ${DIRECTORY_NAME}
ps -aux | grep "autossh" >> ps_output.txt
NLB_PORT=$(ps -aux | awk '/autossh\ -M/ {print $(NF-2)}' | uniq)
NLB_HOST=$(ps -aux | awk '/autossh\ -M/ {print $(NF-1)}' | cut -d'@' -f 2 | uniq)
TUNNEL_INITIATORS=$(ps -aux | awk '/autossh\ -M/ {print $(NF-1)}' | cut -d'@' -f 1)

echo "Collecting tunnel metadata ..."
echo -en "NLB Port: ${NLB_PORT}\n\n" > tunnel_metadata.txt
echo -en "NLB Host: ${NLB_HOST}\n\n" >> tunnel_metadata.txt
for tunnel_initiator in ${TUNNEL_INITIATORS[*]}; do
  echo -en "Tunnel Initiator Id: ${tunnel_initiator}\n\n" >> tunnel_metadata.txt
done

echo "Collecting nslookup output ..."
nslookup "${NLB_HOST}" >> nslookup_output.txt

echo "Collecting telnet output ..."
command -v telnet >> /dev/null && echo "Telnet is already installed at \$PATH" || { echo "Installing telnet ..."; yum install telnet; }
telnet "${NLB_HOST}" "${NLB_PORT}" >> telnet_output.txt 2>&1 &
TELNET_PID=$(ps -e | pgrep telnet > /dev/null 2>&1)
sleep 5
kill -2 "$TELNET_PID" > /dev/null  2>&1

echo "Collecting /var/log/messages ..."
cp  ${VAR_LOG_MESSAGES} messages
if [ -f ${FD_LEAK_WORK_AROUND_SCRIPT_LOGS} ]; then
    cp ${FD_LEAK_WORK_AROUND_SCRIPT_LOGS} fd_leak_work_around_script_logs.txt
fi

echo "Collecting tunnel status and restart logs ..."
TUNNELS=( $(systemctl list-units | awk '/ccm-tunnel/ {print $1}'))
for tunnel in ${TUNNELS[*]}; do
  systemctl status "$tunnel" >> autossh_status.txt
  echo -en '\n\n\n' >> autossh_status.txt
  SERVICE_TYPE=$( echo "$tunnel" | cut -d'@' -f 2 | cut -d'.' -f 1 )
  cp /var/log/autossh-"${SERVICE_TYPE}".log autossh-"${SERVICE_TYPE}".log
done

echo "Collecting cdp-doctor's output ..."
command -v cdp-doctor >> /dev/null && cdp-doctor network status >> cdp_doctor_output.txt || echo "cdp-doctor is not installed on this node...!"

echo "Collecting tcpdump for NLB host and port ..."
command -v tcpdump >> /dev/null && echo "Tcpdump is already installed at \$PATH" || { echo "Installing tcpdump ..."; yum install tcpdump; }
tcpdump -i any host "${NLB_HOST}" and port "${NLB_PORT}" -w tcpdump_output.pcap &
TCPDUMP_PID=$(ps -e | pgrep tcpdump)
sleep 90
kill -2 "$TCPDUMP_PID" >> /dev/null

cd .. && zip -r ${DIRECTORY_NAME}.zip ${DIRECTORY_NAME}
rm -rf ${DIRECTORY_NAME}