#!/bin/sh
# ===[ CAS PDDB login-archiver ]===========================================
#
# Description: CAS PDDB GMS4.sms_user_login table archiver.
#              CASA-8458, CASA-11201, CASA-11202
#
# Revisions:
#
#   REV     DATE       BY        DESCRIPTION
#   ----  -----------  --------  ------------------------------------------
#   1.00  2018-May-04   pjansz   Initial release.
#   -----------------------------------------------------------------------
#     This item is the property of GTECH Corporation, Providence,
#     Rhode Island, and contains confidential and trade secret information.
#     It may not be transferred from the custody or control of GTECH except
#     as authorized in writing by an officer of GTECH.  Neither this item
#     nor the information it contains may be used, transferred, reproduced,
#     published, or disclosed, in whole or in part, and directly or
#     indirectly, except as expressly authorized by an officer of GTECH,
#     pursuant to written agreement.
#
#     Copyright (c) 2018 GTECH Corporation.  All rights reserved.
#   -----------------------------------------------------------------------
# Check usage.
#

ARCHIVER_HOME=/files/db2/scripts/login-archiver
. $ARCHIVER_HOME/archiver-sh-lib.sh
. /files/db2/gtkinst1/.bashrc

LOGFILE=$(basename $0| sed "s/\.sh//g")
LOGFILE="/db2dumps/output_logs/${LOGFILE}.log-$(date +%F)" 

logit "Login table archiver starting with $DB2_SCRIPT" 
logit "Logging output to $LOGFILE"

if [ ! -e "$DB2_SCRIPT" ]; then
  logit "ERROR: File not found: DB2_SCRIPT $DB2_SCRIPT" 
  exit 1
fi

check_run_schedule

# Check to see if HADR is being run on the system
HADR_ENABLED=$(db2 get snapshot for database on ${DBNAME} | grep -A0 'HADR Status' | cut -c1-11)

if [[ "${HADR_ENABLED}" = "HADR Status" ]]; then
   HADR_ROLE=$(db2 get snapshot for database on ${DBNAME} | grep -A15 'HADR Status' | grep Role | cut -d= -f2 | cut -c2-)

   if [[ "${HADR_ROLE}" = "Standby" ]]; then
      logit "ERROR: Login table archive process cannot be performed on HADR standby server" 
      exit 1
   fi
fi

# Do db work!
db2 "connect to ${DBNAME}" 
db2 "set schema ${SCHEMA}"
db2 "set path=sysibm,sysproc,sysfun,${SCHEMA}" 
EXIT_CODE=$?
let ARCHIVE_PASS_COUNT=0

while [ $EXIT_CODE -eq 0 ]; do
 
  check_run_schedule
  let ARCHIVE_PASS_COUNT++
  logit "Archive pass: $ARCHIVE_PASS_COUNT"
  db2 -mstz $LOGFILE -vf $DB2_SCRIPT
  EXIT_CODE=$?
  ROWS_AFFECTED=$(grep "rows affected" $LOGFILE | tail -1 | cut -d: -f2 | xargs)

  if [ $EXIT_CODE -ne 0 ] || [ ! "$ROWS_AFFECTED" -gt 0 ] || [ $ARCHIVE_PASS_COUNT -ge $MAX_ARCHIVE_PASSES ]; then
    logit "Breaking while-loop EXIT_CODE=$EXIT_CODE, ROWS_AFFECTED=$ROWS_AFFECTED, ARCHIVE_PASS_COUNT=$ARCHIVE_PASS_COUNT"
    break
  fi
  sleep 1  # Don't be a hog.
done

db2 "disconnect ${DBNAME}"
logit "Disconnected from $DBNAME and ending."
