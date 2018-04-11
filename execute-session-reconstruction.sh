#!/bin/bash

BASE=$(cd "$(dirname "$0")"; pwd)

export RECONSTRUCTOR_OPTS="-Xmx3g -Xms1g -Dlog4j.configuration=file://$BASE/log4j.cfg"

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

if [ ! -d $DATA ] ; then
	echo "Data directory missing: ${DATA}"
	exit 1
fi
if [ ! -d $FIXED ] ; then
	echo "Fixed data directory missing: ${FIXED}"
	exit 1
fi

rm -rf $FIXED/*

for KIEKER in `ls $DATA` ; do

cat << EOF > reconstructor.config
## The name of the Kieker instance.
kieker.monitoring.name=jira
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

iobserve.service.reader=org.iobserve.service.source.FileSourceCompositeStage
org.iobserve.service.source.FileSourceCompositeStage.sourceDirectories=$DATA/$KIEKER

#####
kieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter
kieker.monitoring.writer.filesystem.FileWriter.customStoragePath=$FIXED
kieker.monitoring.writer.filesystem.FileWriter.charsetName=UTF-8
kieker.monitoring.writer.filesystem.FileWriter.maxEntriesInFile=25000
kieker.monitoring.writer.filesystem.FileWriter.maxLogSize=-1
kieker.monitoring.writer.filesystem.FileWriter.maxLogFiles=-1
kieker.monitoring.writer.filesystem.FileWriter.mapFileHandler=kieker.monitoring.writer.filesystem.TextMapFileHandler
kieker.monitoring.writer.filesystem.TextMapFileHandler.flush=true
kieker.monitoring.writer.filesystem.TextMapFileHandler.compression=kieker.monitoring.writer.filesystem.compression.NoneCompressionFilter
kieker.monitoring.writer.filesystem.FileWriter.logFilePoolHandler=kieker.monitoring.writer.filesystem.RotatingLogFilePoolHandler
kieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.BinaryLogStreamHandler
kieker.monitoring.writer.filesystem.FileWriter.flush=true
kieker.monitoring.writer.filesystem.FileWriter.bufferSize=8192000
kieker.monitoring.writer.filesystem.FileWriter.compression=kieker.monitoring.writer.filesystem.compression.NoneCompressionFilter
EOF

$RECONSTRUCTOR -c reconstructor.config

done

# end
