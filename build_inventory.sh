#!/bin/bash

function LogError() {
  echo "[ERROR]: $1"
  exit 1
}

function LogCons() {
  echo "[INFO ]: $1"
}

function usage () {
echo " Usage: gent_inventory [-h help] [-a {action}] [-c component ]"
echo ""
echo " SYNOPSYS: Create a standby (Data Guard) database."
echo ""
echo " OPTIONS:"
echo " -h                     This help"
echo ""
echo " -a                     The action to be executed. This option is MANDATORY."
echo ""
echo ""
exit 1
}

function build_inventory() {
  root_dir="inventories"
  mkdir -p $root_dir
  if [ ! -d "${root_dir}" ]; then
    LogError "Directory $root_dir does not exist. Dont't know where to build the inventory."
  fi

  dt=$(date +"%Y-%m-%d_%H-%M-%S")
  bkp_dir="$root_dir/bkp/${dt}"
  mkdir -p "$bkp_dir"

  LogCons ""
  LogCons "Backup dir is $bkp_dir "
  LogCons "All files will be saved there."
  LogCons ""

  LogCons "======================="
  LogCons "Generate EVX inventory"
  LogCons "======================="
  dest="$root_dir/evx"
  mkdir -p $dest
  for i in {2..9};do
   LogCons "     -> Build $dest/oracle_ev$i.yml"
   cp $dest/oracle_ev$i.yml $bkp_dir/oracle_ev$i.yml
   ./lookup_bmc.py -p ".*ev$i.*" -g oracle_ev$i > $dest/oracle_ev$i.yml
  done

  LogCons "     -> Build $dest/oracle_evx.yml"
  cp $dest/oracle_evx.yml $bkp_dir/oracle_evx.yml
  ./lookup_bmc.py -p ".*ev.*" -g oracle_evx > $dest/oracle_evx.yml

  LogCons "     -> Build $dest/oracle_uat.yml"
  cp $dest/oracle_uat.yml $bkp_dir/oracle_uat.yml
  ./lookup_bmc.py -p ".*uat.*" -g oracle_uat > $dest/oracle_uat.yml

  LogCons "     -> Build $dest/oracle_dap.yml"
  cp $dest/oracle_dap.yml $bkp_dir/oracle_dap.yml
  ./lookup_bmc.py -p ".*dap.*" -g oracle_dap > $dest/oracle_dap.yml


  LogCons "======================="
  LogCons "Generate EVZ inventory"
  LogCons "======================="
  dest="$root_dir/evz"
  mkdir -p $dest
  for i in {0..1};do 
   LogCons "     -> Build $dest/oracle_ev$i.yml"
   cp $dest/oracle_ev$i.yml $bkp_dir/oracle_ev${i}.yml
   ./lookup_bmc.py -p ".*ev$i.*" -g oracle_ev$i > $dest/oracle_ev$i.yml
  done

  LogCons "     -> Build $dest/oracle_evz.yml"
  cp $dest/oracle_evz.yml $bkp_dir/oracle_evz.yml
  ./lookup_bmc.py -p ".*ev.*" -g oracle_evz > $dest/oracle_evz.yml

  LogCons "======================="
  LogCons "Generate PRD inventory"
  LogCons "======================="
  dest="$root_dir/prd"
  mkdir -p $dest
  LogCons "     -> Build $dest/oracle_prd.yml"
  cp $dest/oracle_prd.yml $bkp_dir/oracle_prd.yml
  ./lookup_bmc.py -p "lx.*prd.*" -g oracle_prd > $dest/oracle_prd.yml
  ./lookup_bmc.py -p "ax.*prd.*" -g oracle_prd >> $dest/oracle_prd.yml

  find "$bkp_dir"  -mtime +180 -exec rm {} \;
}

OPTSTRING="ha:c:"
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    a)
      action=${OPTARG}
      ;;
    c)
      component=${OPTARG}
      ;;
    :)
      LogError "Option -${OPTARG} requires an argument. See -h for help"
      ;;
    h)
      usage
      ;;
    ?)
      LogError "Invalid option: -${OPTARG}. See -h for help"
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$action" ]; then
  LogError "Parameter -a is mandatory. Use --h for help."
  exit 1
fi

case ${action} in
  "build")
    build_inventory
    ;;
  *)
    LogError "Given action $action not known"
esac

