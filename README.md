Author : Ashwini Dubey

Publish Date : 29 Aug 2021

Objective : This respository contains the following scripts files - automation.sh
	
Purpose :

	1. automation.sh : This script is being used to perform following functions :
		a. Update the package details
		b. Installation of apache2 package
		c. Start/Restart the apache2 service
		d. Create a tar archive of apache2 log files present in /var/log/apache2/ directory.
		e. Move the tar archive of apache2 log files from /var/log/apache2/ directory to /tmp/ directory.
		f. Upload the tar archive of apache2 log files to the AWS S3 Bucket.
		g. Create an inventory file , to keep track of the files being archived in tar fromat & copied to S3 Bucket
		h. Cron Job Scheduler to run the script at 00:00 Hours.
		
