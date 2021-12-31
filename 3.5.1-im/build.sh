#!/bin/sh
SYSTEM=$1
VERSION=$2
EXTEND=$3

HOME=/opt/saturn/${VERSION}

FILE_NAME=v${VERSION}.tar.gz
FILE_URL=https://github.com/vipshop/Saturn/archive/${FILE_NAME}

CONSOLE_FILE_NAME='saturn-console-'${VERSION}'.jar'
CONSOLE_FILE_PATH='https://oss.sonatype.org/service/local/artifact/maven/content?r=releases&g=com.vip.saturn&a=saturn-console&c=exec&v='${VERSION}
CONSOLE_DIR_PATH=${HOME}/console

EXECUTOR_FILE_NAME='saturn-executor-'${VERSION}'.zip'
EXECUTOR_FILE_PATH='https://oss.sonatype.org/service/local/artifact/maven/content?r=releases&g=com.vip.saturn&a=saturn-executor&v='${VERSION}'&e=zip&c=zip'
EXECUTOR_DIR_PATH=${HOME}/executor


function installCentOSDependencies(){
    yum update -y
    yum install -y tar.x86_64 wget maven git
}

function installAlpineDependencies(){
    apk update upgrade 
    apk --update add --no-cache --virtual=.build-dependencies unzip nodejs npm git
    apk --update add --no-cache wget chrony tzdata bash
    if [ "$EXTEND" == "IM" ]; then
        apk --update add imagemagick
    fi
}

function settingUpCentOS(){
    installCentOSDependencies
}

function settingUpAlpine(){
    installAlpineDependencies
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

function settingUpSystemUser(){
    echo "root:123321" | chpasswd
}

function download(){
    cd ${HOME}
    if [ -z "$VERSION" ]; then
        echo 'version error!'
        exit 1099
    else
        echo 'begin download console file in path :'${HOME}', url :'${CONSOLE_FILE_PATH}
        wget -O ${CONSOLE_FILE_NAME} ${CONSOLE_FILE_PATH}

        echo 'begin download executor file in path :'${HOME}', url :'${EXECUTOR_FILE_PATH}
        wget -O ${EXECUTOR_FILE_NAME} ${EXECUTOR_FILE_PATH}

        if [ ! -f "${CONSOLE_FILE_NAME}" ]; then
            echo 'console file :'${CONSOLE_FILE_NAME}' not found!'
            exit 1010
        fi

        if [ ! -f "${EXECUTOR_FILE_NAME}" ]; then
            echo 'executor file :'${EXECUTOR_FILE_NAME}' not found!'
            exit 1010
        fi
    fi
}

function prepareInstall(){
    mkdir -p ${HOME}
    echo 'prepare in path :'${HOME}', console file url :'${CONSOLE_FILE_PATH}
    echo 'prepare in path :'${HOME}', executor file url :'${EXECUTOR_FILE_PATH}
}

function install() {
    cd ${HOME}
    mkdir -p ${EXECUTOR_DIR_PATH}
    mkdir -p ${CONSOLE_DIR_PATH}
    local executorZipFolderName='saturn-executor-'${VERSION}

    mv ${CONSOLE_FILE_NAME} ${CONSOLE_DIR_PATH}
    unzip ${EXECUTOR_FILE_NAME}
    mv ${executorZipFolderName}/* ${EXECUTOR_DIR_PATH}
    rm -fr ${executorZipFolderName}
    rm -fr ${EXECUTOR_FILE_NAME}
}

function prepareConsoleLaunch(){
    chmod +xr ${CONSOLE_DIR_PATH}/${CONSOLE_FILE_NAME}
    echo -e '#!/bin/bash
chronyd
cd '${CONSOLE_DIR_PATH}'
java ${CONSOLE_JAVA_OPTS} -jar '${CONSOLE_FILE_NAME}>/usr/local/bin/launch-console
    chmod +xr /usr/local/bin/launch-console
}

function prepareExecutorLaunch(){
    cd ${EXECUTOR_DIR_PATH}
    chmod +xr saturn-executor*.jar
    chmod +xr ${EXECUTOR_DIR_PATH}/bin/*
    chmod +xr ${EXECUTOR_DIR_PATH}/lib/*
    dos2unix ${EXECUTOR_DIR_PATH}/bin/*.sh
    echo -e '#!/bin/bash
chronyd
cd '${EXECUTOR_DIR_PATH}'
/bin/bash bin/saturn-executor.sh start -n ${EXECUTOR_NAMESPACE} -e ${EXECUTOR_NAME} -env ${EXECUTOR_ENV} -d ${EXECUTOR_LIBDIR} -r ${EXECUTOR_RUNMODE} -jmx ${EXECUTOR_JMXPORT} -sld "${EXECUTOR_LOGDIR}" ${EXECUTOR_JAVAOPTS}' >/usr/local/bin/launch-executor
    chmod +xr /usr/local/bin/launch-executor
}

function createLaunchShell(){
    prepareConsoleLaunch
    prepareExecutorLaunch
}

function installCentOSHandle(){
    prepareInstall
    download
    install
    createLaunchShell
}

function installAlpineHandle(){
    prepareInstall
    download
    install
    createLaunchShell
}

function settingUpCentOSFile(){
    echo "settingUpCentOSFile"
}

function settingUpAlpineFile(){
    echo "settingUpAlpineFile"
}

function clearSystem(){
    rm -fr ${SRC} \
    && rm -fr /root/.m2 \
    && rm -fr /build.sh
}

function cleanCentOS(){
    echo "begin clean centOS system."
    clearSystem
}

function cleanAlpine(){
    echo "begin clean alpine system."
    clearSystem
    apk --update del .build-dependencies
}

function installFromAlpine(){
    settingUpAlpine
    installAlpineHandle
    settingUpAlpineFile
    cleanAlpine
    settingUpSystemUser
}

function installFromCentOS(){
    settingUpCentOS
    installCentOSHandle
    settingUpCentOSFile
    cleanCentOS
    settingUpSystemUser
}

function doAction(){
    if [ -z "$SYSTEM" ]; then
        echo 'system is empty!'
        exit 1004
    fi

    case "$SYSTEM" in
        "alpine")
            echo "begin install by alpine system."
            installFromAlpine
            ;;
        "centos")
            echo "begin install by CentOS system."
            installFromCentOS
            ;;
        *)
            echo "system error,please enter!"
            exit 1005
            ;;
    esac
}

doAction
