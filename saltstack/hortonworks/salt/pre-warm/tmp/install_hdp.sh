#!/bin/bash

set -e

check_prerequisites() {
  : ${STACK_TYPE:? required}
  : ${HDP_STACK_VERSION:? required}
  : ${HDP_VERSION:? reqired}
  : ${HDP_BASEURL:? reqired}
  : ${HDP_REPOID:? required}
  : ${VDF:? required}
  : ${REPOSITORY_VERSION:? required}
  : ${AMBARI_VERSION:? reqired}
  : ${OS:? reqired}
  : ${REPOSITORY_TYPE:? required}
}

set_repos() {
  rm  -rvf  /var/run/yum.pid

  mkdir -p /var/www/html/
  cd /var/www/html

  curl ${AMBARI_BASEURL}/ambari.repo -o /etc/yum.repos.d/ambari.repo
  mkdir -p ambari/${OS}
  cd ambari/${OS}/
  reposync -r ambari-${AMBARI_VERSION}
  curl ${AMBARI_BASEURL}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins --create-dirs -o /var/www/html/ambari/${OS}/ambari-${AMBARI_VERSION}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins
  createrepo /var/www/html/ambari/${OS}/ambari-${AMBARI_VERSION}/
  sed -i "s;${AMBARI_BASEURL};${LOCAL_URL_AMBARI};g" /etc/yum.repos.d/ambari.repo
  cp /etc/yum.repos.d/ambari.repo /var/www/html/

  if [[ "$STACK_TYPE" = "HDP" ]]
  then
    REPOSITORY_NAME="hdp"
  elif [[ "$STACK_TYPE" = "HDF" ]]
  then
    REPOSITORY_NAME="hdf"
  fi

  cd ../..
  mkdir -p ${REPOSITORY_NAME}/${OS}
  cd ${REPOSITORY_NAME}/${OS}/

  curl ${HDP_BASEURL}/${REPOSITORY_NAME}.repo -o /etc/yum.repos.d/${REPOSITORY_NAME}.repo

  cat /etc/yum.repos.d/${REPOSITORY_NAME}.repo | sed -e '/HDP-UTIL/,$d' > ${REPOSITORY_NAME}-core.repo
  HDP_URL=$(grep -Pho '(?<=baseurl=).*' ${REPOSITORY_NAME}-core.repo)
  HDP_GPG_KEY_URL=$(grep -Pho '(?<=gpgkey=).*' ${REPOSITORY_NAME}-core.repo)
  rm ${REPOSITORY_NAME}-core.repo
  reposync -r ${STACK_TYPE}-${HDP_VERSION}
  curl  ${HDP_BASEURL}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins --create-dirs -o /var/www/html/${REPOSITORY_NAME}/${OS}/${STACK_TYPE}-${HDP_VERSION}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins
  createrepo /var/www/html/${REPOSITORY_NAME}/${OS}/${STACK_TYPE}-${HDP_VERSION}/
  sed -i "s;${HDP_URL};${LOCAL_URL_HDP};g" /etc/yum.repos.d/${REPOSITORY_NAME}.repo
  sed -i "s;${HDP_GPG_KEY_URL};${LOCAL_URL_HDP}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins;g" /etc/yum.repos.d/${REPOSITORY_NAME}.repo

  cat /etc/yum.repos.d/${REPOSITORY_NAME}.repo | sed -n -e '/HDP-UTIL/,$p' > ${REPOSITORY_NAME}-util.repo
  HDPUTIL_URL=$(grep -Pho '(?<=baseurl=).*' ${REPOSITORY_NAME}-util.repo)
  HDPUTIL_GPG_KEY_URL=$(grep -Pho '(?<=gpgkey=).*' ${REPOSITORY_NAME}-util.repo)
  rm ${REPOSITORY_NAME}-util.repo
  reposync -r HDP-UTILS-${HDPUTIL_VERSION}
  curl ${HDPUTIL_BASEURL}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins --create-dirs -o /var/www/html/${REPOSITORY_NAME}/${OS}/HDP-UTILS-${HDPUTIL_VERSION}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins
  createrepo /var/www/html/${REPOSITORY_NAME}/${OS}/HDP-UTILS-${HDPUTIL_VERSION}/
  sed -i "s;${HDPUTIL_URL};${LOCAL_URL_HDP_UTILS};g" /etc/yum.repos.d/${REPOSITORY_NAME}.repo
  sed -i "s;${HDPUTIL_GPG_KEY_URL};${LOCAL_URL_HDP_UTILS}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins;g" /etc/yum.repos.d/${REPOSITORY_NAME}.repo

  cp /etc/yum.repos.d/${REPOSITORY_NAME}.repo /var/www/html/
  chmod -R 755 /var/www/html
}

download_vdf() {
  # VDF URL sample
  # http://private-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.6.4.5-2/HDP-2.6.4.5-2.xml
  VDF_FILE=/var/www/html/${STACK_TYPE}-${HDP_VERSION}.xml
  curl ${VDF} -o ${VDF_FILE}
  HDP_URL=$(grep -Pho "(?<=\<baseurl\>).*/${STACK_TYPE}/.*(?=\<\/baseurl\>)" ${VDF_FILE})
  HDP_UTILS_URL=$(grep -Pho "(?<=\<baseurl\>).*/HDP-UTILS.*(?=\<\/baseurl\>)" ${VDF_FILE})
  sed -i "s;${HDP_URL};${LOCAL_URL_HDP};g" ${VDF_FILE}
  sed -i "s;${HDP_UTILS_URL};${LOCAL_URL_HDP_UTILS};g" ${VDF_FILE}
  export VDF=${LOCAL_URL_VDF}
}

install_hdp() {
#    exec 3>&1 4>&2
#    exec 1>/var/log/install_hdp.log 2>&1
    if [[ -z "$JAVA_HOME" ]]; then
      source /etc/profile.d/java.sh
    fi
    cd /etc/yum.repos.d

    IP=$(ip addr show {{ pillar['network_interface'] }} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
    echo Ip addess is: $IP
    echo "$IP $(hostname).mydomain $(hostname)" >> /etc/hosts

    ambari-server setup --silent --java-home ${JAVA_HOME}

    if [[ -n "$MPACK_URLS" && "$MPACK_URLS" != 'None' ]]; then
      IFS=, read -ra mpacks <<< "$MPACK_URLS"
      for mpack in "${mpacks[@]}"; do
        echo yes | ambari-server install-mpack --mpack=${mpack} --verbose
      done
    fi

    ambari-server start
    echo Waiting for Ambari server to start
    while [[ ! "RUNNING" == "$(curl -s -m 5 -u admin:admin -H "Accept: text/plain" localhost:8080/api/v1/check)" ]]; do
      sleep 5;
    done
    ambari-agent start
    echo Wait for Ambari agent to join
    while [[ -z "$(curl -s -m 5 -X GET -u admin:admin localhost:8080/api/v1/hosts/ | jq .items[].Hosts.host_name -r)" ]]; do
      sleep 5;
    done
    # leave MYSQL_SERVER out from the blueprint, because it will create a hive user with invalid credentials
    yum install -y mysql-server mysql
    if [[ "$STACK_TYPE" == "HDP" && "$HDP_STACK_VERSION" == "2.4" ]]; then
      BLUEPRINT='{"host_groups":[{"name":"host_group_1","configurations":[],"components":[{"name":"KNOX_GATEWAY"},{"name":"ATLAS_SERVER"},{"name":"SUPERVISOR"},{"name":"SLIDER"},{"name":"ACCUMULO_MASTER"},{"name":"APP_TIMELINE_SERVER"},{"name":"ACCUMULO_MONITOR"},{"name":"HIVE_CLIENT"},{"name":"HDFS_CLIENT"},{"name":"NODEMANAGER"},{"name":"METRICS_COLLECTOR"},{"name":"MAHOUT"},{"name":"FLUME_HANDLER"},{"name":"WEBHCAT_SERVER"},{"name":"RESOURCEMANAGER"},{"name":"STORM_UI_SERVER"},{"name":"HIVE_SERVER"},{"name":"OOZIE_SERVER"},{"name":"FALCON_CLIENT"},{"name":"SECONDARY_NAMENODE"},{"name":"SQOOP"},{"name":"YARN_CLIENT"},{"name":"ACCUMULO_GC"},{"name":"DRPC_SERVER"},{"name":"PIG"},{"name":"HISTORYSERVER"},{"name":"KAFKA_BROKER"},{"name":"OOZIE_CLIENT"},{"name":"NAMENODE"},{"name":"FALCON_SERVER"},{"name":"HCAT"},{"name":"KNOX_GATEWAY"},{"name":"METRICS_MONITOR"},{"name":"SPARK_JOBHISTORYSERVER"},{"name":"SPARK_CLIENT"},{"name":"AMBARI_SERVER"},{"name":"DATANODE"},{"name":"ACCUMULO_TSERVER"},{"name":"ZOOKEEPER_SERVER"},{"name":"ZOOKEEPER_CLIENT"},{"name":"TEZ_CLIENT"},{"name":"METRICS_GRAFANA"},{"name":"HIVE_METASTORE"},{"name":"ACCUMULO_TRACER"},{"name":"MAPREDUCE2_CLIENT"},{"name":"ACCUMULO_CLIENT"},{"name":"NIMBUS"}],"cardinality":"1"}],"Blueprints":{"stack_name":"HDP","stack_version":"2.4"}}'
    fi
    if [[ "$STACK_TYPE" == "HDP" && "$HDP_STACK_VERSION" == "2.5" ]]; then
      BLUEPRINT='{"host_groups":[{"name":"host_group_1","configurations":[{"hive-env":{"hive_database":"Existing MySQL / MariaDB Database"}}],"components":[{"name":"KNOX_GATEWAY"},{"name":"INFRA_SOLR"},{"name":"INFRA_SOLR_CLIENT"},{"name":"RANGER_ADMIN"},{"name":"RANGER_TAGSYNC"},{"name":"RANGER_USERSYNC"},{"name":"ATLAS_SERVER"},{"name":"ATLAS_CLIENT"},{"name":"SUPERVISOR"},{"name":"SLIDER"},{"name":"ACCUMULO_MASTER"},{"name":"APP_TIMELINE_SERVER"},{"name":"ACCUMULO_MONITOR"},{"name":"HIVE_CLIENT"},{"name":"HDFS_CLIENT"},{"name":"NODEMANAGER"},{"name":"METRICS_COLLECTOR"},{"name":"MAHOUT"},{"name":"FLUME_HANDLER"},{"name":"WEBHCAT_SERVER"},{"name":"RESOURCEMANAGER"},{"name":"STORM_UI_SERVER"},{"name":"HIVE_SERVER"},{"name":"OOZIE_SERVER"},{"name":"FALCON_CLIENT"},{"name":"SECONDARY_NAMENODE"},{"name":"SQOOP"},{"name":"YARN_CLIENT"},{"name":"ACCUMULO_GC"},{"name":"DRPC_SERVER"},{"name":"PIG"},{"name":"HISTORYSERVER"},{"name":"KAFKA_BROKER"},{"name":"OOZIE_CLIENT"},{"name":"NAMENODE"},{"name":"FALCON_SERVER"},{"name":"HCAT"},{"name":"KNOX_GATEWAY"},{"name":"METRICS_MONITOR"},{"name":"SPARK_JOBHISTORYSERVER"},{"name":"SPARK_CLIENT"},{"name":"AMBARI_SERVER"},{"name":"DATANODE"},{"name":"ACCUMULO_TSERVER"},{"name":"ZOOKEEPER_SERVER"},{"name":"ZOOKEEPER_CLIENT"},{"name":"TEZ_CLIENT"},{"name":"METRICS_GRAFANA"},{"name":"HIVE_METASTORE"},{"name":"ACCUMULO_TRACER"},{"name":"MAPREDUCE2_CLIENT"},{"name":"ACCUMULO_CLIENT"},{"name":"NIMBUS"},{"name":"ZEPPELIN_MASTER"},{"name":"SPARK2_JOBHISTORYSERVER"},{"name":"SPARK2_CLIENT"},{"name":"SPARK2_THRIFTSERVER"},{"name":"SPARK_THRIFTSERVER"}],"cardinality":"1"}],"Blueprints":{"stack_name":"HDP","stack_version":"2.5"}}'
    fi
    if [[ "$STACK_TYPE" == "HDP" && "$HDP_STACK_VERSION" == "2.6" ]]; then
      BLUEPRINT='{"configurations":[{"druid-common":{"properties_attributes":{},"properties":{"druid.metadata.storage.type":"derby","druid.metadata.storage.connector.connectURI":"jdbc:derby://localhost:1527/druid;create=true","druid.extensions.loadList":"[\"postgresql-metadata-storage\", \"druid-s3-extensions\"]","druid.selectors.indexing.serviceName":"druid/overlord","druid.storage.type":"s3"}}},{"druid-overlord":{"properties_attributes":{},"properties":{"druid.indexer.storage.type":"metadata","druid.indexer.runner.type":"remote","druid.service":"druid/overlord","druid.port":"8090"}}},{"druid-middlemanager":{"properties_attributes":{},"properties":{"druid.server.http.numThreads":"50","druid.worker.capacity":"3","druid.processing.numThreads":"2","druid.indexer.runner.javaOpts":"-server -Xmx2g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhdp.version={{ '{{' }}stack_version{{ '}}' }} -Dhadoop.mapreduce.job.classloader=true","druid.service":"druid/middlemanager","druid.port":"8091"}}},{"druid-coordinator":{"properties_attributes":{},"properties":{"druid.coordinator.merge.on":"false","druid.port":"8081"}}},{"druid-historical":{"properties_attributes":{},"properties":{"druid.server.http.numThreads":"50","druid.processing.numThreads":"10","druid.service":"druid/historical","druid.port":"8083","druid.server.maxSize":"300000000000"}}},{"druid-broker":{"properties_attributes":{},"properties":{"druid.cache.type":"local","druid.server.http.numThreads":"50","druid.broker.http.numConnections":"5","druid.processing.numThreads":"2","druid.service":"druid/broker","druid.port":"8082"}}},{"druid-router":{"properties_attributes":{},"properties":{}}},{"superset":{"properties_attributes":{},"properties":{"SECRET_KEY":"123admin123","SUPERSET_DATABASE_TYPE":"sqlite"}}},{"hive-env":{"hive_database":"Existing MySQL / MariaDB Database"}}],"host_groups":[{"name":"host_group_1","configurations":[],"components":[{"name":"KNOX_GATEWAY"},{"name":"INFRA_SOLR"},{"name":"INFRA_SOLR_CLIENT"},{"name":"RANGER_ADMIN"},{"name":"RANGER_TAGSYNC"},{"name":"RANGER_USERSYNC"},{"name":"ATLAS_SERVER"},{"name":"ATLAS_CLIENT"},{"name":"SUPERVISOR"},{"name":"SLIDER"},{"name":"ACCUMULO_MASTER"},{"name":"APP_TIMELINE_SERVER"},{"name":"ACCUMULO_MONITOR"},{"name":"HIVE_CLIENT"},{"name":"HDFS_CLIENT"},{"name":"NODEMANAGER"},{"name":"METRICS_COLLECTOR"},{"name":"MAHOUT"},{"name":"FLUME_HANDLER"},{"name":"WEBHCAT_SERVER"},{"name":"RESOURCEMANAGER"},{"name":"STORM_UI_SERVER"},{"name":"HIVE_SERVER"},{"name":"OOZIE_SERVER"},{"name":"FALCON_CLIENT"},{"name":"SECONDARY_NAMENODE"},{"name":"SQOOP"},{"name":"YARN_CLIENT"},{"name":"ACCUMULO_GC"},{"name":"DRPC_SERVER"},{"name":"PIG"},{"name":"HISTORYSERVER"},{"name":"KAFKA_BROKER"},{"name":"OOZIE_CLIENT"},{"name":"NAMENODE"},{"name":"FALCON_SERVER"},{"name":"HCAT"},{"name":"KNOX_GATEWAY"},{"name":"METRICS_MONITOR"},{"name":"SPARK_JOBHISTORYSERVER"},{"name":"SPARK_CLIENT"},{"name":"AMBARI_SERVER"},{"name":"DATANODE"},{"name":"ACCUMULO_TSERVER"},{"name":"ZOOKEEPER_SERVER"},{"name":"ZOOKEEPER_CLIENT"},{"name":"TEZ_CLIENT"},{"name":"METRICS_GRAFANA"},{"name":"HIVE_METASTORE"},{"name":"ACCUMULO_TRACER"},{"name":"MAPREDUCE2_CLIENT"},{"name":"ACCUMULO_CLIENT"},{"name":"NIMBUS"},{"name":"ZEPPELIN_MASTER"},{"name":"SPARK2_JOBHISTORYSERVER"},{"name":"SPARK2_CLIENT"},{"name":"SPARK2_THRIFTSERVER"},{"name":"SPARK_THRIFTSERVER"},{"name":"DRUID_OVERLORD"},{"name":"DRUID_COORDINATOR"},{"name":"DRUID_ROUTER"},{"name":"DRUID_BROKER"},{"name":"SUPERSET"},{"name":"DRUID_HISTORICAL"},{"name":"DRUID_MIDDLEMANAGER"}],"cardinality":"1"}],"Blueprints":{"stack_name":"HDP","stack_version":"2.6"}}'
    fi
    if [[ "$STACK_TYPE" == "HDF" && "$HDP_STACK_VERSION" == "3.1" ]]; then
      BLUEPRINT='{"Blueprints":{"stack_name":"HDF","stack_version":"3.1"},"configurations":[{"nifi-ambari-config":{"nifi.security.encrypt.configuration.password":"changemeplease","nifi.node.protocol.port":"9089","nifi.node.port":"9090","nifi.node.ssl.port":"9091","nifi.max_mem":"1g"}},{"nifi-properties":{"nifi.sensitive.props.key":"changemeplease","nifi.security.user.login.identity.provider":"kerberos-provider","nifi.security.identity.mapping.pattern.kerb":"^(.*?)@(.*?)$","nifi.security.identity.mapping.value.kerb":"$1"}},{"nifi-ambari-ssl-config":{"nifi.toolkit.tls.token":"changemeplease","nifi.node.ssl.isenabled":"true","nifi.security.needClientAuth":"false","nifi.toolkit.dn.prefix":"CN=","nifi.toolkit.dn.suffix":", OU=NIFI","nifi.initial.admin.identity":"admin"}},{"nifi-env":{"nifi_group":"nifi","nifi_user":"nifi"}},{"ams-grafana-env":{"metrics_grafana_password":"admin"}}],"host_groups":[{"name":"host_group_1","components":[{"name":"NIFI_CA"},{"name":"NIFI_MASTER"},{"name":"METRICS_COLLECTOR"},{"name":"METRICS_MONITOR"},{"name":"METRICS_GRAFANA"},{"name":"ZOOKEEPER_SERVER"},{"name":"ZOOKEEPER_CLIENT"}],"cardinality":"1"}]}'
    fi
    CLUSTER_TEMPLATE="{\"blueprint\":\"bp\",\"default_password\":\"admin\",\"host_groups\":[{\"name\":\"host_group_1\",\"hosts\":[{\"fqdn\":\""$(hostname -f)"\"}]}],\"provision_action\":\"INSTALL_ONLY\",\"repository_version\": \"$REPOSITORY_VERSION\"}"
    VDF_TEMPLATE="{\"VersionDefinition\": { \"version_url\": \"$VDF\" }}"
    curl -X POST -u admin:admin -H "X-Requested-By: ambari" -d "$VDF_TEMPLATE" http://localhost:8080/api/v1/version_definitions
    curl -X POST -u admin:admin -H "X-Requested-By: ambari" -d "$BLUEPRINT" http://localhost:8080/api/v1/blueprints/bp
    curl -X POST -u admin:admin -H "X-Requested-By: ambari" -d "$CLUSTER_TEMPLATE" http://localhost:8080/api/v1/clusters/test
    if curl --fail -sS -m 5 -X GET -u admin:admin localhost:8080/api/v1/clusters/test/requests/1; then
      echo Wait for install to finish
      while true; do
        REQUEST=$(curl -sS -m 5 -X GET -u admin:admin localhost:8080/api/v1/clusters/test/requests/1)
        PROGRESS=$(echo $REQUEST | jq .Requests.progress_percent)
        STATUS=$(echo $REQUEST | jq -r .Requests.request_status)
        if [[ "-1" == "$PROGRESS" || "FAILED" == "$STATUS" ]]; then
          echo Failed to install the packages, please check logs for further information!
          exit 1;
        fi
        if [[ "100" == "$PROGRESS" ]]; then
          echo Install is finished!
          break
        fi
        echo Install status: ${PROGRESS}%
        sleep 30;
      done
    else
      RC=$?
      echo Failed to check Ambari status with rc: $RC
      echo "exit $RC"
    fi
    reset_ambari
    cleanup_configs
    echo "Installation successful" >> /tmp/install_hdp.status
#    exec 1>&3 2>&4
#    exit 0
}

reset_ambari() {
  #ambari-agent stop || true
  pkill -f ambari_agent || true
  ambari-server stop
  pkill -f ambari-server || true
  ambari-server reset --verbose --silent
}

cleanup_configs() {
  # get rid of old commands and configs
  cd /var/lib/ambari-agent/data/ && ls -1 | grep -v version | xargs rm -vf
  sed -i "s/$IP *.*//g" /etc/hosts
  cd /etc/yum.repos.d && ls -1 | grep *.sh | xargs rm -vf || :
}


main() {
#  set -x
  if [[ -n "$HDP_VERSION" ]]; then
    check_prerequisites
    #exec 1>/var/log/install_hdp.log 2>&1
    if [[ "$REPOSITORY_TYPE" == "local" ]]; then
      set_repos
      download_vdf
    fi
    install_hdp
  fi
#  set +x
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
