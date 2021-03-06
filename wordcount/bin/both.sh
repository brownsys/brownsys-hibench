# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`

echo "========== preparing wordcount data=========="
# configure
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/hibench-config.sh"
. "${DIR}/conf/configure.sh"

# compress check
if [ $COMPRESS -eq 1 ]; then
    COMPRESS_OPT="-D mapred.output.compress=true \
    -D mapred.output.compression.codec=$COMPRESS_CODEC \
    -D mapred.output.compression.type=BLOCK "
else
    COMPRESS_OPT="-D mapred.output.compress=false"
fi


# path check
$HADOOP_EXECUTABLE dfs -rmr $INPUT_HDFS

echo "Total bytes is" $TOTAL_BYTES

# generate data
$HADOOP_EXECUTABLE jar $HADOOP_EXAMPLES_JAR randomtextwriter \
   $COMPRESS_OPT \
   -D mapreduce.randomtextwriter.mapsperhost=0 \
   -D mapreduce.randomtextwriter.totalbytes=$TOTAL_BYTES \
   -D mapred.job.name="hibench.wordcount.preparecontiguous ${TOTAL_BYTES}" \
   $INPUT_HDFS

sleep 5

# path check
$HADOOP_EXECUTABLE dfs -rmr  $OUTPUT_HDFS

# pre-running
SIZE=$($HADOOP_EXECUTABLE job -history $INPUT_HDFS | grep 'org.apache.hadoop.examples.RandomTextWriter$Counters.*|BYTES_WRITTEN')
SIZE=${SIZE##*|}
SIZE=${SIZE//,/}
START_TIME=`timestamp`

# run bench
$HADOOP_EXECUTABLE jar $HADOOP_EXAMPLES_JAR wordcount \
    $COMPRESS_OPT \
    -D mapred.reduce.tasks=${NUM_REDS} \
    -D mapreduce.inputformat.class=org.apache.hadoop.mapreduce.lib.input.SequenceFileInputFormat \
    -D mapreduce.outputformat.class=org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat \
    -D mapred.job.name="hibench.wordcount.run pareto3" \
    $INPUT_HDFS $OUTPUT_HDFS

# post-running
END_TIME=`timestamp`
gen_report "WORDCOUNT" ${START_TIME} ${END_TIME} ${SIZE}
