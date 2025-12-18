#!/bin/bash
# To make it work 
#
# Add host to the tower inventories
# Add vip to the inventories 
# Add vip to firewall rules

host=$1
par_file=$2
vip=$3

if [[ -z "$host" || -z "$par_file" ]];then 
  echo ""
  echo " USAGE       : install_oracle_server_prd.sh [host] [par_file] [vip]"
  echo ""
  echo " SYNOPSYS    : Install OFA, Last  version oracle inaries, create database"
  echo "" 
  echo "" PARAMETERS : 
  echo "              host       = the target host where the database will be installed- MANDATORY"
  echo "              par_file   = parameter file to be used. See examples in vars/create_db_omf*.yml. MANDATORY" 
  echo "              vip        = the vip where oracle grid control agent will be installed. OPTIONEL"
  echo "                           If vip not specified grid conrol will be skipped"
  echo ""
  echo " EXAMPLE: "
  echo "             install_oracle_server_prd.sh lxvgvacfcev202p tmp/vars/create_db_omf_cfcprd.yml cfcprd-vip"
  echo ""
  exit 1
fi


if [[ ! -z "$vip" ]]; then 
  echo "WARNING: vip not specified. Grid control agent installation wll be skipped"
fi

echo "All good"

./execute_tower_job.sh -j PRD_Ofa_Install_Oracle -t $host
if [ $? -ne 0 ]; then 
  echo "Install OFA failed. STOP"
  exit 1
fi

../execute_tower_job.sh -j PRD_Oracle_Create_Database_OMF_single_multi  -f $par_file -t $host
if [ $? -ne 0 ]; then 
  echo "Create database failed. STOP"
  exit 1
fi

if [[ ! -z "$vip" ]]; then 
  ./execute_tower_job.sh -j  PRD_Grid_control_Agent_Install_VIP_Standalone -l $vip
  if [ $? -ne 0 ]; then 
    echo "Install grid failed. STOP"
    exit 1
  fi
fi

echo "OFA, DB and Grid are sucesfull installed"
echo ""
exit 0
