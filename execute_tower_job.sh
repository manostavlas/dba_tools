#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color (reset)

function usage {
  echo ""
  echo " Usage:                 execute_tower_job.sh [-h] [-j job_template_name] [-t limit ] [-f extra_vars_file] [-l]"
  echo ""
  echo " SYNOPSYS:              Execute a job template defined in the ANSIBLE TOWER"
  echo ""
  echo ""
  echo " ENVIONEMENT:"
  echo "                        These env variables must be defined:"
  echo "                           export CONTROLLER_HOST=<https://tower-{evx|evz|prd}.corp.ubp.ch"
  echo "                           export CONTROLLER_USERNAME=<tower_username>"
  echo "                           export CONTROLLER_PASSWORD=<tower_password>"
  echo "" 
  echo " OPTIONS:"
  echo " -h                     This help"
  echo ""
  echo " -j                     The tower job template. Use -l to get the complete list of job templates."
  echo ""
  echo " -t                     The limit target host. This is mandatory."
  echo ""
  echo " -f                     The extra vars yaml file"
  echo "" 
  echo " -l                     List all templates"
  echo ""
  echo ""
  echo ""
  echo " EXAMPLE:"               
  echo ""
  echo "                        List all jobs "
  echo "                          execute_tower_job.sh -l "
  echo ""
  echo "                        Execute the job template EVX_Ofa_Install_Oracle  on all lxsgvatapevx1\*p hosts  "
  echo "                          execute_tower_job.sh -j EVX_Ofa_Install_Oracle  -t lxsgvatapevx1\*p"
  echo ""
  echo "                        Execute the job EVX_Oracle_Sanity_check_fs_almost_full on host lxvgvaoraev104p using parameters defined in vars/sanity_check_fs.yml file"
  echo "                          execute_tower_job.sh -j EVX_Oracle_Sanity_check_fs_almost_full -f vars/sanity_check_fs.yml -t lxvgvaoraev104p" 
  echo ""
  exit 1
}



function exec_job_template {
  local tower_template=$1
  local tower_limit=$2
  local var_file=$3

  extra_var_opt=""
  if [ "$var_file" != "" ]; then
    extra_var_opt="--extra_vars @$var_file"
  fi

  local template_id=0

  # get job_id
  echo ""
  echo -e "Get the template_id for the job ${GREEN}$tower_template${NC}"
  template_id=$(awx job_templates list --all | jq -r '.results[] | select(.name == "'$tower_template'") | .id')
  if [ -z "${template_id}" ] || [ "$template_id" -eq 0 ]; then
    echo -e "Cannot the id for ${GREEN}$tower_template${NC}. ${RED}STOP${NC}"
    echo ""
    exit 1
  fi

  # execute job and get the job_id
  echo -e "Execute the job ${GREEN}$tower_template${NC}. Template id: ${BLUE}${template_id}${NC}"
  local job_id=0
  echo -e "Execute command: ${BLUE}awx job_templates launch --limit $tower_limit $extra_var_opt $template_id${NC}"
  job_id=$(awx job_templates launch  --limit $tower_limit $extra_var_opt  $template_id | jq .job)
  echo -e "To get the real time log: ${BLUE}awx jobs monitor $job_id${NC}"
  if [ -z "$job_id" ] || [ "$job_id" -eq 0 ]; then
    echo -e "Cannot start the template ${GREEN}$tower_template${NC}. ${RED}STOP${NC}"
    echo ""
    exit 1
  fi

  local job_status="NA"
  local count=0
  while [[ "$job_status" != "successful" && "$job_status" != "failed" ]];do
    job_status=$(awx jobs get $job_id | jq '.status')
    job_status=$(echo "$job_status" | sed 's/[\" ]//g')
    case $job_status in
      "running")
        echo -ne "Job running since ... ${GREEN}${count}${NC} secondes. Status: ${GREEN}${job_status}${NC} \r"
        ;;
      "failed")
        echo -ne "Job running since ... ${GREEN}${count}${NC} secondes. Status: ${RED}${job_status}${NC} \r"
        ;;
      *)
        echo -ne "Job running since ... ${GREEN}${count}${NC} secondes. Status: ${YELLOW}${job_status}${NC} \r"
        ;;
    esac
    sleep 1
    ((count++))
  done

  awx jobs get $job_id  | jq -r '"Started: \(.started)         Finished: \(.finished)       Elapsed: \(.elapsed)"'
  echo -e "Job ${GREEN}$tower_template${NC}: ${BLUE}$job_id${NC} status is $job_status"
  echo -e "To get the job output use the command: ${BLUE}awx jobs stdout $job_id${NC} "
  echo ""
  if [ "$job_status" != "successful" ]; then 
    exit 1
  fi
}

function list_templates {
   awx job_templates list --all |  jq -r '.results[] | "\(.id) \(.name)"'
   exit 0
}


extra_var_file=""

if [ -z "$CONTROLLER_HOST" ]; then 
  echo ""
  echo -e "Environment is not set. Set variables CONTROLLER_HOST, CONTROLLER_USERNAME, CONTROLLER_PASSWORD. See README.md . ${RED}STOP${NC}"
  echo ""
  exit 1
fi
export CONTROLLER_VERIFY_SSL=false

OPTSTRING="hlj:t:f:"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    j)
      job_template_name=${OPTARG}
      ;;
    f)
      extra_var_file=${OPTARG}
      if [ ! -f $extra_var_file ]; then 
         echo -e "Given extra vars file: ${BLUE}$extra_var_file${NC} does not exist.  ${RED}STOP${NC}."
         exit 1
      fi
      ;;
    t)
      target_limit=${OPTARG}
      ;;
    l)
        list_templates
        ;;
    :)
      LogError "Option -${OPTARG} requires an argument."
      usage
      ;;
    h)
      usage
      ;;
    ?)
      LogError "Invalid option: -${OPTARG}."
      usage
      ;;
  esac
done
shift $((OPTIND -1))

if [[ -z "$job_template_name" || -z "$target_limit" ]]; then 
  echo "Parameter -j job_template_name and -t target limit are mandatory. See -h. "
  exit 1
fi 


exec_job_template $job_template_name $target_limit $extra_var_file
exit 0
echo ""
