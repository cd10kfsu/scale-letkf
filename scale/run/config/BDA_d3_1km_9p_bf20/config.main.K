#!/bin/bash
#===============================================================================
#
#  Main settings for SCALE-LETKF scripts
#
#===============================================================================

DIR="$(cd "$(pwd)/.." && pwd)"   # Root directory of the SCALE-LETKF

OUTDIR="/volume63/data/hp150019/gylien/exp/scale-letkf/BDA_case130713/d3_1km_100mem_121" # Directory for SCALE-LETKF output

#===============================================================================
# Location of model/data files

MODELDIR="$DIR/../../bin/K"
DATADIR="/volume63/data/hp150019/gylien/scale-letkf/database"

DATA_TOPO=
DATA_TOPO_BDY_SCALE="/volume63/data/hp150019/gylien/scale-letkf/database/topo_prep/BDA_d2_5km_64p_bf16"
DATA_LANDUSE=
DATA_BDY_SCALE="/volume63/data/hp150019/gylien/exp/scale-letkf/BDA_case130713/d2_5km_100mem_tint-1hr"
DATA_BDY_SCALE_PREP=
DATA_BDY_WRF=
DATA_BDY_NICAM=

OBS="/volume63/data/hp150019/gylien/obs/QCED_1KM_v4"     # directory of observation data in LETKF obs format
OBSNCEP=                                                 # directory of observation data in NCEP BUFR format

#===============================================================================
# model/data file options

TOPO_FORMAT='DEM50M'    # 'prep': Use prepared topo files in $DATA_TOPO
                        # 'GTOPO30' (requires compatible 'config.nml.scale_pp')
                        # 'DEM50M'  (requires compatible 'config.nml.scale_pp')

LANDUSE_FORMAT='LU100M' # 'prep': Use prepared landuse files in $DATA_LANDUSE
                        # 'GLCCv2' (requires compatible 'config.nml.scale_pp')
                        # 'LU100M' (requires compatible 'config.nml.scale_pp')
LANDUSE_UPDATE=0        # 0: Time-invariant landuse files
                        # 1: Time-variant landuse files

BDY_FORMAT=1            # 0: SCALE boundary files (with exactly same domain settings; do not need additional preprocessing)
                        # 1: SCALE history (requires compatible 'config.nml.scale_init')
                        # 2: WRF           (requires compatible 'config.nml.scale_init')
                        # 3: NICAM         (requires compatible 'config.nml.scale_init')
BDY_ENS=1               # 0: Fixed boundary files for all memebers
                        # 1: Ensemble boundary files

BDYINT=3600
BDYCYCLE_INT=21600

PARENT_REF_TIME=20130713060000

OCEAN_INPUT=0           # 0: No ocean input (use cycling ocean variables)
                        # 1: Update the ocean variables every cycle

OCEAN_FORMAT=99         # 0: SCALE init files (with exactly same domain settings; do not need additional preprocessing)
                        # 99: From the same file as used in generating the boundary conditions ($BDY_FORMAT)

OBSNUM=2
OBSNAME[1]=obs                                    
OBSNAME[2]=radar

#===============================================================================
# Cycling settings

WINDOW_S=300       # SCALE forecast time when assimilation window starts (second)
WINDOW_E=300       # SCALE forecast time when assimilation window ends (second)
LCYCLE=300         # Length of a GFS-LETKF cycle (second)
LTIMESLOT=300      # Timeslot interval for 4D-LETKF (second)

#===============================================================================
# Parallelization settings

MEMBER=100         # Ensemble size

NNODES=90          # Number of nodes
PPN=1              # Number of processes per node

THREADS=8          # Number of threads per process

SCALE_NP=9         # Number of processes to run SCALE

BGJOB_INT='0.1s'   # Interval of multiple background job submissions

ENABLE_SET=0       ######

#===============================================================================
# Temporary directories to store runtime files

MACHINE_TYPE=10             # Machine type
                            #  1: Linux cluster with PBS
                            # 10: K-computer
                            # 11: K-computer (micro jobs)
                            # 12: K-computer (interact jobs)

TMPDAT_MODE=3               # Disk type used for the 'dat' temporary directory (input data)
TMPRUN_MODE=3               # Disk type used for the 'run' temporary directory (runtime files)
TMPOUT_MODE=$TMPRUN_MODE    # Disk type used for the 'out' temporary directory (output)
                            #  1: share (link to TMP)
                            #  2: share (staging to TMP)
                            #  3: local (staging to TMPL)

DATA_BDY_TMPLOC=1           # Location of the temporary directory for DATA_BDY
                            #  1: in $TMPDAT
                            #  2: in $TMPOUT

DISK_MODE_TOPO_LANDUSE_DB=2

DISK_MODE_DATA_BDY=2

DISK_MODE_DATA_TOPO=2
DISK_MODE_DATA_LANDUSE=2
DISK_MODE_DATA_BDYPREP=2

ONLINE_STGOUT=0             # Stage out right after each cycle (do not wait until the end of the job)?
                            #  0: No
                            #  1: Yes

#SIMPLE_STGOUT=1             # Stage out the entire 'out' temporary directory instead of specifying each file?
#                            #  0: No
#                            #  1: Yes

STAGEOUT_ALL=0  ###### to be implemented

SYSNAME="$(basename $OUTDIR)"                # A unique name in the machine
TMPSUBDIR="scale-letkf_${SYSNAME}"           # (used to identify multiple runs in the same time)

TMP=                        # (When $MACHINE_TYPE=10, this will be automatically set)
TMPS="$DIR/tmp/$TMPSUBDIR"  # Temporary directory only on the server node
TMPL=                       # (When $MACHINE_TYPE=10, this will be automatically set)

CLEAR_TMP=0                 # Clear temporary directories after the completion of job?
                            #  0: No
                            #  1: Yes

#===============================================================================
# Environmental settings

MPIBIN=$(dirname $(which mpiexec))
MPIRUN="$MPIBIN/mpiexec"

SCP='cp -L'
SCP_HOSTPREFIX=''
#SCP='rsync -Lq'
#SCP_HOSTPREFIX=''
#SCP="scp -q"
#SCP_HOSTPREFIX="XXXX:"

SCP_THREAD=8

PYTHON="python"

#BUFRBIN=

#===============================================================================
# Machine-independent source file

. config.rc

#===============================================================================