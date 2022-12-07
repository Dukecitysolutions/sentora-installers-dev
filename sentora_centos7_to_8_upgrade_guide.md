# Sentora CentOs 7 to 8 upgrade Guide

### Login to server directly or thur SSH as ROOT. SUDO will not work!!!
### Run the following commands below to start OS upgrade and follow the instructions step-by-step.

# yum install epel-release -y
# yum install yum-utils
# yum install rpmconf
# rpmconf -a

# package-cleanup --leaves
# package-cleanup --orphans

### COMING SOON!!!
