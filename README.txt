CA Player Direct PD DB Login Table Archiver

Description: CAS PDDB GMS4.sms_user_login table archiver.
             CASA-8458, CASA-11201, CASA-11202
              Copy records from GMS4.sms_user_login to GMS4.sms_user_login_archive
              Delete copied records from GMS4.sms_user_login
			  
The following scripts are deployed to "${caXXXdb2cdbN}:/files/db2/scripts/login-archiver/
Scripts:
	1. login-archiver.sh
    2. archiver-sh-lib.sh
	3. login-archiver.db2

The login-archiver.sh supports the following usage/options:

    USAGE: login-archiver.sh [options]
      options
      -d | --db2-script filename (default=/files/db2/scripts/login-archiver/login-archiver.db2)
      -l | --last-maint-hr num (default=6 America/Los_Angeles)
      -m | --max-archive-passes num (default=200)
      -q | --quiet

The script does the following:
    - Initializes the logfile
    - Confirms the db2-script exists
    - checks if it should continue running based on Los_Angeles TZ, current hour and last-maint-hr
    - Checks if HADR enabled and it's role is NOT "Standby"
    - Connect to DB 
    - Performs archiving until 
        - non-zero exit code 
        - or zero rows affected 
        - or archive-pass-count >= max-archive-passes
    - Disconnect from DB
    
The DB2 script, SELECT from driving query is throttled with
	FETCH first 10000 rows only.
	
The CA PDDB/GMS4 database user crontab should be configured to invoke the sh script at
the beginnig of the CA maintenance window 02:00 Los_Angeles, e.g.,
The sh script runs on the PD DB host, sets the env, dot-include of gtkinst1’s .bashrc, initializes logfile and invokes DB2 on the db2 script file to copy login records to the new archive table then delete records that were archived.
A crontab entry looks as follows:
	0 2 * * * /files/db2/scripts/login-archiver/login-archiver.sh

The archiver produces logfile, /db2dumps/output_logs/login-archiver.YYYY-MM-DD, e.g., 

/db2dumps/output_logs/login-archiver.2018-04-23
     1  Login table archiver starting 2018-04-23, using /files/db2/scripts/login-archive/login-archiver.db2
     2  insert into GMS4.sms_user_login_archive select login_id , physical_customer_data_id , contract_identity , contract_type_id , key_access_value , key_access_type_id , ext_system_id , login_date , logout_date , ip_address , provider_id , login_type_id , api_key, device_id, current date from GMS4.sms_user_login where (   -- real people:
     3   login_date < ( current date - 36 months ) and key_access_value NOT in ( 'calottomobileadm@gmail.com', 'nota2ndchancewinner@gmail.com', 'cslmobile1@gmail.com', 'thirtyplus@calottery.com', 'dca_ren_staff@gtech.com' ) ) or (   -- automated monitor accounts:
     4   login_date < ( current date - 7 days ) and key_access_value in ( 'calottomobileadm@gmail.com', 'nota2ndchancewinner@gmail.com', 'cslmobile1@gmail.com', 'thirtyplus@calottery.com', 'dca_ren_staff@gtech.com' ) ) FETCH first 10 rows only
     5    Number of rows affected : 10
     6  DB20000I  The SQL command completed successfully.

     7  commit
     8  DB20000I  The SQL command completed successfully.

     9  delete GMS4.sms_user_login where login_id in (select login_id from GMS4.sms_user_login_archive where archive_date = current date)
    10    Number of rows affected : 10
    11  DB20000I  The SQL command completed successfully.

    12  commit
    13  DB20000I  The SQL command completed successfully.

	