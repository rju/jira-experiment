#!/bin/bash

# configuration

BASE=$(cd "$(dirname "$0")"; pwd)

ANALYSIS_OPTS="-Xmx6g -Xms2g -Dlog4j.configuration=file:///home/reiner/Projects/iObserve/experiments/jira-experiment/log4j.cfg"

# internal data
CLUSTERINGS[0]=xmeans
CLUSTERINGS[1]=em
CLUSTERINGS[2]=hierarchy
CLUSTERINGS[3]=similarity

if [ -f $BASE/config ] ; then
	. $BASE/config
else
	echo "Missing configuration"
	exit 1
fi

mode=""
for C in ${CLUSTERINGS[*]} ; do
	if [ "$C" == "$1" ] ; then
		mode="$C"
	fi
done

if [ "$mode" == "" ] ; then
	echo "Unknown mode $1"
	exit 1
fi

if [ ! -x $ANALYSIS ] ; then
	echo "Missing analysis cli"
	exit 1
fi
if [ ! -d $DATA ] ; then
	echo "Data directory missing"
	exit 1
fi
if [ ! -d $FIXED ] ; then
	echo "Fixed data directory missing"
	exit 1
fi
if [ ! -d $PCM ] ; then
	echo "PCM directory missing"
	exit 1
fi
if [ ! -d "$RESULTS" ] ; then
	mkdir "$RESULTS"
fi

# compute setup
if [ -f $FIXED/kieker.map ] ; then
	KIEKER_DIRECTORIES=$FIXED
else
	KIEKER_DIRECTORIES=""
	for D in `ls $FIXED` ; do
		if [ "$KIEKER_DIRECTORIES" == "" ] ;then
			KIEKER_DIRECTORIES="$FIXED/$D"
		else
			KIEKER_DIRECTORIES="$KIEKER_DIRECTORIES:$FIXED/$D"
		fi
	done
fi


# assemble analysis config
cat << EOF > analysis.config
## The name of the Kieker instance.
kieker.monitoring.name=JIRA
kieker.monitoring.hostname=
kieker.monitoring.metadata=true

iobserve.analysis.source=org.iobserve.service.source.FileSourceCompositeStage
org.iobserve.service.source.FileSourceCompositeStage.sourceDirectories=$KIEKER_DIRECTORIES

iobserve.analysis.traces=true
iobserve.analysis.dataFlow=true

iobserve.analysis.model.pcm.directory.db=$DB
iobserve.analysis.model.pcm.directory.init=$PCM

# trace preparation (note they should be fixed)
iobserve.analysis.behavior.IEntryCallTraceMatcher=org.iobserve.analysis.systems.jira.JIRACallTraceMatcher
iobserve.analysis.behavior.IEntryCallAcceptanceMatcher=org.iobserve.analysis.systems.jira.JIRATraceAcceptanceMatcher
iobserve.analysis.behavior.ITraceSignatureCleanupRewriter=org.iobserve.analysis.systems.jira.JIRASignatureCleanupRewriter
iobserve.analysis.behavior.IModelGenerationFilterFactory=org.iobserve.analysis.systems.jpetstore.JPetStoreEntryCallRulesFactory

iobserve.analysis.behavior.triggerInterval=1000

iobserve.analysis.behavior.sink.baseUrl=$RESULTS
iobserve.analysis.container.management.sink.visualizationUrl=http://localhost:8080
EOF

case "$mode" in
"${CLUSTERINGS[0]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behaviour.filter=org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.expectedUserGroups=1
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.variance=1
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.prefix=jira
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.outputUrl=$RESULTS
org.iobserve.analysis.clustering.xmeans.XMeansBehaviorCompositeStage.representativeStrategy=org.iobserve.analysis.systems.jira.JIRARepresentativeStrategy
EOF
;;
"${CLUSTERINGS[1]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behaviour.filter=org.iobserve.analysis.clustering.em.EMBehaviorCompositeStage
org.iobserve.analysis.clustering.xmeans.EMBehaviorCompositeStage.prefix=jira
org.iobserve.analysis.clustering.xmeans.EMBehaviorCompositeStage.outputUrl=$RESULTS
org.iobserve.analysis.clustering.xmeans.EMBehaviorCompositeStage.representativeStrategy=org.iobserve.analysis.systems.jira.JIRARepresentativeStrategy
EOF
;;
"${CLUSTERINGS[2]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behaviour.filter=org.iobserve.analysis.clustering.hierarchy.BehaviorCompositeStage
EOF
;;
"${CLUSTERINGS[3]}")
cat << EOF >> analysis.config
# specific setup similarity matching
iobserve.analysis.behaviour.filter=org.iobserve.analysis.behavior.clustering.similaritymatching.BehaviorCompositeStage
iobserve.analysis.behavior.IClassificationStage=org.iobserve.analysis.behavior.clustering.similaritymatching.SimilarityMatchingStage
iobserve.analysis.behavior.sm.IParameterMetric=org.iobserve.analysis.systems.jira.JIRAParameterMetric
iobserve.analysis.behavior.sm.IStructureMetricStrategy=org.iobserve.analysis.behavior.clustering.similaritymatching.GeneralStructureMetric
iobserve.analysis.behavior.sm.IModelGenerationStrategy=org.iobserve.analysis.behavior.clustering.similaritymatching.UnionModelGenerationStrategy
iobserve.analysis.behavior.sm.parameters.radius=2
iobserve.analysis.behavior.sm.structure.radius=2
EOF
;;
esac

# run analysis
echo "------------------------"
echo "Run analysis"
echo "------------------------"

$ANALYSIS -c analysis.config

# end
