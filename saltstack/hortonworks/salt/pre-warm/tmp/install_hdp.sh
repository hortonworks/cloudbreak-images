#!/bin/bash

set -e

check_prerequisites() {
  : ${STACK_TYPE:? required}
  : ${STACK_VERSION:? reqired}
  : ${STACK_BASEURL:? reqired}
  : ${STACK_REPOID:? required}
  : ${VDF:? required}
  : ${STACK_REPOSITORY_VERSION:? required}
  : ${CLUSTERMANAGER_VERSION:? reqired}
  : ${OS:? reqired}
  : ${REPOSITORY_TYPE:? required}
}

set_hdp_repo() {
  REPOSITORY_NAME=$(tr '[:upper:]' '[:lower:]' <<< ${STACK_TYPE})

  mkdir -p ${REPOSITORY_NAME}/${OS}
  cd ${REPOSITORY_NAME}/${OS}/

  curl --fail ${STACK_BASEURL}/${REPOSITORY_NAME}.repo -o /etc/yum.repos.d/${REPOSITORY_NAME}.repo || true
  curl --fail ${STACK_BASEURL}/${REPOSITORY_NAME}bn.repo -o /etc/yum.repos.d/${REPOSITORY_NAME}.repo || true
  #if the 'bn' repo exist that will rewrite /etc/yum.repos.d/${REPOSITORY_NAME}.repo with that

}

set_repos() {
  rm  -rvf  /var/run/yum.pid

  mkdir -p /var/www/html/
  cd /var/www/html

  curl ${CLUSTERMANAGER_BASEURL}/ambari.repo -o /etc/yum.repos.d/ambari.repo
  mkdir -p ambari/${OS}
  cd ambari/${OS}/
  reposync -r ambari-${CLUSTERMANAGER_VERSION}
  curl ${CLUSTERMANAGER_BASEURL}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins --create-dirs -o /var/www/html/ambari/${OS}/ambari-${CLUSTERMANAGER_VERSION}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins
  createrepo /var/www/html/ambari/${OS}/ambari-${CLUSTERMANAGER_VERSION}/
  sed -i "s;${CLUSTERMANAGER_BASEURL};${LOCAL_URL_AMBARI};g" /etc/yum.repos.d/ambari.repo
  cp /etc/yum.repos.d/ambari.repo /var/www/html/

  cd ../..
  set_hdp_repo
  cat /etc/yum.repos.d/${REPOSITORY_NAME}.repo | sed -e '/HDP-UTIL/,$d' > ${REPOSITORY_NAME}-core.repo

  HDP_URL=$(grep -Pho '(?<=baseurl=).*' ${REPOSITORY_NAME}-core.repo)
  HDP_GPG_KEY_URL=$(grep -Pho '(?<=gpgkey=).*' ${REPOSITORY_NAME}-core.repo)
  rm ${REPOSITORY_NAME}-core.repo
  reposync -r ${STACK_TYPE}-${STACK_VERSION}
  curl  ${STACK_BASEURL}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins --create-dirs -o /var/www/html/${REPOSITORY_NAME}/${OS}/${STACK_TYPE}-${STACK_VERSION}/RPM-GPG-KEY/RPM-GPG-KEY-Jenkins
  createrepo /var/www/html/${REPOSITORY_NAME}/${OS}/${STACK_TYPE}-${STACK_VERSION}/
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
  VDF_FILE=/var/www/html/${STACK_TYPE}-${STACK_VERSION}.xml
  curl ${VDF} -o ${VDF_FILE}
  HDP_URL=$(grep -Pho "(?<=\<baseurl\>).*/${STACK_TYPE}/.*(?=\<\/baseurl\>)" ${VDF_FILE})
  HDP_UTILS_URL=$(grep -Pho "(?<=\<baseurl\>).*/HDP-UTILS.*(?=\<\/baseurl\>)" ${VDF_FILE})
  sed -i "s;${HDP_URL};${LOCAL_URL_HDP};g" ${VDF_FILE}
  sed -i "s;${HDP_UTILS_URL};${LOCAL_URL_HDP_UTILS};g" ${VDF_FILE}
  export VDF=${LOCAL_URL_VDF}
}

install_hdp_without_ambari() {
  set_hdp_repo
  #REPOSITORY_NAME=$(tr '[:upper:]' '[:lower:]' <<< ${STACK_TYPE})bn
  ##yum install -y mysql-server mysql
  #curl ${STACK_BASEURL}/${REPOSITORY_NAME}.repo -o /etc/yum.repos.d/${REPOSITORY_NAME}.repo
  yum repo-pkgs clustermanager -y install
  yum repo-pkgs ${STACK_TYPE}-${STACK_VERSION} -y install --skip-broken
  if [[ "$STACK_TYPE" == "HDP" ]]; then
    yum repo-pkgs HDP-UTILS-${HDPUTIL_VERSION} -y install --skip-broken
  fi
  echo "Installation successful" >> /tmp/install_hdp.status
}

install_mpacks() {
    if [[ -n "$MPACK_URLS" && "$MPACK_URLS" != 'None' ]]; then
      IFS=, read -ra mpacks <<< "$MPACK_URLS"
      for mpack in "${mpacks[@]}"; do
        echo yes | ambari-server install-mpack --mpack=${mpack} --verbose
      done
    fi
}

main() {
  if [[ -n "$STACK_VERSION" ]]; then
    check_prerequisites
    exec 1>/var/log/install_hdp.log 2>&1
    if [[ "$REPOSITORY_TYPE" == "local" ]]; then
      set_repos
      download_vdf
    fi
    install_hdp_without_ambari
    install_mpacks
  fi
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
