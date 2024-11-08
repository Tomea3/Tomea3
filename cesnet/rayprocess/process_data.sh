# init files names
DATA_PLY="cloud_wood_only.ply"
TREES_MESH_PLY="cloud_trees_mesh.ply"

# Start raycloudtools processing
echo "$(date) raycloudtools processing start" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayimport cloud_wood_only.laz ray 0,0,-10 --remove_start_pos
echo "$(date) loaded" >> $LOG_FILE

# Extract trees mesh
echo "$(date) attempting to extract trees mesh" >> $LOG_FILE
singularity exec -B $SCRATCHDIR/:/data ./raycloudtools.img rayextract trees_mesh $DATA_PLY

# Check if the last command was successful
if [ $? -eq 0 ]; then
    echo "$(date) trees mesh extracted successfully" >> $LOG_FILE
    mv cloud_trees_mesh.ply $TREES_MESH_PLY
else
    echo "$(date) rayextract trees mesh failed" >> $LOG_FILE
    exit 1  # Exit script if tree mesh extraction fails
fi

# List files in SCRATCHDIR
echo "lof in SCRATCHDIR:" >> $LOG_FILE
echo "$(ls -lh)" >> $LOG_FILE
echo "" >> $LOG_FILE
