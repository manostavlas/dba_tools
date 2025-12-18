
# Set environment to use awx toolkit

## Build Virtual env 
## --------------------------------
```
cd $HOME
mkdir projects 
cd projects
/appli/alm/venv/ansible-navigator/bin/python3.11 -m venv venv

# check that the pip.conf is correct configured and create it if not exist as follows
mkdir -p $HOME/.config/pip

cat $HOME/.config/pip/pip.conf
[global]
index-url = https://almbinaryrepo.corp.ubp.ch/api/pypi/ubp-python-prd/simple

[distutils]
index-servers = local

[local]
repository: https://almbinaryrepo.corp.ubp.ch/artifactory/api/pypi/ubp-python-dev-local

# install the awx toolkit
pip install --upgrade awxkit

# set the vrtual env 
. $HOME/projects/venv/activate 

# export the env variables for ansible tower
export CONTROLLER_HOST=https://tower-{evx|evz|prd}.corp.ubp.ch
export CONTROLLER_USERNAME=<tower_username>
export CONTROLLER_VERIFY_SSL=false
export CONTROLLER_PASSWORD=<tower_password>
```


## Examples:
## ----------------------------------------------------------------------------------------------------
```
awx job_templates list -f human --all
awx job_templates launch  --limit lxsgvatbrprd01p --extra_vars @vars/sanity_check_fs.yml 16385 | jq .job
```

# Create database Old way example 
## Install OFA 
`./execute_tower_job.sh -j PRD_Ofa_Install_Oracle -t lxvgvaasdprd02p`
## Install Oracle binaries
`./execute_tower_job.sh -j  PRD_Oracle_Database_Server_Install -f vars/install_oracle_bin.yml -t lxvgvaasdprd02p`
## Create database
