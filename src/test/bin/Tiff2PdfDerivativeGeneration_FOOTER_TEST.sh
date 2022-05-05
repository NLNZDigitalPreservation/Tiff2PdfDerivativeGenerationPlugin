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
# -resample 150 -quality 80% -filter Mitchell merged_derivative_copy images output

# Example usage outside of Rosetta:
# cd /home/yure/AppDev/Natlib/NDHA-RP-MigrationPlugins/Tiff2PdfDerivativeGenerationPlugin/src/main/bin
# ./Tiff2PdfDerivativeGeneration.sh -resample 150 -quality 80% -filter Mitchell merged_derivative_copy /home/yure/AppDev/Test/Tiff2PdfDerivativeGenerationPlugin/sub01/inputDir/ /home/yure/AppDev/Test/Tiff2PdfDerivativeGenerationPlugin/sub01/outputDir/

# Temporary location for storing converted jpeg files
temp_image_dir=/tmp/dps_pdf_deriv_copy_gen

# Location of cover page disclaimer
cover_image_dir=/exlibris1/operational_storage/shared_oper/migration_plugin_cover_page/page-0.jpg
# Location of footer image
footer_image_dir=/exlibris1/operational_storage/shared_oper/migration_plugin_cover_page
footer_image_file=footer_image.png
footer_label='Property of National Library.\nNo commercial resale allowed.'

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
	IMAGEMAGICK_CONVERT_CMD="/usr/local/bin/convert"
	IMAGEMAGICK_IDENTIFY_CMD="/usr/local/bin/identify"
	#IMAGEMAGICK_CONVERT_CMD="/exlibris/product/ImageMagick-6.6.1-10/utilities/convert"
	# Define the system date command
	DATE_CMD="date"
	# Define sam2p path and location
	SAM2P_CMD="/exlibris/product/sam2p-0.49/sam2p"
	# Define Sejda path and location
	SEJDA_CMD="/exlibris/product/sejda-console-1.0.0.M10/bin/sejda-console"
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
# wrap all but the three last parameter in brackets (output name, input and output dirs)
for (( i=1;$i<$#-2;i=$i+1 ))
do
    ARGS="$ARGS ${!i}"
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
cp $cover_image_dir "$temp_sip_dir"/pdf-step1/

ORIG_FOOTER_HEIGHT=$($IMAGEMAGICK_IDENTIFY_CMD -ping -format '%h' "$footer_image_dir"/"$footer_image_file")
ORIG_FOOTER_WIDTH=$($IMAGEMAGICK_IDENTIFY_CMD -ping -format '%w' "$footer_image_dir"/"$footer_image_file")
for file in "$INPUT_DIR"/*
do
	echo -e "Converting to jpeg: $file"
	$IMAGEMAGICK_CONVERT_CMD $ARGS $file "$temp_sip_dir"/pdf-step1/page-"$j".jpg
	#Example of appending footer image
	#ImageMagick append rule is:
	#If they are not of the same width, narrower images are padded with the current -background color setting, 
	#and their position relative to each other can be controlled by the current -gravity setting. 

	#But what about varying sized images (e.g. landscape)?
	#This rule fixes the footer height to always be 10% of the image
	IMAGE_HEIGHT=$($IMAGEMAGICK_IDENTIFY_CMD -ping -format '%h' "$temp_sip_dir"/pdf-step1/page-"$j".jpg)
	IMAGE_WIDTH=$($IMAGEMAGICK_IDENTIFY_CMD -ping -format '%w' "$temp_sip_dir"/pdf-step1/page-"$j".jpg)
	NEW_FOOTER_WIDTH=$((${IMAGE_HEIGHT} / 10 * ${ORIG_FOOTER_WIDTH} / ${ORIG_FOOTER_HEIGHT}))
	#but cannot exceed original image's width
	NEW_FOOTER_WIDTH=${NEW_FOOTER_WIDTH}>${IMAGE_WIDTH}?${IMAGE_WIDTH}:${NEW_FOOTER_WIDTH}

	$IMAGEMAGICK_CONVERT_CMD "$footer_image_dir"/"$footer_image_file" -resize ${NEW_FOOTER_WIDTH} "$temp_sip_dir"/pdf-step1/"$footer_image_file" 
	$IMAGEMAGICK_CONVERT_CMD -gravity Center -append "$temp_sip_dir"/pdf-step1/page-"$j".jpg "$temp_sip_dir"/pdf-step1/"$footer_image_file" "$temp_sip_dir"/pdf-step1/page-"$j".jpg
	#Example of appending text -composited label
	#tricky to get it to look good / right size
	#$IMAGEMAGICK_CONVERT_CMD -background '#00000080' \ 
	#	-fill white \
	#	label:"$footer_label" \
	#	miff:- |composite -gravity south -geometry +0+3 \
	#	- page-1.jpg  page-1-footer.jpg
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

for (( i=0;$i<$j;i=$i+1 ))
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
