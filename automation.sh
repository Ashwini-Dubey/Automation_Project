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
echo  "[LOG] Updating the package details"
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
echo "[LOG] Checking if the apache2 package is already installed or not , if not install it"
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

#Copying the .tar files from /tmp/ directory to S3 bucket
aws s3 \
cp /tmp/${MY_NAME}-${FILENAME}-${TIMESTAMP}.tar \
s3://${S3_BUCKET}/${MY_NAME}-${FILENAME}-${TIMESTAMP}.tar
