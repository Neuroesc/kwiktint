# kwiktint
Kwiktint automated cluster cutting with Klustakwik via Tint

This function prepares an input to the command line and then Tint for unsupervised cluster cutting of data with KlustaKwik. 
> [!NOTE]
> For this function to work, you must have a version of Tint with added command line options (v.4.4.18 and up).  
Once the function has been run a .cut file will be saved alongside the data, more often than not it will be named 'kwiktint_tetrode#.cut', unless you specified a different output name. You can then load the data in TINT as you would normally, and then manually load the .cut file:
1) in cluster window click on '...' button next to 'redo exact cut' button
2) select the correct .cut file, click yes if tint asks about overwriting previous clusters
3) ellipses should now appear over your data
4) click 'redo exact cut' 
5) click yes again if warned about overwriting
6) you should now have kkwiked data
7) when finished sorting, click 'save centers'
8) click yes to overwrite

# Usage
process files with default settings:
```
kwiktint()
```

'Screening mode'  - If Matlab is in a directory containing only one session (1 .set file) and no inputs are given this function will automatically analyse that session and look for all tetrodes. Output files are named 'kwiktint'.  

'Experiment mode' - If multiple .set files are present the function will ask the user to identify which sessions to analyse. It will then assume these sessions should be kkwiked together and that all tetrodes should be analysed. Output files are named 'kwiktint'.  

'Batch mode'      - If you wish to kkwik multiple sessions, but keep the outputs seperate and in different .cut files then run the function with the 'combine' input set to 0. The function will continue to ask which sessions should be analysed, but these will be kkwiked seperately. Output files are named after each original session name, to avoid overwriting anything  

process with Name-Value pairs used to control aspects of the cluster cutting:
```
kwiktint(Name,Value,...)
```

# Parameters

'combine'          -   (default = true) Logical or scalar, set to 1 or true to combine multiple .set files into one output, set to 0 or false to analyse sessions individually. If sessions are to be combined, they should be named in numerically or alphabetically ascending order, matching the order they were recorded. TINT will always order them in this way when they are opened or kkwiked, so for continuity they should be named this way. I name recordings using this convention:
>(date in format yymmdd)(a-z order of recording)_(name of maze)

'tetrodes'         -   (default = 1:16) Vector of tetrodes to be analysed i.e. [1 2 3 4], the function will run on the included tetrodes if they are available, missing tetrodes are ignored

'outname'          -   (default = 'kwiktint') String, the file name to use for combined outputs

'assume_all_set'   -   (default = true) Logical or scalar, set this to 1 or true and the function will always just assume you want to analyse all available .set files, it will not ask you to select them I always separate sessions (i.e. all the recordings related to one data collection) into different directories, so I always want to combine all .set files in a directory. Some people have other conventions like saving all of the recordings for a day in a directory, in which case they would need to specify the files each time

'backup_cuts'      -   (default = true) Logical or scalar, set to 1 or true and kwiktint will backup .cut files if they already exist, the backups are named with the exact date/time they are backed up appended at the end of the extension and saved in a 'kwiktint' directory alongside the data

'max_tp'           -   (default = 3) Scalar specifying how many tetrodes can be analysed simultaneously or how many instances of TINT can be open simultaneously, includes ones opened by the user. This means if you open a copy of TINT manually to do some manual cluster cutting etc klustakwik will only run max_tp-1 copies of TINT.

# Examples
run function using default values
```
kwiktint()
```
run function using default values, but only on tetrodes 1 and 5
```
kwiktint('tetrodes',[1 5])
```
run function using default values, all specified
```
kwiktint('combine',1,'tetrodes',1:16,'outname','kwiktint','assume_all_set',1,'backup_cuts',1,'max_tp',3)
```
