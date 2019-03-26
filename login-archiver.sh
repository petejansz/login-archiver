#!/bin/sh
# ===[ CAS PDDB login-archiver ]===========================================================================
#
# Description: CAS PDDB GMS4.sms_user_login table archiver.
#              CASA-8458, CASA-11201, CASA-11202
#
# Revisions:
#
#   REV     DATE       BY        DESCRIPTION
#   ----  -----------  --------  --------------------------------------------------------------------------
#   1.20  2019-Mar-12   pjansz   Support update statements, export DBNAME=GMS4 (dev dbname)
#   1.13  2019-Feb-20   pjansz   Ren check_run_schedule to is_maint_window, return true|false, don't exit
#   1.12  2019-Feb-19   pjansz   Add better logic handling db2 no-rows-found error and DELETE rows affected
#   1.11  2019-Feb-12   pjansz   Log each SQL script to its own log files.
#   1.10  2018-Nov-13   pjansz   Support archiving other tables.
#   1.01  2018-Jul-18   pjansz   Create DB2 history log file
#   1.00  2018-May-04   pjansz   Initial release.
#   -------------------------------------------------------------------------------------------------------
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
#   -------------------------------------------------------------------------------------------------------
#

if [ -z "$ARCHIVER_HOME" ]; then
  ARCHIVER_HOME=/files/db2/scripts/login-archiver
fi

. $ARCHIVER_HOME/archiver-sh-lib.sh

BASENAME=$(basename $0 | sed "s/\.sh//g")
BASENAME_DB2_SCRIPT=$(basename $DB2_SCRIPT | sed "s/\.sql//g")
LOGFILE="/db2dumps/output_logs/${BASENAME}-${BASENAME_DB2_SCRIPT}.log-$(date +%F)"
HISTORYLOG="/db2dumps/output_logs/${BASENAME}-${BASENAME_DB2_SCRIPT}-history.log"

logit "Login table archiver starting with $DB2_SCRIPT"
logit "LAST_MAINT_HOUR=$LAST_MAINT_HOUR, MAX_ARCHIVE_PASSES=$MAX_ARCHIVE_PASSES"
logit "Logging output to $LOGFILE"
logit "DB2 history: $HISTORYLOG"

if [ ! -e "$DB2_SCRIPT" ]; then
  logit "ERROR: File not found: DB2_SCRIPT $DB2_SCRIPT"
  exit 1
fi

IS_MAINT_WINDOW=$(is_maint_window)
if [[ "${IS_MAINT_WINDOW}" != 'true' ]]; then
  logit "Exiting. Current time hour $(date +%H) >= LAST_MAINT_HOUR=$LAST_MAINT_HOUR"
  exit 0
fi

exit_if_hadr_standby

# Do db work!
db2 "connect to ${DBNAME}"
db2 "set schema ${SCHEMA}"
db2 "set path=sysibm,sysproc,sysfun,${SCHEMA}"
EXIT_CODE=$?

IS_MAINT_WINDOW=true
let ARCHIVE_PASS_COUNT=0
let ROWS_AFFECTED=0
let TOTAL_ROWS_ARCHIVED=0
format_vitals()
{
  STR=$(printf "TOTAL_ROWS_ARCHIVED=%s, ARCHIVE_PASS_COUNT=%s, ROWS_ARCHIVED_THIS_PASS=%s, IS_MAINT_WINDOW=%s, EXIT_CODE=%s" $TOTAL_ROWS_ARCHIVED $ARCHIVE_PASS_COUNT $ROWS_AFFECTED $IS_MAINT_WINDOW $EXIT_CODE)
  echo $STR
}

while [ $EXIT_CODE -eq 0 ]; do

  IS_MAINT_WINDOW=$(is_maint_window)
  if [ "$IS_MAINT_WINDOW" == 'true' ]; then
    let ARCHIVE_PASS_COUNT++
    logit "Archive pass: $ARCHIVE_PASS_COUNT"
    db2 -mstz $LOGFILE -l $HISTORYLOG -vf $DB2_SCRIPT
    DB2_EXIT_CODE=$?

    EXIT_CODE=$(isEmptyTableError $DB2_EXIT_CODE)
    if [[ $? -eq 0 ]]; then
      ROWS_AFFECTED=$(grep -iC 1  -e "^DELETE" -e "^UPDATE" $LOGFILE | tail -3 | grep "rows affected" | tail -1 | cut -d: -f2 | xargs)
      if [ -z "$ROWS_AFFECTED" ]; then
        let ROWS_AFFECTED=0
      fi
    fi

    let TOTAL_ROWS_ARCHIVED=$(( TOTAL_ROWS_ARCHIVED + ROWS_AFFECTED ))
  fi

  VITALS=$(format_vitals)

  if [[ "$IS_MAINT_WINDOW" != 'true' || $EXIT_CODE -ne 0 || $ROWS_AFFECTED -lt 1 || $ARCHIVE_PASS_COUNT -ge $MAX_ARCHIVE_PASSES ]]; then
    logit "Breaking while-loop. ${VITALS}"
    break
  fi

done

VITALS=$(format_vitals)
db2 "disconnect ${DBNAME}"
logit "Disconnected from $DBNAME and ending. ${VITALS}"
exit $EXIT_CODE
