#!/bin/bash

##
## Michal Czerwinski <michal@qubitdigital.com>
## 

set -e -u


name="exhibitor"
package_version="-1"
maintainer="${USER}@${hostname}"
section="misc"
license="Apache Software License 2.0"
description="ZooKeeper co-process for instance monitoring, backup/recovery, cleanup and visualization."
url="https://github.com/Netflix/exhibitor" 
vendor="Netflix"

build() {
    clean
    mkdir dev
    cd dev
    git clone git://github.com/Netflix/exhibitor.git
    mkdir exhibitor-build
    cd exhibitor-build
    cp -rp ../exhibitor/gradle* .
    wget https://raw.github.com/Netflix/exhibitor/master/exhibitor-standalone/src/main/resources/buildscripts/standalone/gradle/build.gradle
    ./gradlew jar
    cd ..
    cd ..
    jarfile=$(find ./dev/exhibitor-build/build/libs/ -type f -name "exhibitor*.jar"|head -n1)
    mkdir -p dev/exhibitor-deb/etc
    mkdir -p dev/exhibitor-deb/etc/exhibitor dev/exhibitor-deb/etc/default dev/exhibitor-deb/etc/default dev/exhibitor-deb/etc/init
    mkdir -p dev/exhibitor-deb/var/log/exhibitor
    mkdir -p dev/exhibitor-deb/usr/lib/exhibitor

    cp exhibitor.default dev/exhibitor-deb/etc/default/exhibitor
    cp exhibitor.init dev/exhibitor-deb/etc/init/exhibitor.conf
    cp log4j.properties dev/exhibitor-deb/etc/exhibitor/
    cp s3.properties dev/exhibitor-deb/etc/exhibitor/
    cp $jarfile dev/exhibitor-deb/usr/lib/exhibitor
    deb $jarfile
}

deb() {
   jarfile=$1
   version=$(echo $jarfile|awk -F "-" '{print $4}'| sed -e 's/.jar//g')
   fpm  -t deb \
        -n ${name} \
        -v ${package_version}${version} \
        --description "${description}" \
        --category ${section} \
        --vendor "${vendor}" \
        --license "${license}" \
        --after-install ./exhibitor.postinst \
        --maintainer "${maintainer}" \
        --url "${url}" \
        --prefix=/ \
        --config-files /etc/exhibitor/s3.properties \
        --config-files /etc/exhibitor/log4j.properties \
        --config-files /etc/default/exhibitor \
        --config-files /etc/init/exhibitor.conf \
        -d sun-java6-jdk \
        -d sun-java6-bin \
        -d sun-java6-jre \
        -s dir \
        -C dev/exhibitor-deb/ etc/ usr/ var/
 
}

clean() {
   rm -rf dev
}

print_usage() {
    echo "Usage: $0 < build | clean >"
    exit 1
}

if [ "$#" -lt 1 ]; then
    print_usage
else
    case "$1" in
        clean )
            clean ;;
        build )
            build ;;
             *)
            print_usage ;;
    esac
fi
