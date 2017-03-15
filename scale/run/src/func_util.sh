#!/bin/bash
#===============================================================================
#
#  Common utilities (using built-in 'datetime' program)
#  August 2014, Guo-Yuan Lien
#
#  *Require source 'config.main' first.
#
#===============================================================================

safe_init_tmpdir () {
#-------------------------------------------------------------------------------
# Safely initialize a temporary directory
#
# Usage: safe_init_tmpdir DIRNAME
#
#   DIRNAME  The temporary directory
#-------------------------------------------------------------------------------

local DIRNAME="$1"

#-------------------------------------------------------------------------------

if [ -z "$DIRNAME" ]; then
  echo "[Warning] $FUNCNAME: '\$DIRNAME' is not set." >&2
  exit 1
fi

mkdir -p $DIRNAME || exit $?

if [ ! -d "$DIRNAME" ]; then
  echo "[Error] $FUNCNAME: '$DIRNAME' is not a directory." >&2
  exit 1
fi
if [ ! -O "$DIRNAME" ]; then
  echo "[Error] $FUNCNAME: '$DIRNAME' is not owned by you." >&2
  exit 1
fi

rm -fr $DIRNAME/* || exit $?

#-------------------------------------------------------------------------------
}

#===============================================================================

safe_rm_tmpdir () {
#-------------------------------------------------------------------------------
# Safely remove a temporary directory
#
# Usage: safe_rm_tmpdir DIRNAME
#
#   DIRNAME  The temporary directory
#-------------------------------------------------------------------------------

local DIRNAME="$1"

#-------------------------------------------------------------------------------

if [ -z "$DIRNAME" ]; then
  echo "[Error] $FUNCNAME: '\$DIRNAME' is not set." >&2
  exit 1
fi
if [ ! -e "$DIRNAME" ]; then
  return 0
fi
if [ ! -d "$DIRNAME" ]; then
  echo "[Error] $FUNCNAME: '$DIRNAME' is not a directory." >&2
  exit 1
fi
if [ ! -O "$DIRNAME" ]; then
  echo "[Error] $FUNCNAME: '$DIRNAME' is not owned by you." >&2
  exit 1
fi

rm -fr $DIRNAME
res=$? && ((res != 0)) && exit $res

#-------------------------------------------------------------------------------
}

#===============================================================================

rev_path () {
#-------------------------------------------------------------------------------
# Compose the reverse path of a path
#
# Usage: rev_path PATH
#
#   PATH  The forward path
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local path="$1"

#-------------------------------------------------------------------------------

local rpath='.'
local base
while [ "$path" != '.' ]; do
  base=$(basename $path)
  res=$? && ((res != 0)) && exit $res
  path=$(dirname $path)
  if [ "$base" = '..' ]; then
    if [ -d "$path" ]; then
      rpath="$rpath/$(basename $(cd $path && pwd))"
    else
      echo "[Error] $FUNCNAME: Error in reverse path search." 1>&2
      exit 1
    fi
  elif [ "$base" != '.' ]; then
    rpath="$rpath/.."
  fi
done
if [ ${rpath:0:2} = './' ]; then
  echo ${rpath:2}
else
  echo $rpath
fi

#-------------------------------------------------------------------------------
}

#===============================================================================

mpirunf () {
#-------------------------------------------------------------------------------
# Submit a MPI job according to nodefile
#
# Usage: mpirunf NODEFILE PROG [ARGS]
#
#   NODEFILE  Name of nodefile (omit the directory $NODEFILE_DIR)
#   PROG      Program
#   ARGS      Arguments passed into the program
#
# Other input variables:
#   $NODEFILE_DIR  Directory of nodefiles
#-------------------------------------------------------------------------------

if (($# < 2)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local NODEFILE="$1"; shift
local PROG="$1"; shift
local CONF="$1"; shift
local STDOUT="$1"; shift
local ARGS="$@"

progbase=$(basename $PROG)
progdir=$(dirname $PROG)

#-------------------------------------------------------------------------------

if [ "$MPI_TYPE" = 'sgimpt' ]; then

  local HOSTLIST=$(cat ${NODEFILE_DIR}/${NODEFILE})
  HOSTLIST=$(echo $HOSTLIST | sed 's/  */,/g')

  $MPIRUN -d $progdir $HOSTLIST 1 ./$progbase $CONF $STDOUT $ARGS
#  $MPIRUN -d $progdir $HOSTLIST 1 omplace -nt ${THREADS} ./$progbase $CONF $STDOUT $ARGS
  res=$?
  if ((res != 0)); then
    echo "[Error] $MPIRUN -d $progdir $HOSTLIST 1 ./$progbase $CONF $STDOUT $ARGS" >&2
    echo "        Exit code: $res" >&2
    exit $res
  fi

elif [ "$MPI_TYPE" = 'openmpi' ]; then

  NNP=$(cat ${NODEFILE_DIR}/${NODEFILE} | wc -l)

  $MPIRUN -np $NNP -hostfile ${NODEFILE_DIR}/${NODEFILE} -wdir $progdir ./$progbase $CONF $STDOUT $ARGS
  res=$?
  if ((res != 0)); then
    echo "[Error] $$MPIRUN -np $NNP -hostfile ${NODEFILE_DIR}/${NODEFILE} -wdir $progdir ./$progbase $CONF $STDOUT $ARGS" >&2
    echo "        Exit code: $res" >&2
    exit $res
  fi

elif [ "$MPI_TYPE" = 'impi' ]; then

  NNP=$(cat ${NODEFILE_DIR}/${NODEFILE} | wc -l)

  $MPIRUN -n $NNP -machinefile ${NODEFILE_DIR}/${NODEFILE} -gwdir $progdir ./$progbase $CONF $STDOUT $ARGS
  res=$?
  if ((res != 0)); then
    echo "[Error] $$MPIRUN -n $NNP -machinefile ${NODEFILE_DIR}/${NODEFILE} -gwdir $progdir ./$progbase $CONF $STDOUT $ARGS" >&2
    echo "        Exit code: $res" >&2
    exit $res
  fi

elif [ "$MPI_TYPE" = 'K' ]; then

  NNP=$(cat ${NODEFILE_DIR}/${NODEFILE} | wc -l)

  if [ "$STG_TYPE" = 'K_rankdir' ]; then

    mpiexec -n $NNP -of-proc $STDOUT ./${progdir}/${progbase} $CONF '' $ARGS
    res=$?
    if ((res != 0)); then
      echo "[Error] mpiexec -n $NNP -of-proc $STDOUT ./${progdir}/${progbase} $CONF '' $ARGS" >&2
      echo "        Exit code: $res" >&2
      exit $res
    fi

  else

#    ( cd $progdir && mpiexec -n $NNP -of-proc $STDOUT ./$progbase $CONF '' $ARGS )
    ( cd $progdir && mpiexec -n $NNP -vcoordfile "${NODEFILE_DIR}/${NODEFILE}" -of-proc $STDOUT ./$progbase $CONF '' $ARGS )
    res=$?
    if ((res != 0)); then 
#      echo "[Error] mpiexec -n $NNP -of-proc $STDOUT ./$progbase $CONF '' $ARGS" >&2
      echo "[Error] mpiexec -n $NNP -vcoordfile "${NODEFILE_DIR}/${NODEFILE}" -of-proc $STDOUT ./$progbase $CONF '' $ARGS" >&2
      echo "        Exit code: $res" >&2
      exit $res
    fi

  fi

fi

#-------------------------------------------------------------------------------
}

#===============================================================================

pdbash () {
#-------------------------------------------------------------------------------
# Submit bash parallel scripts according to nodefile
#
# Usage: pdbash NODEFILE PROC_OPT SCRIPT [ARGS]
#
#   NODEFILE  Name of nodefile (omit the directory $NODEFILE_DIR)
#   PROC_OPT  Options of using processes
#             all:  run the script in all processes listed in $NODEFILE
#             one:  run the script only in the first process and node in $NODEFILE
#   SCRIPT    Script (the working directory is set to $SCRP_DIR)
#   ARGS      Arguments passed into the program
#
# Other input variables:
#   $NODEFILE_DIR  Directory of nodefiles
#-------------------------------------------------------------------------------

if (($# < 2)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local NODEFILE="$1"; shift
local PROC_OPT="$1"; shift
local SCRIPT="$1"; shift
local ARGS="$@"

if [ -x "$TMPDAT/exec/pdbash" ]; then
  pdbash_exec="$TMPDAT/exec/pdbash"
elif [ -x "$COMMON_DIR/pdbash" ]; then
  pdbash_exec="$COMMON_DIR/pdbash"
else
  echo "[Error] $FUNCNAME: Cannot find 'pdbash' program." >&2
  exit 1
fi

if [ "$PROC_OPT" != 'all' ] && [ "$PROC_OPT" != 'one' ]; then
  echo "[Error] $FUNCNAME: \$PROC_OPT needs to be {all|one}." >&2
  exit 1
fi

#-------------------------------------------------------------------------------

if [ "$MPI_TYPE" = 'sgimpt' ]; then

  if [ "$PROC_OPT" == 'all' ]; then
    local HOSTLIST=$(cat ${NODEFILE_DIR}/${NODEFILE})
  elif [ "$PROC_OPT" == 'one' ]; then
    local HOSTLIST=$(head -n 1 ${NODEFILE_DIR}/${NODEFILE})
  fi
  HOSTLIST=$(echo $HOSTLIST | sed 's/  */,/g')

  $MPIRUN -d $SCRP_DIR $HOSTLIST 1 $pdbash_exec $SCRIPT $ARGS
#  $MPIRUN -d $SCRP_DIR $HOSTLIST 1 bash $SCRIPT - $ARGS
  res=$?
  if ((res != 0)); then
    echo "[Error] $MPIRUN -d $SCRP_DIR $HOSTLIST 1 $pdbash_exec $SCRIPT $ARGS" >&2
    echo "        Exit code: $res" >&2
    exit $res
  fi

elif [ "$MPI_TYPE" = 'openmpi' ]; then

  if [ "$PROC_OPT" == 'all' ]; then
    NNP=$(cat ${NODEFILE_DIR}/${NODEFILE} | wc -l)
  elif [ "$PROC_OPT" == 'one' ]; then
    NNP=1
  fi

  $MPIRUN -np $NNP -hostfile ${NODEFILE_DIR}/${NODEFILE} -wdir $SCRP_DIR $pdbash_exec $SCRIPT $ARGS
  res=$?
  if ((res != 0)); then
    echo "[Error] $MPIRUN -np $NNP -hostfile ${NODEFILE_DIR}/${NODEFILE} -wdir $SCRP_DIR $pdbash_exec $SCRIPT $ARGS" >&2
    echo "        Exit code: $res" >&2
    exit $res
  fi

elif [ "$MPI_TYPE" = 'impi' ]; then

  if [ "$PROC_OPT" == 'all' ]; then
    NNP=$(cat ${NODEFILE_DIR}/${NODEFILE} | wc -l)
  elif [ "$PROC_OPT" == 'one' ]; then
    NNP=1
  fi

  $MPIRUN -n $NNP -machinefile ${NODEFILE_DIR}/${NODEFILE} -gwdir $SCRP_DIR $pdbash_exec $SCRIPT $ARGS
  res=$?
  if ((res != 0)); then
    echo "[Error] $MPIRUN -n $NNP -machinefile ${NODEFILE_DIR}/${NODEFILE} -gwdir $SCRP_DIR $pdbash_exec $SCRIPT $ARGS" >&2
    echo "        Exit code: $res" >&2
    exit $res
  fi

elif [ "$MPI_TYPE" = 'K' ]; then

  if [ "$STG_TYPE" = 'K_rankdir' ]; then
    if [ "$PROC_OPT" == 'one' ]; then

      mpiexec -n 1 $pdbash_exec $SCRIPT $ARGS
      res=$?
      if ((res != 0)); then
        echo "[Error] mpiexec -n 1 $pdbash_exec $SCRIPT $ARGS" >&2
        echo "        Exit code: $res" >&2
        exit $res
      fi

    else

      mpiexec $pdbash_exec $SCRIPT $ARGS
      res=$?
      if ((res != 0)); then
        echo "[Error] mpiexec $pdbash_exec $SCRIPT $ARGS" >&2
        echo "        Exit code: $res" >&2
        exit $res
      fi

    fi
  else
    if [ "$PROC_OPT" == 'one' ]; then

      ( cd $SCRP_DIR && mpiexec -n 1 $pdbash_exec $SCRIPT $ARGS )
      res=$?
      if ((res != 0)); then
        echo "[Error] mpiexec -n 1 $pdbash_exec $SCRIPT $ARGS" >&2
        echo "        Exit code: $res" >&2
        exit $res
      fi

    else

      ( cd $SCRP_DIR && mpiexec $pdbash_exec $SCRIPT $ARGS )
      res=$?
      if ((res != 0)); then
        echo "[Error] mpiexec $pdbash_exec $SCRIPT $ARGS" >&2
        echo "        Exit code: $res" >&2
        exit $res
      fi

    fi
  fi

fi

#-------------------------------------------------------------------------------
}

#===============================================================================

pdrun () {
#-------------------------------------------------------------------------------
# Return if it is the case to run parallel scripts, according to nodefile
#
# Usage: pdrun GROUP OPT
#
#   GROUP   Group of processes
#           all:     all processes
#           (group): process group #(group)
#   OPT     Options of the ways to pick up processes
#           all:  run the script in all processes in the group
#           alln: run the script in all nodes in the group, one process per node (default)
#           one:  run the script only in the first process in the group
#
# Other input variables:
#   MYRANK  The rank of the current process
#
# Exit code:
#   0: This process is used
#   1: This process is not used
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local GROUP="$1"; shift
local OPT="${1:-alln}"

#-------------------------------------------------------------------------------

local mynode=${proc2node[$((MYRANK+1))]}
if [ -z "$mynode" ]; then
  exit 1
fi

local res=1
local n

if [ "$GROUP" = 'all' ]; then

  if [ "$OPT" = 'all' ]; then
    exit 0
  elif [ "$OPT" = 'alln' ]; then
    res=0
    for n in $(seq $MYRANK); do
      if ((${proc2node[$n]} == mynode)); then
        res=1
        break
      fi
    done
  elif [ "$OPT" = 'one' ]; then
    if ((MYRANK == 0)); then
      exit 0
    fi
  fi

elif ((GROUP <= parallel_mems)); then

  local mygroup=${proc2group[$((MYRANK+1))]}
  local mygrprank=${proc2grpproc[$((MYRANK+1))]}

  if ((mygroup = GROUP)); then
    if [ "$OPT" = 'all' ]; then
      exit 0
    elif [ "$OPT" = 'alln' ]; then
      res=0
      for n in $(seq $((mygrprank-1))); do
        if ((${mem2node[$(((GROUP-1)*mem_np+n))]} == mynode)); then
          res=1
          break
        fi
      done
    elif [ "$OPT" = 'one' ]; then
      if ((${mem2node[$(((GROUP-1)*mem_np+1))]} == mynode)); then
        res=0
        for n in $(seq $((mygrprank-1))); do
          if ((${mem2node[$(((GROUP-1)*mem_np+n))]} == mynode)); then
            res=1
            break
          fi
        done
      fi
    fi
  fi

fi

exit $res

#-------------------------------------------------------------------------------
}

#===============================================================================

bdy_setting () {
#-------------------------------------------------------------------------------
# Calculate scale_init namelist settings for boundary files
#
# Usage: bdy_setting TIME FCSTLEN PARENT_LCYCLE [PARENT_FOUT] [PARENT_REF_TIME] [SINGLE_FILE]
#
#   TIME
#   FCSTLEN
#   PARENT_LCYCLE
#   PARENT_FOUT
#   PARENT_REF_TIME
#   SINGLE_FILE
#
# Return variables:
#   $nbdy
#   $ntsteps
#   $ntsteps_skip
#   $bdy_times[1...$nbdy]
#   $bdy_start_time
#   $parent_start_time
#
#  *Require source 'func_datetime' first.
#-------------------------------------------------------------------------------

if (($# < 3)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local TIME=$(datetime $1); shift
local FCSTLEN=$1; shift
local PARENT_LCYCLE=$1; shift
local PARENT_FOUT=${1:-$PARENT_LCYCLE}; shift
local PARENT_REF_TIME=${1:-$TIME}; shift
local SINGLE_FILE=${1:-0}

PARENT_REF_TIME=$(datetime $PARENT_REF_TIME)

#-------------------------------------------------------------------------------
# compute $parent_start_time based on $PARENT_REF_TIME and $PARENT_LCYCLE

parent_start_time=$PARENT_REF_TIME
local parent_start_time_prev=$parent_start_time
while ((parent_start_time <= TIME)); do
  parent_start_time_prev=$parent_start_time
  parent_start_time=$(datetime $parent_start_time $PARENT_LCYCLE s)
done
parent_start_time=$parent_start_time_prev

while ((parent_start_time > TIME)); do
  parent_start_time=$(datetime $parent_start_time -${PARENT_LCYCLE} s)
done

#-------------------------------------------------------------------------------
# compute $bdy_start_time, $ntsteps_skip, and $ntsteps_total based on $parent_start_time and $PARENT_FOUT
# (assume $bdy_start_time <= $TIME)

ntsteps_skip=-1
bdy_start_time=$parent_start_time
while ((bdy_start_time <= TIME)); do
  bdy_start_time_prev=$bdy_start_time
  bdy_start_time=$(datetime $bdy_start_time $PARENT_FOUT s)
  ntsteps_skip=$((ntsteps_skip+1))
done
bdy_start_time=$bdy_start_time_prev

local ntsteps_total=$(((FCSTLEN-1)/PARENT_FOUT+2 + ntsteps_skip))

if ((bdy_start_time != TIME)); then
  if (($(datetime $bdy_start_time $(((ntsteps_total-1)*PARENT_FOUT)) s) < $(datetime $TIME $FCSTLEN s))); then
    ntsteps_total=$((ntsteps_total+1))
  fi
fi

#-------------------------------------------------------------------------------
# compute $ntsteps

if ((PARENT_LCYCLE % PARENT_FOUT != 0)); then
  echo "[Error] $FUNCNAME: $PARENT_LCYCLE needs to be an exact multiple of $PARENT_FOUT." >&2
  exit 1
fi

if ((SINGLE_FILE == 1)); then
  ntsteps=$ntsteps_total
else
  ntsteps=$((PARENT_LCYCLE / PARENT_FOUT))
fi

#-------------------------------------------------------------------------------
# compute $nbdy and $bdy_times[1...$nbdy]

nbdy=1
bdy_times[1]=$parent_start_time
while ((ntsteps_total > ntsteps)); do
  nbdy=$((nbdy+1))
  bdy_times[$nbdy]=$(datetime ${bdy_times[$((nbdy-1))]} $PARENT_LCYCLE s)
  ntsteps_total=$((ntsteps_total-ntsteps))
done

if ((nbdy == 1)); then
  ntsteps=$ntsteps_total
fi

#echo "\$nbdy              = $nbdy" >&2
#echo "\$ntsteps           = $ntsteps" >&2
#echo "\$ntsteps_skip      = $ntsteps_skip" >&2
#echo "\$ntsteps_total     = $ntsteps_total" >&2
#echo "\$bdy_start_time    = $bdy_start_time" >&2
#echo "\$parent_start_time = $parent_start_time" >&2

#-------------------------------------------------------------------------------
}

#===============================================================================

mv_to_outdir () {
#-------------------------------------------------------------------------------
# Submit a PJM job.
#
# Usage: job_submit_PJM
#
#   JOBSCRP  Job script
#
# Return variables:
#   $jobid  Job ID monitered
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

SINGLE_FILE
SORC_DIR
SORC_PREFIX
DEST_DIR
DEST_PREFIX_1
DEST_PREFIX_2
SUFFIX

#-------------------------------------------------------------------------------

if ((SINGLE_FILE == 1)); then
  mkdir -p ${DEST_DIR}
  ifile="restart_${ATIME:0:8}-${ATIME:8:6}.000.nc"
  if [ -e "${SORC_DIR}/${SORC_PREFIX_1}${SUFFIX}" ]; then
    mv -f ${SORC_DIR}/${SORC_PREFIX_1}${SUFFIX} ${DEST_DIR}/${DEST_PREFIX_1}.${DEST_PREFIX_2}${SUFFIX}
  fi
else
  mkdir -p ${DEST_DIR}/${DEST_PREFIX_1}
  local len=${#SORC_PREFIX}
  for ifile in $(cd $SORC_DIR ; ls ${SORC_PREFIX}*${SUFFIX}); do
    mv -f ${SORC_DIR}/${ifile} ${DEST_DIR}/${DEST_PREFIX_1}/${DEST_PREFIX_2}${ifile:$len}
  done
fi

#-------------------------------------------------------------------------------
}

#===============================================================================

job_submit_PJM () {
#-------------------------------------------------------------------------------
# Submit a PJM job.
#
# Usage: job_submit_PJM
#
#   JOBSCRP  Job script
#
# Return variables:
#   $jobid  Job ID monitered
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local JOBSCRP="$1"

local rundir=$(dirname $JOBSCRP)
local scrpname=$(basename $JOBSCRP)

#-------------------------------------------------------------------------------

res=$(cd $rundir && pjsub $scrpname 2>&1)
echo $res

if [ -z "$(echo $res | grep 'ERR')" ]; then
  jobid=$(echo $res | grep 'submitted' | cut -d ' ' -f 6)
  if [ -z "$jobid" ]; then
    echo "[Error] $FUNCNAME: Error found when submitting a job." >&2
    exit 1
  fi
else
  echo "[Error] $FUNCNAME: Error found when submitting a job." >&2
  exit 1
fi

#-------------------------------------------------------------------------------
}

#===============================================================================

job_end_check_PJM () {
#-------------------------------------------------------------------------------
# Check if a PJM job has ended.
#
# Usage: job_end_check_PJM JOBID
#
#   JOBID  Job ID monitored
#
# Return variables:
#   $jobstat    Job status
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local JOBID="$1"

#-------------------------------------------------------------------------------

local res=0
local tmp
while true; do
  tmp=$(pjstat ${JOBID} | tail -n 1)
  if [ -z "$(echo $tmp | grep ${JOBID})" ]; then
    break
  fi
  sleep 10s
done

tmp=$(pjstat -H ${JOBID} | tail -n 1)
if [ -z "$(echo $tmp | grep ${JOBID})" ]; then
  echo "[Error] $FUNCNAME: Cannot find PJM job ${JOBID}." >&2
  return 99
else
  jobstat=$(echo $tmp | cut -d ' ' -f3)
  if [ "$jobstat" = 'REJECT' ] || [ "$jobstat" = 'CANCEL' ]; then
    res=98
  elif [ "$jobstat" = 'ERROR' ]; then
    res=97
  fi  
fi

if ((res != 0)); then
  echo "[Error] $FUNCNAME: PJM job $JOBID ended with errors." >&2
  echo "        status      = $jobstat" >&2
  return $res
fi
return 0

#-------------------------------------------------------------------------------
}

#===============================================================================

job_end_check_PJM_K () {
#-------------------------------------------------------------------------------
# Check if a PJM job has ended (specialized for the K computer).
#
# Usage: job_end_check_PJM_K JOBID
#
#   JOBID  Job ID monitored
#
# Return variables:
#   $jobstat    Job status
#   $jobec      Job exit code
#   $jobreason  Job exit reason
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local JOBID="$1"

#-------------------------------------------------------------------------------

local res=0
local tmp
while true; do
  tmp=$(pjstat --choose ST,EC,REASON ${JOBID} | tail -n 1)
  if [ -z "$tmp" ]; then
    echo "[Error] $FUNCNAME: Cannot find PJM job ${JOBID}." >&2
    return 99
  fi

  jobstat=$(echo $tmp | cut -d ' ' -f1)
  jobec=$(echo $tmp | cut -d ' ' -f2)
  jobreason=$(echo $tmp | cut -d ' ' -f3-)

  if [ "$jobstat" = 'RJT' ] || [ "$jobstat" = 'CCL' ]; then
    res=98
    break
  elif [ "$jobstat" = 'EXT' ]; then
    if [ "$jobreason" != '-' ]; then
      res=97
    elif ((jobec != 0)); then
      res=$jobec
    fi
    break
  fi
  sleep 30s
done

if ((res != 0)); then
  echo "[Error] $FUNCNAME: PJM job $JOBID ended with errors." >&2
  echo "        status      = $jobstat" >&2
  echo "        exit code   = $jobec" >&2
  echo "        exit reason = $jobreason" >&2
  return $res
fi
return 0

#-------------------------------------------------------------------------------
}

#===============================================================================

job_submit_torque () {
#-------------------------------------------------------------------------------
# Submit a torque job.
#
# Usage: job_submit_torque
#
#   JOBSCRP  Job script
#
# Return variables:
#   $jobid  Job ID monitered
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local JOBSCRP="$1"

local rundir=$(dirname $JOBSCRP)
local scrpname=$(basename $JOBSCRP)

#-------------------------------------------------------------------------------

res=$(cd $rundir && qsub $scrpname 2>&1)
jobid=$(echo $res | cut -d '.' -f1)

if ! [[ "$jobid" =~ ^[0-9]+$ ]] ; then
  jobid=
  echo "[Error] $FUNCNAME: Error found when submitting a job." >&2
  exit 1
fi

echo "qsub Job $jobid submitted."

#-------------------------------------------------------------------------------
}

#===============================================================================

job_end_check_torque () {
#-------------------------------------------------------------------------------
# Check if a torque job has ended.
#
# Usage: job_end_check_torque JOBID
#
#   JOBID  Job ID monitored
#
# * Do not support exit code yet
#-------------------------------------------------------------------------------

if (($# < 1)); then
  echo "[Error] $FUNCNAME: Insufficient arguments." >&2
  exit 1
fi

local JOBID="$1"

#-------------------------------------------------------------------------------

local res=0
local tmp
while true; do
  tmp=$(qstat ${JOBID} 2> /dev/null)
  if (($? != 0)); then
    break
  fi
  sleep 5s
done

return 0

#-------------------------------------------------------------------------------
}

#===============================================================================
