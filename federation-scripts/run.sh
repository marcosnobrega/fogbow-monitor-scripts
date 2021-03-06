#!/bin/bash
echo "....................................."
echo "Starting script. "
echo "....................................."

# Importing scripts
DIRNAME=`dirname $0`
source "$DIRNAME/settings.sh"
source "$DIRNAME/database.sh"
source "$DIRNAME/run-utils.sh"
source "$DIRNAME/token-plugins/token-util.sh"
source "$DIRNAME/cachet/cachet.sh"
source "$DIRNAME/test-compute.sh"
source "$DIRNAME/test-storage.sh"
source "$DIRNAME/test-network.sh"

EXECUTION_UUID=`uuidgen`
echo "** Properties **"
echo "- Execution id: "$EXECUTION_UUID
echo "- Token plugin: "$TOKEN_PLUGIN
echo "** End Properties ** "

# From token-util.sh
MANAGER_TOKEN=$(getToken)
echo "Manager token: "$MANAGER_TOKEN

## logs
echo "Creating logs folder."
LOGS_PATH="$DIRNAME/logs/$EXECUTION_UUID"
mkdir $LOGS_PATH
LOG_MONITORING_COMPUTE_PATH_PREFIX="$LOGS_PATH/monitoringCompute-"
LOG_MONITORING_NETWORK_PATH_PREFIX="$LOGS_PATH/monitoringNetwork-"
LOG_MONITORING_STORAGE_PATH_PREFIX="$LOGS_PATH/monitoringStorage-"
echo "Logs path : "$LOGS_PATH

echo "** Starting garbageCollector. **"
execGarbageCollector > "$LOGS_PATH/garbageCollector.log"

echo "** Starting monitoring. **"
for i in `cat $MANAGERS_TO_MONITOR`; do
	if [[ "$i" == *"manager"* ]]; then
		eval `echo $i`;
		echo "Running tests on manager $manager"
		createCachetGroupComponent $manager
	else
		if [[ "$i" == "compute" ]]; then
			echo "COMPUTE: Running tests for $i on $manager"
			createCachetComponent $MANAGER $CONST_COMPUTE_PREFIX
			monitoringCompute $manager >> "$LOG_MONITORING_COMPUTE_PATH_PREFIX"$manager".log" &

		elif [[ "$i" == "storage" ]]; then
			echo "STORAGE: Running tests for $i on $manager"
			monitoringStorage $manager >> "$LOG_MONITORING_STORAGE_PATH_PREFIX"$manager".log" &
			createCachetComponent $MANAGER $CONST_STORAGE_PREFIX
			
		elif [[ "$i" == "network" ]]; then
			echo "NETWORK: Running tests for $i on $manager"
			monitoringNetwork $manager >> "$LOG_MONITORING_NETWORK_PATH_PREFIX"$manager".log" &
			createCachetComponent $MANAGER $CONST_NETWORK_PREFIX
			
		fi
	fi
done

if [ $GARBAGE_COLLECTOR_END_SCRIPT ]; then
	DATE=`date`
	echo "$DATE - Waiting $TIME_TO_START_GARBAGE_COLLECTOR_END_SCRIPT seconts to start garbageCollector again."
	sleep $TIME_TO_START_GARBAGE_COLLECTOR_END_SCRIPT
	echo "$DATE - Starting garbageCollector."
	execGarbageCollector > "$LOGS_PATH/garbageCollectorEnd.log"
fi

echo "....................................."
echo "End main script."
echo "Wait others scripts (monitoringCompute, monitoringStorage and monitoringNetwork. "
echo "Check logs in $LOGS_PATH."
echo "....................................."