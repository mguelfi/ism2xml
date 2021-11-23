#!/bin/bash

SAXON=saxon.jar
UUID=`uuidgen`
PYTHON_VERSION=`python3 -V 2>&1`

usage() { echo "Usage: $0 [-o <output folder>] [-i <ism document path>]" 1>&2; }

while getopts "o:i:h" g; do
    case "${g}" in
        i)
            i=${OPTARG}
            ;;
        o)
            o=${OPTARG}
            ;;
        h)
            usage; exit 0
            ;;
        *)
            usage; exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${i}" ] || [ -z "${o}" ]; then
    usage
    exit 2
fi

if [ "${PYTHON_VERSION:7:1}" != "3" ]; then
    echo "python3 is required in your PATH:: ${PYTHON_VERSION}"
    exit 3
fi

TEMP="$(mktemp)" || { echo "Failed to create temp file"; exit 4; }
mkdir -p "${o}" || { echo "Failed to make output folder"; exit 5; }

echo Converting doc to xml...
CATALOG_NAME=`python3 docparse.py -i "${i}" -x "${TEMP}" -o`

echo Making ASCS XML...
java -jar ${SAXON} -s:"${TEMP}" -xsl:ism2acsc.xslt -o:${o}/ISM.xml

echo Making Catalog...
java -jar ${SAXON} -s:"${TEMP}" -xsl:ism2oscal.xslt -o:"${o}/${CATALOG_NAME}" uuid=${UUID}

for CLASS in official protected secret top_secret
do
    echo Making ${CLASS^^} profile...
    java -jar ${SAXON} -s:"${TEMP}" -xsl:ism_oscal_profiles.xsl -o:"${o}/ISM_${CLASS^^}_Profile.xml" uuid=`uuidgen` classification=${CLASS} ism_uuid=${UUID}
done  

echo Making HTML...
java -jar ${SAXON} -s:"${TEMP}" -xsl:oscal_catalog_html.xsl -o:${o}/ISM_Catalog.html

rm "${TEMP}"
