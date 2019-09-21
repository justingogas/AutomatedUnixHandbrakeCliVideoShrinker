#!/bin/bash

# This is a UNIX Bash script that will automatically shrink videos that are placed in a set of folders.  It will take videos loaded into one directory, shrink them to 45% - 55% of their current size, and then delete the original video.  Handbrake-CLI is the video processing program used, but it could be adapted to use any command-line video program.
# Handbrake cannot predict the end size of the file, so it will try multiple encodes until reaches the desired half file size.  Since Handbrake seems to randomly restart the machine that this shrinker is running on, it records its current encode settings and will restart with that setting if a system restart is detected instead of from scratch, potentially saving multiple encode cycles of the same file.


cd ~/Videos/encode/

path="$(pwd)"

# Only run one instance of this by checking for any queued videos.  If none are found, then start a new encode.
queued="$(ls $path/queue/ | wc -l)"

# If a record is found in the working directory, then start with that video at the last encoding quality.  This way, if it was interrupted by a system restart, it doesn't start from scratch and waste time encoding levels that were too large.
info="$(ls $path/info/ | wc -l)"

# Create two ranges, an outer range and an inner range, that represent a percentage of encoded file size.  These will determine if a more aggressive shrinking factor is used on the next encode if the encoded file missed its mark with the end file size.
# If it is outside the outer threshold, then increase the shrink factor by a larger amount.  If inside the outer threshold but outside the inner threshold, then use a smaller shrink factor for the next encode.
# This prevents the scenario where an encode just barely missed the desired file size mark but an encode with the same aggressive shrinking factor will sacrifice too much quality unnecessarily on its next encode.
innerThresholdUpper="0.55"
innerThresholdLower="0.45"
outerThresholdUpper="0.65"
outerThresholdLower="0.35"


# Target file size is 1G per hour, which seems to equate to half the file size for the types of video I encode.  Some compress much more, which is undesirable, and others less, so redo the encode if it isn't in the correct range.
# 27 is the start encode quality.  Lower numbers is higher quality (bigger file size) and higher numbers is lower quality (smaller file size).  Do not go below 20 (imperceptible quality increase) or above 32 (horrendous $
# For high-quality videos with minimal compression, this should cut the file size by half.  For videos that can be heavily compressed, this is too much and should be reduced.
# Repeat the encode with a lower quality number if it is too compressed or with a higher number if it is not compressed enough.
encodeQuality=27
interruptedFileEncodingQuality=0

# The aggressive and relaxed encode steps are applied on subsequent encodes if the file size missed its mark.  The higher step is used if it was outside the outer threshold and the lower step is used if it was inside the outer threshold but outside the inner threshold.
# Note that Handbrake has reversed quality numbers where lower numbers indicate higher quality, so a lower quality will add the more aggressive encode quality step.
aggressiveEncodeQualityStep=3
relaxedEncodeQualityStep=1

# Start the encoding if a current encode is not detected.
if [ $queued -eq 0 ]; then

	interruptedFileEncodeQuality=0

	# When a file starts an encode, it creates a text file in the info folder named the same as the file that contains the number of the encode quality.  If this file exists, start this file again at this encode quality.
	if [ ! $info -eq 0 ]; then

		file="$(ls $path/info/ -1 | head -n 1)"
		interruptedFileEncodingQuality="$(cat $path/info/$file)"
		rm "$path/info/$file"

	else

		# Get the top file in the source directory to shrink if no interrupted file was found.
		file="$(ls $path/source/ -1 | head -n 1)"

	fi

	if [ ! -z "$file" ]; then

		echo "Encoding $path/source/$file"

		# Move the source file into the queue directory, and then start the encoding.
		mv "$path/source/$file" "$path/queue/$file"

		# Whether this is the first iteration of this script will ignore the resulting file size since the first run doesn't have an end file to compare to.
		firstRun=1

		# Find out the result of the file size being between 0.45 and 0.55 by using the basic calculator program to evaluate the decimal numbers.  Script logic can only use integers.  Install this if it is not already installed.
		aboveInnerThresholdLower=0
		belowInnerThresholdUpper=0

		# If the difference is more extreme than 10%, then use these expressions to give a bigger encode quality value so time isn't wasted with an encode that was not aggressive enough.
		aboveOuterThresholdLower=0
		belowOuterThresholdUpper=0

		while [[ $firstRun -eq 1 ]] || [[ $aboveInnerThresholdLower -ne $belowInnerThresholdUpper && $encodeQuality -gt 19 && $encodeQuality -lt 31 ]]; do

			# If file size expressions are 0, then this is the first run, and set the quality to the default.
			if [[ $firstRun -eq 1 ]]; then

				if [ $interruptedFileEncodingQuality -ne 0 ]; then

					encodeQuality=$((interruptedFileEncodingQuality))
					echo "Restarting failed encode at quality $encodeQuality."

				fi

			# If the file size difference is below 35 percent, then use a very aggressive encode quality increase (lower encode quality number).
			elif [ $aboveOuterThresholdLower -eq 0 ]; then 

				echo "Increasing quality - $aggressiveEncodeQualityStep."
				encodeQuality=$((encodeQuality-aggressiveEncodeQualityStep))

			# If the file size difference is above 35 percent but below 45 percent, then give a slight quality increase (lower encode quality number).
			elif [ $aboveOuterThresholdLower -eq 1 ] && [ $aboveInnerThresholdLower -eq 0 ]; then

				echo "Increasing quality - $relaxedEncodeQualityStep."
				encodeQuality=$((encodeQuality-relaxedEncodeQualityStep))

			# If the file size difference is below 65 percent but above 55 percent, then give a slight quality decrease (higher encode quality number).
			elif [ $belowInnerThresholdUpper -eq 0 ] && [ $belowOuterThresholdUpper -eq 1 ]; then

				echo "Decreasing quality + $relaxedEncodeQualityStep."
				encodeQuality=$((encodeQuality+relaxedEncodeQualityStep))

			# If the file size difference is above 65 percent, then use a very aggressive encode quality decrease (higher encode quality number).
			else

				echo "Decreasing quality + $aggressiveEncodeQualityStep."
				encodeQuality=$((encodeQuality+aggressiveEncodeQualityStep))

			fi

			# Create a record of the file and recording level that was used in case that a restart interrupts the current encode, the encoding doesn't start from scratch.
			echo "$encodeQuality" > "$path/info/$file"

			# Encode at quality level 30, which will shave about 60% - 80% of a file's size.  Place the output file in the working directory.
			HandBrakeCLI -i "$path/queue/$file" -o "$path/working/$file" -q $encodeQuality

			# Get the file sizes and calculate the difference in order to zero in on a good encode quality that is about half the original file size.
			cd $path/queue/
			originalFileSize="$(stat -c '%s' *)"

			cd $path/working/
			newFileSize="$(stat -c '%s' *)"

			expression="$(echo $newFileSize / $originalFileSize)"
			expression="$(echo $expression)"

			# Use the basic calculator for evaluating expressions of whether or not the file size difference of the start and end file are within the threshold ranges.
			fileSizeDifference="$(echo $expression | bc -l)"

			expression="$fileSizeDifference >= $innerThresholdLower"
			aboveInnerThresholdLower="$(bc -l <<< $expression)"

			expression="$fileSizeDifference <= $innerThresholdUpper"
			belowInnerThresholdUpper="$(bc -l <<< $expression)"

			expression="$fileSizeDifference >= $outerThresholdLower"
			aboveOuterThresholdLower="$(bc -l <<< $expression)"

			expression="$fileSizeDifference <= $outerThresholdUpper"
			belowOuterThresholdUpper="$(bc -l <<< $expression)"

			firstRun=0
		done

		# Move the completed file to the complete folder, delete the queue file, and delete the info file.
		mv "$path/working/$file" "$path/complete/$file"

		rm "$path/queue/$file"

		rm "$path/info/$file"
	fi

fi
