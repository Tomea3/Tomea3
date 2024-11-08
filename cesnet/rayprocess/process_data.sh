# init files names
DATA_PLY="cloud.ply"
TERRAIN_PLY="cloud_mesh.ply"
TRUNKS_TXT="cloud_trunks.txt"
FOREST_TXT="cloud_forest.txt"
SEGMENTED_PLY="cloud_segmented.ply"
TREES_TXT="cloud_trees.txt"
TREES_MESH_PLY="cloud_trees_mesh.ply"
LEAVES_PLY="cloud_leaves.ply"

# Log file
LOG_FILE="process.log"

# Start PDAL processing
echo "$(date) pdal processing start" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./pdal.img pdal pipeline /data/pdal_pipeline.json
echo "$(date) pdal processing end" >> $LOG_FILE

# Start raycloudtools processing
echo "$(date) raycloudtools processing start" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayimport cloud.laz ray 0,0,-10 --remove_start_pos
echo "$(date) loaded" >> $LOG_FILE

# Extract terrain, trunks, and forest
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayextract terrain $DATA_PLY
echo "$(date) terrain extracted" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayextract trunks $DATA_PLY
echo "$(date) trunks extracted" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayextract forest $DATA_PLY
echo "$(date) forest extracted" >> $LOG_FILE

# Extract trees directly without decimation
echo "$(date) attempting to extract trees without decimation" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayextract trees $DATA_PLY $TERRAIN_PLY

# Check if the last command was successful
if [ $? -eq 0 ]; then
    echo "$(date) trees extracted successfully" >> $LOG_FILE
    mv cloud_segmented.ply $SEGMENTED_PLY
    mv cloud_trees.txt $TREES_TXT
    mv cloud_trees_mesh.ply $TREES_MESH_PLY
else
    echo "$(date) rayextract trees failed" >> $LOG_FILE
    exit 1  # Exit script if tree extraction fails
fi

# Extract leaves
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayextract leaves $DATA_PLY $TREES_TXT
echo "$(date) leaves extracted" >> $LOG_FILE

# Extract tree information
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img treeinfo $TREES_TXT
echo "$(date) treeinfo extracted" >> $LOG_FILE

# List files in SCRATCHDIR
echo "lof in SCRATCHDIR:" >> $LOG_FILE
echo "$(ls -lh)" >> $LOG_FILE
echo "" >> $LOG_FILE

# Create images for each segmented tree
SEGMENT_DIR="${SCRATCHDIR}/segments"
mkdir -p $SEGMENT_DIR
cp $SEGMENTED_PLY segments/$SEGMENTED_PLY
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img raysplit segments/$SEGMENTED_PLY seg_colour
echo "$(date) segments extracted" >> $LOG_FILE

# Render and export each segment
for segment_file in ${SEGMENT_DIR}/*.ply; do
    singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayrender "$segment_file" right ends
    segment_laz="${segment_file%.ply}.laz"
    segment_traj="${segment_file%.ply}.txt"
    singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayexport $segment_file $segment_laz $segment_traj
    singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img raywrap "$segment_file" inwards 1.0
    #echo "Rendered image for $segment_file" >> $LOG_FILE
done

echo "$(date) segments exported" >> $LOG_FILE
