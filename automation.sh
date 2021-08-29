#!/bin/bash
#-----------------------------------------------------------------------------------------------------------------------------
#  Purpose of this script is to install the apache2 package and create a tar archive of apache2 access & error logs.
# .log files present in the /var/log/apache2/ directory will be compressed to .tar format.
# .tar files compressed from .log files will be uploaded to S3 bucket.
#------------------------------------------------------------------------------------------------------------------------------

#Setting the s3 bucket details
MY_NAME="Ashwini"
S3_BUCKET="upgrad-ashwini"

#Updating the package details
echo  "Updating the package details"
sudo apt-get update -y

#Setting up  the AWS CLI
echo "Setting up the AWS CLI"
cd /root

if [ ! -e /usr/local/bin/aws ]
then
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        apt-get install unzip
        unzip awscliv2.zip
        sudo ./aws/install
else
        echo "AWS CLI setup alredy exists"
fi


#Checking if the apache2 package is already installed or not , if not install it.
echo "Checking if the apache2 package is already installed or not , if not install it"
pkg="apache2"
which $pkg > /dev/null 2>&1
if [[ $? == 0 ]];
then
        echo "apache2 already installed"
else
        sudo apt-get install apache2 -y
        if [[ $? == 0 ]];
        then
                echo "apache2 installed successfully"
        else
                echo "apache2 installation failed"
        fi
fi

#Checking if the apache2 service is enabled or not.
apache2_status=$(service apache2 status)
if [[ $apache2_status != *"active (running)"* ]];
then
        echo "Starting the apache2 server"
        sudo /etc/init.d/apache2 start
        echo "apache2 server has started"
else
        echo "apache2 server is running"
fi

#Navigating to /var/log/apache2/ directory for the logs
echo "Changing the directory from current directory to /var/log/apache2/ directory"
cd /var/log/apache2/

#Creating the tar file of *.log files
echo  "Creating tar file of all the .log files"
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
FILENAME="httpd-logs"
sudo tar -cvf "$MY_NAME-$FILENAME-$TIMESTAMP".tar *.log

#Moving the .tar file from /var/log/apache2/ directory to /tmp/ directory
echo "Moving the .tar file from the current directory to /tmp/ directory"
sudo mv *.tar /tmp/
cd /tmp

#Check if inventory.html file exists in /var/www/html else create it.

echo "#Check if inventory.html file exists in /var/www/html else create it."
COUNT=$(ls *.tar | grep $TIMESTAMP | wc -l)
FILE=$(ls *.tar | grep $TIMESTAMP | tail -n 1 )
FILE_SIZE=$(ls -lh $FILE | awk '{print $5}')
FILE_EXTENSION="tar"

cd /var/www/html
if [ ! -e /var/www/html/inventory.html ]
then
        echo "File doesn't exist"
        touch /var/www/html/inventory.html
        ls
        cat <<EOF > /var/www/html/inventory.html
        <!DOCTYPE html>
        <html style="text-align:center;">
        <head>
        <title>Inventory Details</title>
        <h1><b><i>Inventory Details of tar files uploaded into s3</i></b></h1>
        <style>
        table,td {
                border: 1px solid black;
                border-collapse: collapse;
        }
        td{
                                width: 25%;
                font-weight: bold;
        }
        table{
                                width:100%;
        }
        </style>
        </head>
        <body>
        <table>
        <tr>
        <td>Log Type</td>
        <td>Date Created</td>
        <td>Type</td>
        <td>Size</td>
        </tr>
        </table>
EOF
fi

#Copying the .tar files from /tmp/ directory to S3 bucket
aws s3 \
cp /tmp/${MY_NAME}-${FILENAME}-${TIMESTAMP}.tar \
s3://${S3_BUCKET}/${MY_NAME}-${FILENAME}-${TIMESTAMP}.tar

#Appending the inventory file with the details of files being converted to tar archive and copied to s3
aws s3 ls s3://${S3_BUCKET}

aws_file_count=$(aws s3 ls s3://${S3_BUCKET}/${MY_NAME}-${FILENAME}-${TIMESTAMP}.tar | wc -l)
if [ ${aws_file_count} -gt 0 ]
then
        cat <<EOF >> /var/www/html/inventory.html
        <table>
        <tr>
        <td>$FILENAME</td>
        <td>$TIMESTAMP</td>
        <td>$FILE_EXTENSION</td>
        <td>$FILE_SIZE</td>
        </tr>
        </table>
EOF
fi

#Cron Job Setup , to run the automation.sh script daily at00:00
cd /etc/cron.d
sudo touch /etc/cron.d/automation
sudo echo "SHELL=/bin/bash" > /etc/cron.d/automation
sudo echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /etc/cron.d/automation
sudo echo "0 0 * * * root /root/Automation_Project/automation.sh > /root/Automation_Project/cron_log.log" > /etc/cron.d/automation
