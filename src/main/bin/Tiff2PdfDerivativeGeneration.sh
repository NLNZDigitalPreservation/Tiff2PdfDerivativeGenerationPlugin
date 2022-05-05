#!/bin/bash

#
#
# Tuesday,  3 March 2015  Ben O'Brien
#  Created
#
#

# Constants
declare -r TRUE=1
declare -r FALSE=0
declare -r ARG_USE_COVER_PAGE="--use-cover-page"

# Temporary location for storing converted jpeg files
temp_image_dir=/tmp/dps_pdf_deriv_copy_gen

# Location of cover page disclaimer
cover_image_dir="<path>/page-0.jpg"

#DURING TESTING ONLY: Log everything to a file in /tmp
# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
#exec > >(tee -i /tmp/dps_pdf_deriv_copy_gen/log.log)
#exec 2>&1

# Set the PATH environment variable for this script (affects only this script)
# to the set PATH
set_Paths() {
	PATH=/usr/bin:/bin
	export PATH
	# Set LD_LIBRARY_PATH to blank to stop script using Rosetta version of ImageMagick
	LD_LIBRARY_PATH=
	export LD_LIBRARY_PATH
	# Set Open File Descriptors limit to 30000 
	ulimit -n 30000
	# Define ImageMagick path and location
	#IMAGEMAGICK_CONVERT_CMD="/usr/local/bin/convert" 
	IMAGEMAGICK_CONVERT_CMD="<path>/convert"
	# Define the system date command
	DATE_CMD="date"
	# Define sam2p path and location
	SAM2P_CMD="<path>/sam2p"
	# Define Sejda path and location
	SEJDA_CMD="<path>/sejda-console"
}

create_Dir() {	
	new_dir=${1}	
	# Create dir if doesn't exist
	if [ ! -d $new_dir ]
	then
	#	echo -e "Creating the directory for processing $new_dir\n"
		mkdir -p $new_dir
	fi
	sub_image_dir=$new_dir
}

datetime=`date +%Y%m%d%H%M%S`
create_Dir "$temp_image_dir/$datetime"
temp_sip_dir=$sub_image_dir
set_Paths

ARGS=""
USE_COVER_PAGE=$FALSE
# wrap all but the three last parameter in brackets (output name, input and output dirs)
for (( i=1;$i<$#-2;i=$i+1 ))
do	
	if [[ $USE_COVER_PAGE = $FALSE ]] && [[ "${!i}" = "$ARG_USE_COVER_PAGE" ]]; then
		USE_COVER_PAGE=$TRUE
		let i=i+1
		cover_image_dir="${!i}"
	else
    	ARGS="$ARGS ${!i}"
	fi
done

# Set INPUT/OUTPUT vars
OUTPUT_FILENAME="${!i}"
let i=i+1
INPUT_DIR="${!i}"
echo -e "INPUT DIR: `$INPUT_DIR`"
let i=i+1
OUTPUT_DIR="${!i}"
OUTPUT_FILE=`echo "$OUTPUT_DIR/$OUTPUT_FILENAME.pdf"`


################################################
# Convert tiffs to jpegs
################################################

# Conversion begin timestamp
echo -e "Conversion start: `$DATE_CMD`"

j=1
# Create first pdf sub-folder
create_Dir "$temp_sip_dir"/pdf-step1
# Copy cover page to first pdf sub-folder
if [[ $USE_COVER_PAGE = $TRUE ]]; then
	cp "$cover_image_dir" "$temp_sip_dir"/pdf-step1/page-"$j".jpg
	let j=j+1
fi

for file in "$INPUT_DIR"/*
do
	echo -e "Converting to jpeg: $file"
	$IMAGEMAGICK_CONVERT_CMD $file $ARGS "$temp_sip_dir"/pdf-step1/page-"$j".jpg
	let j=j+1
done

# Conversion end timestamp
echo "Conversion end: `$DATE_CMD`"

################################################
# Create temporary PDFs
################################################

# Create sub-folder for PDfs to merge
create_Dir "$temp_sip_dir"/pdf-step2

# PDF generation begin timestamp
echo -e "PDf generation start: `$DATE_CMD`"

for (( i=1;$i<$j;i=$i+1 ))
do
	# Prepend leading zeros to preserve correct numerically order
	printf -v num '%06d' $i;
	$SAM2P_CMD "$temp_sip_dir"/pdf-step1/page-"$i".jpg "$temp_sip_dir"/pdf-step2/page-"$num".pdf
done

# PDF generation end timestamp
echo "PDf generation end: `$DATE_CMD`"


################################################
# Merge temporary PDFs
################################################

echo -e "PDF merging start: `$DATE_CMD`"

# Merge jpegs to PDF
$SEJDA_CMD merge -d "$temp_sip_dir"/pdf-step2 -o $OUTPUT_FILE
#$SEJDA_CMD setmetadata -f $OUTPUT_FILE"_tmp" -o $OUTPUT_FILE --author "NDHA" --keywords "Book Collection" --subject "Travel" --title "Conquest of the New Zealand Alps"
# setmetadata --author "NDHA" --keywords "Book Collection" --subject "Travel" --title "Conquest of the New Zealand Alps"
# 2>error.log

echo -e "PDF merging end: `$DATE_CMD`"

# Delete the temporary files created if any
#echo "Removing the temp directory for processing $temp_sip_dir"
rm -fR $temp_sip_dir
