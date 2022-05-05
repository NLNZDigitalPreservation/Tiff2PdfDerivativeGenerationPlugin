
Replace all `<path>` to real software path in
`src/main/bin/Tiff2PdfDerivativeGeneration.sh` (Line 19, 38, 42, 44)

Fill `src/main/plugin/PLUGIN-INF/metadata_Tiff2PdfDerivativeGenerationPlugin.xml` Line 19 to 29.

Params pattern for "stream handler" configuration
`<script-specific parameters> <jpeg conversion parameters> <output pdf label> <input dir> <output dir>`

Eg.
```
-density 150 -quality 50% merged_derivative_copy /tmp/images /tmp/output`
```
Test arguments

`-resample 150 -quality 80% -filter Mitchell merged_derivative_copy images output`

script-specific parameters:

`--use-cover-page "<path>/page-0.jpg" : add the .jpg cover page`

Example usage outside of Rosetta:
```
cd <path>/Tiff2PdfDerivativeGenerationPlugin/src/main/bin
```
```
bash -e Tiff2PdfDerivativeGeneration.sh --use-cover-page "<path>/page-0.jpg" -resample 150 -quality 80% -filter Mitchell merged_derivative_copy <path>/inputDir/ <path>/outputDir/`
```

-e option used so: any subsequent(*) commands which fail will cause the shell script to exit immediately. 

The benefit of using -e is that it prevents errors snowballing into serious issues when they could have been caught earlier.

ImageMagick installation notes:

Installing from sudo apt-get or source release (./configure, make, make install) will NOTE configure delegates so that ImageMagick can process different file formats, e.g. jpeg, tiff

The dependencies it needs to process the various file formats must be installed beforehand, via the call:

Easiest way to generate the required list of development libraries is to make sure you have the 'Sources' box ticked in 'Software & Updates' and then run the following command from a Terminal:

```
apt-get -s build-dep imagemagick
```