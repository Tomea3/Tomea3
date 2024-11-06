


# copy input file and raycloudtools to scratch

cp /storage/brno2/home/tomea/STSM_pokusy/singularity_img/raycloudtools.img $SCRATCHDIR && echo "raycloud copied" >> $LOG_FILE || { echo "raycloud cp error" >> $LOG_FILE; exit 1; }
cp /storage/brno2/home/tomea/STSM_pokusy/singularity_img/pdal.img $SCRATCHDIR && echo "pdal copied" >> $LOG_FILE || { echo "pdal cp error" >> $LOG_FILE; exit 1; }
cp $DATADIR/$SOURCE_DATA  $SCRATCHDIR && echo "data copied" >> $LOG_FILE || { echo "data cp error" >> $LOG_FILE; exit 1; }



