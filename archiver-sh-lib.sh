# ===[ CAS PDDB login-archiver sh lib ]=====================================
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
#

if [ -z "$DBNAME" ]; then
  DBNAME=PDDB
fi
SCHEMA=GMS4
DB2_SCRIPT=
export TZ='America/Los_Angeles'
QUIET=false
HELP=false
let LAST_MAINT_HOUR=6
let MAX_ARCHIVE_PASSES=200

help()
{
  echo "USAGE: $(basename $0) [options] -d | --db2-script filename"
  echo "  options"
  echo "  -l | --last-maint-hr num (default=${LAST_MAINT_HOUR} ${TZ})"
  echo "  -m | --max-archive-passes num (default=${MAX_ARCHIVE_PASSES})"
  echo "  -q | --quiet"
}

logit()
{
  MSG=$1
  LOG_MSG="$(date +%F:%T) $(basename $0): ${MSG}" 

  if [ "$QUIET" != 'true' ]; then
    echo "${LOG_MSG}"
  fi

  echo "${LOG_MSG}" >> $LOGFILE
}

# Check to see if HADR is being run on the system
exit_if_hadr_standby()
{
  HADR_ENABLED=$(db2 get snapshot for database on ${DBNAME} | grep -A0 'HADR Status' | cut -c1-11)
  if [[ "${HADR_ENABLED}" = "HADR Status" ]]; then
    HADR_ROLE=$(db2 get snapshot for database on ${DBNAME} | grep -A15 'HADR Status' | grep Role | cut -d= -f2 | cut -c2-)
    if [[ "${HADR_ROLE}" = "Standby" ]]; then
      logit "ERROR: Archive process cannot be run on HADR standby server"
      exit 1
    fi
  fi
}

is_maint_window() # 'true' if in maint window else return 'false'
{
  CUR_HOUR=$(date +%H)
  IS=true
  if [ "$CUR_HOUR" -ge "$LAST_MAINT_HOUR" ]; then
    IS=false
  fi

  echo $IS
}

# If $1, error code != 0 and SQL0100W in logfile, then we had an empty table error, which is ok
# so return 0 else some other error, return the input error code.
isEmptyTableError() # args : exitCode
{
  db2ExitCode=$1
  exitCode=0
  if [[ $db2ExitCode != 0 ]]; then
    EMPTY_TABLE=$(grep -c SQL0100W $LOGFILE)

    if [[ "$EMPTY_TABLE" -gt 0 ]]; then
      exitCode=0
    else
      exitCode=$db2ExitCode
    fi

  fi

  echo $exitCode
}

# options parser:
OPTS=$(getopt -o d:hql:m: --long quiet,db2-script:,last-maint-hr:,help,max-archive-passes: -n 'parse-options' -- "$@")
if [ $? != 0 ]; then 
  echo "Failed parsing options." >&2 
  exit 1 
fi
eval set -- "$OPTS"

while true; do
  case "$1" in
    -d | --db2-script )         DB2_SCRIPT="$2"; shift; shift ;;
    -h | --help )               HELP=true; shift ;;
    -q | --quiet )              QUIET=true; shift  ;; 
    -l | --last-maint-hr )      LAST_MAINT_HOUR="$2"; shift; shift ;;
    -m | --max-archive-passes ) MAX_ARCHIVE_PASSES="$2"; shift; shift ;;
    -- ) shift; break ;;
     * ) break ;;
  esac
done

if [[ "$HELP" == 'true' || -z "$DB2_SCRIPT" ]]; then
  help
  exit 1
fi

