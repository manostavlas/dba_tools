#!/bin/bash
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

NC='\033[0m' # No Color
awx ping > /dev/null 2>&1
if [ "$?" != "0" ]; then 
  printf "${Red}Unable to contact controler. Use ${Blue}awx login${Red} command to connect to controler${NC} \n"
  exit 1
fi

echo ""
echo Available jobs: 
echo -------------------------------------------------------------------
awx job_templates list -f human
echo "" 
# Prompt the user for a job name
read -p "Enter the job name (or part of it (make it unique)): " job_name

# Find the job ID using the provided job name
job_id=$(awx job_templates list | jq -r --arg job_name "$job_name" '.results[] | select(.name | test($job_name)) | .id')

# Check if a job ID was found
if [ -z "$job_id" ]; then
    echo "No job template found matching the name: $job_name"
    exit 1
fi

printf "Job ID found:${Blue} ${job_id} ${NC} \n"

# Get the last executed job ID for the job template
last_execution_stat=$(awx job_templates get "$job_id" | jq -r '.summary_fields.last_job')
echo "Last execution status: "
printf "$last_execution_stat \n"

last_job_id=$(awx job_templates get "$job_id" | jq -r '.summary_fields.last_job.id')

# Check if a last job ID was found
if [ "$last_job_id" == "null" ]; then
    printf "${Red}No last executed job found for job template ID: ${Blue}$job_id${NC} \n"
    exit 1
fi

printf  "Last executed job ID:${Blue} $last_job_id ${NC} \n"

# Get the output of the last executed job
echo "Fetching output of the last executed job..."
awx --conf.color false jobs stdout "$last_job_id" > /tmp/last_job_output.txt
printf "Output in ${Green} /tmp/last_job_output.txt ${NC} \n"
echo ""

