#!/bin/bash

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Please remember to copy this file back to /exlibris/dps/nlnz_tools
# and commit back to the subversion repository if changes are made
# these scripts may not be retained after DPS upgrades
# see the readme.txt in the nlnz_tools form more information.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
#
#
# Tuesday,  3 March 2015  Ben O'Brien
#  Created
#
#
# Params pattern for "stream handler" configuration
# <jpeg conversion parameters> <output pdf label> <input dir> <output dir>
#
# Eg.
# -density 150 -quality 50% merged_derivative_copy /tmp/images /tmp/output

# Test arguments
# -density 150 -quality 50% merged_derivative_copy images output

# Temporary location for storing converted jpeg files
temp_image_dir=/tmp/dps_pdf_deriv_copy_gen
# Location of cover page disclaimer
cover_image_dir=/export/home/obrienbe/page-0.jpg

# Create temp dir if doesn't exist
if [ ! -d $temp_image_dir ]
then
#	echo -e "Creating the temp directory for processing $temp_image_dir\n"
	mkdir -p $temp_image_dir
fi




# Server path to ImageMagick for DEV/UAT/PROD
#-- DEV/UAT --
#PATH=/usr/sfw/bin:$PATH
#-- PROD --
PATH=/opt/csw/bin:$PATH
export PATH
# Set LD_LIBRARY_PATH to blank to stop script using Rosetta version of ImageMagick
LD_LIBRARY_PATH=
export LD_LIBRARY_PATH
# Set Open File Descriptors limit to 30000
ulimit -n 30000




ARGS=""
# wrap all but the three last parameter in brackets (output name, input and output dirs)
for (( i=1;$i<$#-2;i=$i+1 ))
do
    ARGS="$ARGS ${!i}"
done

# Set INPUT/OUTPUT vars
OUTPUT_FILENAME="${!i}"
let i=i+1
INPUT_DIR="${!i}"
let i=i+1
OUTPUT_DIR="${!i}"
OUTPUT_FILE=`echo "$OUTPUT_DIR/$OUTPUT_FILENAME.pdf"`

# Conversion begin timestamp
echo -e "Conversion start: $(date)"

j=1
for file in "$INPUT_DIR"/*
do
	echo -e "Converting to jpeg: $file"
	convert $file $ARGS "$temp_image_dir"/page-"$j".jpg
	let j=j+1
done

# Conversion end timestamp
echo "Conversion end: $(date)"

# Copy cover page to tmp folder
cp $cover_image_dir "$temp_image_dir"/

# Merge jpegs to PDF
#echo -e "\nCreating PDF with $ARGS: $OUTPUT_FILE"
#convert -limit area 0 -limit map 0 -debug "ALL" "$temp_image_dir"/*.jpg $OUTPUT_FILE 2>/export/home/obrienbe/error.log
convert -limit area 0 -limit map 0 "$temp_image_dir"/*.jpg $OUTPUT_FILE 2>/export/home/obrienbe/error.log

# Delete the temporary files created if any
#echo "Removing the temp directory for processing $temp_image_dir"
rm -fR $temp_image_dir

