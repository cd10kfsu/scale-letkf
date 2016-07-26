#!/bin/bash
#===============================================================================
#
#  Main settings for SCALE-LETKF scripts
#
#===============================================================================

DIR="$(cd "$(pwd)/.." && pwd)"   # Root directory of the SCALE-LETKF

DDIR="/volume63/data/hp150019/gylien/test/scale-letkf/letkf/scale"

OUTDIR="$DDIR/../../exp/testcase_45km_4p" # Directory for SCALE-LETKF output

LOGDIR="$DIR/log"

#===============================================================================
# Location of model/data files

MODELDIR="$DDIR/../../scale/scale-rm/test/case_real/check_japan/run"
DATADIR="$DDIR/../../database"

DATA_TOPO="$DDIR/../../database/topo_prep/testcase_45km_4p_bf10"
DATA_LANDUSE="$DDIR/../../database/landuse_prep/testcase_45km_4p_bf10"
DATA_BDY_SCALE=
DATA_BDY_SCALE_PREP="$DDIR/../../database/bdy_prep/testcase_45km_4p"
DATA_BDY_WRF="$DDIR/../../ncepfnl/wrfout"
DATA_BDY_NICAM=

OBS="$DDIR/../../obs/prepbufr_obs_eastasia"    # directory of observation data in LETKF obs format
OBSNCEP="$DDIR/../../obs/prepbufr" # directory of observation data in NCEP BUFR format

#===============================================================================
# model/data file options

TOPO_FORMAT='prep'      # 'prep': Use prepared topo files in $DATA_TOPO
                        # 'GTOPO30' (requires compatible 'config.nml.scale_pp')
                        # 'DEM50M'  (requires compatible 'config.nml.scale_pp')

LANDUSE_FORMAT='prep'   # 'prep': Use prepared landuse files in $DATA_LANDUSE
                        # 'GLCCv2' (requires compatible 'config.nml.scale_pp')
                        # 'LU100M' (requires compatible 'config.nml.scale_pp')
LANDUSE_UPDATE=0        # 0: Time-invariant landuse files
                        # 1: Time-variant landuse files

BDY_FORMAT=0            # 0: SCALE with exactly same domain settings (do not need additional preprocessing)
                        # 1: SCALE (requires compatible 'config.nml.scale_init')
                        # 2: WRF   (requires compatible 'config.nml.scale_init')
                        # 3: NICAM (requires compatible 'config.nml.scale_init')
BDY_ENS=0               # 0: Fixed boundary files for all memebers
                        # 1: Ensemble boundary files

BDYINT=21600

OCEAN_INPUT=0           # 0: No ocean input (use cycling ocean variables)
                        # 1: Update the ocean variables every cycle

OCEAN_FORMAT=99         # 0: SCALE init files (with exactly same domain settings; do not need additional preprocessing)
                        # 99: From the same file as used in generating the boundary conditions ($BDY_FORMAT)

OBSNUM=1
OBSNAME[1]=obs                                    
OBSNAME[2]=radar

#===============================================================================
# Cycling settings

WINDOW_S=10800     # SCALE forecast time when assimilation window starts (second)
WINDOW_E=32400     # SCALE forecast time when assimilation window ends (second)
LCYCLE=21600       # Length of a GFS-LETKF cycle (second)
LTIMESLOT=3600     # Timeslot interval for 4D-LETKF (second)

#===============================================================================
# Parallelization settings

MEMBER=10          # Ensemble size

NNODES=44          # Number of nodes
PPN=1              # Number of processes per node

THREADS=8          # Number of threads per process

SCALE_NP=4         # Number of processes to run SCALE

BGJOB_INT='0.1s'   # Interval of multiple background job submissions

ENABLE_SET=1       ######

#===============================================================================
# Temporary directories to store runtime files

MACHINE_TYPE=10             # Machine type
                            #  1: Linux cluster with PBS
                            # 10: K-computer
                            # 11: K-computer (micro jobs)
                            # 12: K-computer (interact jobs)

TMPDAT_MODE=2               # Disk type used for the 'dat' temporary directory (input data)
TMPRUN_MODE=2               # Disk type used for the 'run' temporary directory (runtime files)
TMPOUT_MODE=$TMPRUN_MODE    # Disk type used for the 'out' temporary directory (output)
                            #  1: share (link to TMP)
                            #  2: share (staging to TMP)
                            #  3: local (staging to TMPL)

DATA_BDY_TMPLOC=1           # Location of the temporary directory for DATA_BDY
                            #  1: in $TMPDAT
                            #  2: in $TMPOUT

ONLINE_STGOUT=0             # Stage out right after each cycle (do not wait until the end of the job)?
                            #  0: No
                            #  1: Yes

SIMPLE_STGOUT=0             # Stage out the entire 'out' temporary directory instead of specifying each file?
                            #  0: No
                            #  1: Yes

SYSNAME="$(basename $OUTDIR)"                # A unique name in the machine
TMPSUBDIR="scale-letkf_${SYSNAME}" # (used to identify multiple runs in the same time)

TMP=                        # (When $MACHINE_TYPE=10, this will be automatically set)
TMPS="$DIR/tmp/$TMPSUBDIR"  # Temporary directory only on the server node
TMPL=                       # (When $MACHINE_TYPE=10, this will be automatically set)

#===============================================================================
# Environmental settings

MPIBIN=$(dirname $(which mpiexec))
MPIRUN="$MPIBIN/mpiexec"

SCP='cp -L'
SCP_HOSTPREFIX=''
#SCP="scp -q"
#SCP_HOSTPREFIX="XXXX:"

PYTHON="python"

#BUFRBIN=

#===============================================================================
# Machine-independent source file

. config.rc

#===============================================================================