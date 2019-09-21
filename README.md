# Automated UNIX Handbrake-CLI video shrinker

This is a UNIX Bash script that will automatically shrink videos that are placed in a set of folders.  It will take videos loaded into one directory, shrink them to 45% - 55% of their current size, and then delete the original video.  Handbrake-CLI is the video processing program used, but it could be adapted to use any command-line video program.

Handbrake cannot predict the end size of the file, so it will try multiple encodes until reaches the desired half file size.  Since Handbrake seems to randomly restart the machine that this shrinker is running on, it records its current encode settings and will restart with that setting if a system restart is detected instead of from scratch, potentially saving multiple encode cycles of the same file.

This script should be put into the cron (every minute is fine), and if it detects it is currently encoding, then it will not start another encode.

## Installation

The script uses ~/Videos/encode/ as its default folder with the two essential scripts placed here.  This can be changed in the script.  There are five essential sub-folders and one optional sub-folder:

* Source: This is where video files to encode are placed.  File names do not need to conform to any standard.
* Info: This is where an information file about the current encode is placed in order to recover from a system restart.
* Queue: This is where a file is moved to from source and encoded from when the process starts.
* Working: This is where the encoded file is written to.
* Complete: This is where successfully-encoded files are placed.  The originals 
* Stage: Optional folder.  It would be useful to place files here if uploading files remotely via FTP so that the encode process run on a cron does not start an encode on a half-written file.  Move files from here into the source folder.

A second script, resetEncode.bash, needs to be run on system startup.  This will reset any encoding jobs that were run if the system was interrupted.  If it exists, the current encode will be restarted from its last known encode quality.  If this is not run, then an interrupted encode will prevent a new encode process from starting.  The running of a script on startup differs depending on your version of UNIX, so use the method for your distribution.

UNIX Basic Calculator (bc) is also a requirement for this script.  Install it if you do not have it already: https://www.tecmint.com/bc-command-examples/

## Usage

When the scripts and all folders are in place, cron the encode script:

```bash
* * * * * /<path to main encode directory>/encode.bash #
```

## Contributing
Not expecting any contributions, but pull requests or forks are welcome.

## License
GNU General Public License 3.0
