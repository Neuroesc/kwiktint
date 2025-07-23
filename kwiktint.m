function kwiktint(varargin)
%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DESCRIPTION
% kwiktint  function for running klustakwik on Axona files
% This function prepares an input to the command line and then Tint for unsupervised cluster cutting of data with KlustaKwik. 
% For this function to work, you must have a version of Tint with added command line options (v.4.4.18 and up)
% Once the function has been run a .cut file will be saved alongside the data, more often than not it will be named 'kwiktint_tetrode#.cut', 
% unless you specified a different output name. You can then load the data in TINT as you would normally, and then manually load the 
% .cut file:
%       1) in cluster window click on '...' button next to 'redo exact cut' button
%       2) select the correct .cut file, click yes if tint asks about overwriting previous clusters
%       3) ellipses should now appear over your data
%       4) click 'redo exact cut' 
%       5) click yes again if warned about overwriting
%       6) you should now have kkwiked data
%       7) when finished sorting, click 'save centers'
%       8) click yes to overwrite
%
% USAGE:
%           kwiktint() process files with default settings
%                 'Screening mode'  - If Matlab is in a directory containing only one session (1 .set file) and no inputs are given this function 
%                                     will automatically analyse that session and look for all tetrodes. Output files are named 'kwiktint'.
%                 'Experiment mode' - If multiple .set files are present the function will ask the user to identify which sessions to analyse. It will then assume 
%                                     these sessions should be kkwiked together and that all tetrodes should be analysed. Output files are named 'kwiktint'.
%                 'Batch mode'      - If you wish to kkwik multiple sessions, but keep the outputs seperate and in different .cut files then run the function with the 'combine' 
%                                     input set to 0. The function will continue to ask which sessions should be analysed, but these will be kkwiked seperately. 
%                                     Output files are named after each original session name, to avoid overwriting anything
%
%           kwiktint(Name,Value,...) process with Name-Value pairs used to control aspects 
%           of the cluster cutting
%
%           Parameters include:
%
%           'combine'          -   (default = true) Logical or scalar, set to 1 or true to combine multiple .set files into one output, set to 0 or false to analyse sessions individually
%                                  If sessions are to be combined, they should be named in numerically or alphabetically ascending order, matching the order they 
%                                  were recorded. TINT will always order them in this way when they are opened or kkwiked, so for continuity they should be named this way.
%                                  I name recordings using this convention: [date in format yymmdd][a-z order of recording]_[name of maze]
%
%           'tetrodes'         -   (default = 1:16) Vector of tetrodes to be analysed i.e. [1 2 3 4], the function will run on the included tetrodes if they are available, missing tetrodes are ignored
%
%           'outname'          -   (default = 'kwiktint') String, the file name to use for combined outputs
%
%           'assume_all_set'   -   (default = true) Logical or scalar, set this to 1 or true and the function will always just assume you want to analyse all available .set files, it will not ask you to select them
%                                  I always separate sessions (i.e. all the recordings related to one data collection) into different directories, so I always want to combine all .set files in a directory
%                                  Some people have other conventions like saving all of the recordings for a day in a directory, in which case they would need to specify the files each time
%
%           'backup_cuts'      -   (default = true) Logical or scalar, set to 1 or true and kwiktint will backup .cut files if they already exist, the backups are named with the exact date/time they are backed up
%                                  appended at the end of the extension and saved in a 'kwiktint' directory alongside the data
%
%           'max_tp'           -   (default = 3) Scalar specifying how many tetrodes can be analysed simultaneously or how many instances of TINT can be open simultaneously, includes ones opened by the user.
%                                  This means if you open a copy of TINT manually to do some manual cluster cutting etc klustakwik will only run max_tp-1 copies of TINT.
%
% EXAMPLES:
%
%           % run function using default values
%           kwiktint()
%
%           % run function using default values, but only on tetrodes 1 and 5
%           kwiktint('tetrodes',[1 5])
%
%           % run function using default values, all specified
%           kwiktint('combine',1,'tetrodes',1:16,'outname','kwiktint','assume_all_set',1,'backup_cuts',1,'max_tp',3)
%

% HISTORY:
% version 1.0.0, Release 03/08/16 Initial release
% version 1.1.0, Release 03/08/16 removed the need for a batch file, function calls system directly
% version 1.1.1, Release 03/08/16 added max_cpu option where cmd is called continuously, without waiting for KK to finish
% version 1.2.0, Release 04/08/16 added .cut file saving
% version 1.2.1, Release 05/08/16 added comments, created getSET and getTRODES to relieve some text
% version 1.2.2, Release 08/08/16 fixed bug with .cut file saving
% version 1.3.0, Release 08/08/16 added saving system calls, added saving outputs using combined filename for ease of use with other functions
% version 1.4.0, Release 31/10/16 added ability to KKwik files in seperate directories, output will be put in current directiry (if combining) or the original directories (if analysed seperately)
% version 2.0.0, Release 31/10/16 version 2 created, major overhaul, for klustering distal directories
% version 2.0.1, Release 01/11/16 changed the directories in which the outputs are saved to make further analysis easier
% version 2.1.0, Release 15/02/17 changed output default so files are saved with the name 'kwiktint', this is optional though
% version 2.2.0, Release 16/02/17 fixed bug in directory saving/creation and collected all outputs into folder named using 'out_name'
% version 2.2.1, Release 17/02/17 cleaned up comments and help, added 'out_name' as an input for people who what to kkwik different combinations of sessions in the same directory
% version 2.2.2, Release 20/03/17 updated and cleaned for distribution
% version 2.3.0, Release 11/04/17 simplified idata creation and amalgamated this with .set detection, changed to use getSNAMES
% version 2.3.1, Release 12/04/17 fixed bug in idata cell array
% version 2.4.0, Release 20/06/17 added klustakwik options
% version 2.5.0, Release 12/11/17 replaced getTRODES with legacy copy, will fix this better in future
% version 2.6.0, Release 20/06/19 added display of spike count when cluster cutting and an ETA for completion
% version 3.0.0, Release 31/12/19 version 3, added name value pair arguments, improved comments, 
% version 3.1.0, Release 31/12/19 function can run on multiple tetrodes simultaneously, up to a maximum limit
% version 3.2.0, Release 06/10/21 minor comments for packaging / git upload
%
% Author: Roddy Grieves
% UCL & Dartmouth College
% eMail: roddy.m.grieves@dartmouth.edu
% Copyright 2016 Roddy Grieves
%
% for questions about Tint:
% http://www.axona.com/contact-us

%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> INPUT ARGUMENTS CHECK
%% Parse inputs
    p = inputParser;
    addOptional(p,'combine',true,@(x) numel(x)>~1 & (isnumeric(x)|islogical(x)) );  
    addOptional(p,'tetrodes',1:16,@(x) isnumeric(x) ); 
    addOptional(p,'outname','kwiktint',@(x) isstring(x) );   
    addOptional(p,'assume_all_set',true,@(x) numel(x)>~1 & (isnumeric(x)|islogical(x)) );  
    addOptional(p,'backup_cuts',true,@(x) numel(x)>~1 & (isnumeric(x)|islogical(x)) );  
    addOptional(p,'max_tp',2,@(x) isnumeric(x) ); 
    addOptional(p,'skip_grounded',false,@(x) numel(x)>~1 & (isnumeric(x)|islogical(x)) );  
    parse(p,varargin{:});
    config = p.Results;

%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> KLUSTAKWIK SETUP
% features - here you can change which features klustakwik (through TINT) will use to cluster the spike data
    kkfet = struct;
    kkfet.channels                      = [1 2 3 4]; % tetrode channels to use, enter a zero in place of a channel you want to remove
    kkfet.PC1                           = 1; % use first principal component
    kkfet.PC2                           = 1; % use second principal component
    kkfet.PC3                           = 1; % use third principal component
    kkfet.PC4                           = 0; % use fourth principal component
    kkfet.A                             = 1; % use spike amplitude
    kkfet.Vt                            = 0; % use height at time t
    kkfet.P                             = 0; % use height of peak
    kkfet.T                             = 0; % use depth of trough
    kkfet.tP                            = 0; % use time of peak
    kkfet.tT                            = 0; % use time of trough
    kkfet.En                            = 0; % use energy (L2 norm)
    kkfet.Ar                            = 0; % use area under waveform (L1 norm)
    kkfet.names                         = {'PC1','PC2','PC3','PC4','A','Vt','P','T','tP','tT','En','Ar'};
    kkfet.string                        = [kkfet.PC1 kkfet.PC2 kkfet.PC3 kkfet.PC4 kkfet.A kkfet.Vt kkfet.P kkfet.T kkfet.tP kkfet.tT kkfet.En kkfet.Ar];

% parameters - these are parameters used to refine the klustakwik process
    kkset = struct;
    kkset.Screen                        = 1; % (default 1) Set this value to 1 if you want the progress messages from KlustaKwik to appear in a command window on the PC. Set to 0 to see no command window output.
    kkset.Verbose                       = 0; % (default 0) Set this value to 1 if you want detailed progress messages from KlustaKwik. Set to 0 for shorter messages.
    kkset.Log                           = 1; % (default 1) Set this value to 1 if you want a .klg.N log file to be produced by KlustaKwik. Set to 0 if you don't want a log.
    kkset.MaxPossibleClusters           = 30; % (default 30) The largest permitted number of clusters, so cluster splitting can produce no more than n clusters. TINT can only support up to 90 clusters
    kkset.nStarts                       = 1; % (default 1) The algorithm will be started n times for each inital cluster count between MinClusters and MaxClusters
    kkset.RandomSeed                    = 1; % Specifies a seed for the random number generator.
    kkset.DistThresh                    = 6.907755; % (default 6.907755) Time-saving parameter. If a point has log likelihood more than d worse for a given class than for the best class, the log likelihood for that class is not recalculated. This saves an awful lot of time.
    kkset.ChangedThresh                 = 0.05; % (default 0.05) All log-likelihoods are recalculated if the fraction of instances changing class exceeds f (see DistThresh)
    kkset.FullStepEvery                 = 10; % (default 10) All log-likelihoods are recalculated every n steps (see DistThresh).
    kkset.MaxIter                       = 500; % (default 500) Maximum number of iterations. ie. it won't try more than n iterations from any starting point.
    kkset.SplitEvery                    = 40; % (default 40) Test to see if any clusters should be split every n steps. 0 completely suppresses splitting altogether.
    kkset.Subset                        = 1; % not explained
    kkset.PenaltyK                      = 1; % (default 1) The higher PenaltyK and PenaltyKLogN are, the fewer clusters you obtain. Higher penalties discourage cluster splitting. 
    kkset.PenaltyKLogN                  = 0; % (default 0) PenaltyKLogN increases penalty when there are more points.
    kkset.UseDistributional             = 1; % (default 1) To use KlustaKwik in "masked" mode, set this to 1. This enables the use of the new `masked Expectation-Maximization' algorithm.
    kkset.UseMaskedInitialConditions    = 1; % (default 1) Initialises using distinct derived binary masks. Use together with AssignToFirstClosestMask below.
    kkset.AssignToFirstClosestMask      = 1; % (default 1) If starting with a number of clusters fewer than the number of distinct derived binary masks, it will assign the rest of the points to the cluster with the nearest mask.
    kkset.PriorPoint                    = 1; % (default 1) Helps normalize covariance matrices.
    sptfactor                           = 0.0015; % (default = 0.0015) multiply number of spikes by this factor to estimate time till completion    
    disp(sprintf('\t...see <a href="https://github.com/klusta-team/klustakwik">https://github.com/klusta-team/klustakwik</a> for klustakwik details'))
    % Kadir SN, Goodman DFM, Harris KD (2014). High-dimensional cluster analysis with the masked EM algorithm. Neural Computation 26:11. doi:10.1162/NECO_a_00661

%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> PREPARE DATA
% get some session data
    disp(sprintf('Identifying sessions...')); tic;

    % get .set file names
    setdirs = dir('*.set');
    if numel(setdirs) == 1
        config.assume_all_set = 1;
    end
    [snames,~,~,fnames] = getSNAMES(config.assume_all_set);

    % sort out how to proceed
    idata = cell(1,4);
    if isempty(fnames)
        setdirs = dir('*.set');
        keyboard

    elseif length(fnames) == 1
        combine = 1;
        disp(sprintf('\t...only 1 .set file detected: %s',snames{1}))
        disp(sprintf('\t...will analyse session into .cut files named: %s',config.outname));
        idata(1,1:4) = {fnames{1},config.outname,pwd,pwd};
    elseif length(fnames) > 1
        disp(sprintf('\t...multiple .set files detected: ')) 
        for ff = 1:length(fnames)
            disp(sprintf('\b%s ',[snames{ff} '.set']))
        end
        if config.combine
            disp(sprintf('\t...will analyse multiple sessions into .cut files named: %s',config.outname)); 
            dat_to_load = [];
            for ff = 1:length(snames) % for each selected session
                if isempty(dat_to_load)        
                    dat_to_load = fnames{ff};   
                else
                    dat_to_load = [dat_to_load ',' fnames{ff}];
                end
                idata(1,1:4) = {dat_to_load,config.outname,pwd,pwd};
            end     
        else
            disp(sprintf('\t...will analyse multiple sessions into separate .cut files'));  
            for ff = 1:length(fnames) % for each selected session
                idata(ff,1:4) = {fnames{ff},snames{ff},pwd,pwd}; 
            end
        end
    end

    % we need to work out which channels were grounded or are dead, so these can be removed from the klustakwik procedure. This information is also saved
    disp(sprintf('Finding dead channels...'))
    [~,nme,~] = fileparts(snames{1});
    [dedch,eegch,grdch] = readSET([pwd '\' nme '.set']); % open first .set file to find dead channels - these shouldn't change and Tint can't handle it if they do anyway
    disp(sprintf('\t...eeg: %s',mat2str(eegch')))
    disp(sprintf('\t...grounded: %s',mat2str(grdch')))
    deads_index = repmat(kkfet.channels,1,16); % create a matrix with 1:4 for each tetrode
    deads_index(dedch) = 0; % make dead channels equal zero
    deads_mat = reshape(deads_index',4,[]); % each column now represents a tetrode, we will use this matrix later to remove dead channels

%% >>>>>>>>>> Connect to TINT   
    % messages for the user
    disp(sprintf('Starting analysis...'))
    f_start = tic;
    disp(sprintf(['\t...analysis starting at: ',datestr(now)]));  
    if ~config.combine
        disp(sprintf('\t...will analyse sessions into seperate .cut files'));
    elseif config.combine == 1
        disp(sprintf('\t...will combine sessions into one .cut file and output as: %s',config.outname));
    elseif config.combine == 3
        disp(sprintf('\t...will analyse sessions into seperate .cut files'));
    end 
    disp(sprintf('\t...will attempt to analyse tetrodes: %s',mat2str(config.tetrodes)));

    % connect with TINT - we will try to find tint in the default install directory, if it isn't there we will search through the program files directory
    % this latter method will generally take longer
    tint_location = 'C:\Program Files (x86)\Axona\Tint\Tint.exe';
    disp(sprintf('Connecting to TINT...'))
    if exist(tint_location,'file')
        disp(sprintf('\t...TINT found at: %s',tint_location));
    else
        disp(sprintf('\t...TINT not found at: %s',tint_location));
        disp(sprintf('\t...searching program files, please wait'));
        [failed,tpath] = system('WHERE /F /R "C:\Program Files (x86)" Tint.exe'); % try to find tint
        qindx = strfind(tpath,'"');
        tint_location = tpath(qindx(1)+1:qindx(2)-1); % take the first copy of tint found
        if failed
            error('ERROR: cannot find TINT, please install in the default directory or manually edit tint_location in kwiktint... exiting')
        else
            disp(sprintf('\t...TINT found at: %s',tint_location));
            disp(sprintf('\t...for increased speed install TINT in the default directory or manually change tint_location in kwiktint'));
        end 
    end     
    
%% >>>>>>>>>>>>>>>>>>>> Check the available tetrodes
    % this is just a standard process to determine which tetrode files actually exist
    % this means the function can be run as default with all tetrodes (1:16) selected, this vector will then be refined here
    disp(sprintf('Assessing data...'))
    
    tin = config.tetrodes;    
    fcheck = NaN(length(snames),length(tin));
    for tt = 1:length(tin) % for each requested tetrode
        ctet = tin(tt);
        for ff = 1:length(snames) % for each selected session
            csess = snames{ff};
            [pst,nme,~] = fileparts(csess);
            efile = exist([pst '\' nme '.' num2str(ctet)],'file');
            fcheck(ff,tt) = efile;
        end
    end
    scheck = logical(prod(fcheck,1));
    mvalue = setdiff(tin,tin(scheck)); % find any missing values
    tetrodes = tin(scheck);    

    if isempty(mvalue)
        disp(sprintf('\t...tetrodes %s accounted for',mat2str(tetrodes)))
    else
        disp(sprintf('\t...tetrodes %s accounted for',mat2str(tetrodes)))
        disp(sprintf('\t...WARNING: tetrodes %s are incomplete and will be skipped',mat2str(mvalue)))
    end 
    disp(sprintf('\t...done'))    

%% >>>>>>>>>> Prepare instructions for TINT
    % basically to run TINT just requires specific text arranged in a specific way, this function just provides a convenient wrapper for arranging this text.
    % here these text files will begin to take shape
    disp(sprintf('Running klustakwik...'))

    disp(sprintf('\tMaxPossClust=%d, MaxIter=%d, PenaltyK=%d, PenaltyKlogN=%d',kkset.MaxPossibleClusters,kkset.MaxIter,kkset.PenaltyK,kkset.PenaltyKLogN));
    disp(sprintf('\tPC1=%d, PC2=%d, PC3=%d, PC4=%d, A=%d, Vt=%d, P=%d, T=%d, tP=%d, tT=%d, En=%d, Ar=%d',kkfet.PC1,kkfet.PC2,kkfet.PC3,kkfet.PC4,kkfet.A,kkfet.Vt,kkfet.P,kkfet.T,kkfet.tP,kkfet.tT,kkfet.En,kkfet.Ar));
    disp(sprintf('\tScreen=%d, Verbose=%d, Log=%d',kkset.Screen,kkset.Verbose,kkset.Log));

    % actually run kkwik on each file
    [~,~,~] = mkdir([idata{1,4} '\kwiktint']);
    sysname = [idata{1,4} '\kwiktint\TINT_system_calls.txt'];
    fileID1 = fopen(sysname,'a'); % I think it would be useful to have a record of all system calls, this file will contain them
    for ss = 1:length(idata(:,1)) % for each tint session or row of idata
        dat_to_load = idata{ss,1};
        name_now = idata{ss,2};
        out_dir = idata{ss,4};
        if isempty(dat_to_load) || isempty(name_now) || isempty(out_dir)
            continue
        end 

        % display which session(s) we are analysing now
        if config.combine
            disp(sprintf('\t...analysing sessions: %s together',name_now))
            disp(sprintf('\t...will output to: %s',[out_dir '\kwiktint\' name_now]))
        else
            disp(sprintf('\t...analysing session: %s seperately',name_now))
            disp(sprintf('\t...will output to: %s',[out_dir '\kwiktint\' name_now]))        
        end 

        % generate the full system string with the required tetrode
        com_strs = cell(length(tetrodes));
        for tt = 1:length(tetrodes) % for each requested tetrode
            tnow = tetrodes(tt);
            disp(sprintf('\t\tTetrode: %d...',tnow))
            nspikes = findNSPIKES(snames,tnow);
            disp(sprintf('\t\t\t...%d spikes detected (ETA: %.fs)',nspikes,nspikes*sptfactor)); % the nspikes are multiplied by a s/spike factor, this can be changed per system

            % backup .cut files if we are overwriting them
            cutname1 = [out_dir '\' name_now '_' num2str(tnow) '.cut'];
            cutname2 = [cutname1 '_' datestr(now,30)];
            if exist(cutname1,'file') && config.backup_cuts
                copyfile(cutname1,cutname2,'f');
            end 

            %% Generate the klustakwik options file
            kk_fname = ['Filename=' out_dir '\' name_now];
            kk_params = ['KKparamstr=-Verbose ' num2str(kkset.Verbose) ' -Log ' num2str(kkset.Log) ' -Screen ' num2str(kkset.Screen) ' -MaxPossibleClusters ' num2str(kkset.MaxPossibleClusters) ' -nStarts ' num2str(kkset.nStarts) ' -RandomSeed ' num2str(kkset.RandomSeed) ' -DistThresh ' num2str(kkset.DistThresh,10) ' -FullStepEvery ' num2str(kkset.FullStepEvery) ' -ChangedThresh ' num2str(kkset.ChangedThresh,10) ' -MaxIter ' num2str(kkset.MaxIter,10) ' -SplitEvery ' num2str(kkset.SplitEvery,10) ' -Subset ' num2str(kkset.Subset) ' -PenaltyK ' num2str(kkset.PenaltyK,10) ' -PenaltyKLogN ' num2str(kkset.PenaltyKLogN,10) ' -UseDistributional ' num2str(kkset.UseDistributional) ' -UseMaskedInitialConditions ' num2str(kkset.UseMaskedInitialConditions) ' -AssignToFirstClosestMask ' num2str(kkset.AssignToFirstClosestMask) ' -PriorPoint ' num2str(kkset.PriorPoint)];
            kk_features = sprintf('PC1=%d\nPC2=%d\nPC3=%d\nPC4=%d\nA=%d\nVt=%d\nP=%d\nT=%d\ntP=%d\ntT=%d\nEn=%d\nAr=%d',kkfet.PC1,kkfet.PC2,kkfet.PC3,kkfet.PC4,kkfet.A,kkfet.Vt,kkfet.P,kkfet.T,kkfet.tP,kkfet.tT,kkfet.En,kkfet.Ar);
            kk_reports = sprintf('Screen=%d\nVerbose=%d\nLog=%d',kkset.Screen,kkset.Verbose,kkset.Log);

            channs = deads_mat(:,tnow); 
            % when converting Neuralynx files to Tint format the .set files are mostly empty
            % this wrongly makes it seem like all the channels are grounded. Here we disable
            % this and assume all channels are working
            if ~config.skip_grounded % if we don't care about grounded channels
                dindx = reshape(repmat(1:4,1,16)',4,[]); % create a matrix with 1:4 for each tetrode
                channs = dindx(:,tnow);
            end
            
            if ~sum(channs)
                disp(sprintf('\t\t\t...grounded, skipping'))
                continue
            end 
            
            kk_channels = [];
            for i = 1:4
                if ismember(i,channs) && i~=4
                    kk_channels = [kk_channels, sprintf('%s=1\n',num2str(i))];
                elseif ismember(i,channs) && i==4
                    kk_channels = [kk_channels, sprintf('%s=1',num2str(i))]; 
                elseif ~ismember(i,channs) && i~=4
                    kk_channels = [kk_channels, sprintf('%s=0\n',num2str(i))];
                elseif ~ismember(i,channs) && i==4
                    kk_channels = [kk_channels, sprintf('%s=0',num2str(i))]; 
                end 
            end 

            %% write the .ini file
            % the .ini file holds the klustakwik option for TINT, it isn't necessary as TINT will default to principal components, but we produce it every time just to be sure
            iname = [out_dir '\kwiktint\TINT_input_' name_now '_' num2str(tnow) '.ini'];
            fileID = fopen(iname,'w');
            if config.combine % if we are combining files, use the output name 'merge', else, just use the original filename (default)
                fprintf(fileID,'%s\n','[Main]',kk_fname,kk_params,'[IncludeChannels]',kk_channels,'[ClusteringFeatures]',kk_features,'[Reporting]',kk_reports);
            else
                fprintf(fileID,'%s\n','[Main]',kk_params,'[IncludeChannels]',kk_channels,'[ClusteringFeatures]',kk_features,'[Reporting]',kk_reports);
            end
            fclose(fileID);
            save([out_dir '\kwiktint\' name_now '.kk'],'kkfet','kkset'); % also save a mat file containing the data

            %% Prepare inputs for Tint
            % run_line is the actual command line that will be used with command prompt to run TINT and load the appropriate settings
            % the .text file generated here is just a record of what the run_line states, mainly for debugging
            logname = [out_dir '\kwiktint\TINT_output_' name_now '_' num2str(tnow) '.txt']; 
            run_line = ['"' tint_location '" ' '"' dat_to_load '" ' '"' num2str(tetrodes(tt)) '" ' '"' logname '" ' '"/convertkk2cut" "/runKK" ' '"/KKoptions"' ' "' iname '"'];
            fprintf(fileID1,'%s\n','[run_line]',run_line);

            %% Display which channels were not included and save this info
            dindx = find(channs == 0);
            if ~isempty(dindx)
                disp(sprintf('\t\t\t...channel(s) excluded: %s',mat2str(dindx)))
            end 
            save([out_dir '\kwiktint\' name_now '_channel_data.mat'],'dedch','eegch','grdch','-v7.3'); % save channel and eeg data

            %% Run klustakwik
            if config.max_tp > 1
                % get the process ID (pid) for all running Tint processes        
                disp(sprintf('\t\t\t...queued')) 
                p = System.Diagnostics.Process.GetProcessesByName('Tint'); % find already running Tint processes  
                tnum = p.Length;
                while tnum >= config.max_tp
                    p = System.Diagnostics.Process.GetProcessesByName('Tint'); % find already running Tint processes  
                    tnum = p.Length;
                    pause(1);
                end        
                % the 'system' command is one way to run things on the O.S. or in command prompt (outside Matlab basically)
                disp(sprintf('\t\t\t...klustakwiking'))
                system([run_line '&']);          
            else
                % the 'system' command is one way to run things on the O.S. or in command prompt (outside Matlab basically)
                disp(sprintf('\t\t\t...klustakwiking'))
                k_start = tic;
                system(run_line);          
                disp(sprintf('\t\t\t...done (%.2fs)',toc(k_start)))              
            end
        end 
    end 
    fclose(fileID1);
    disp(sprintf('\t...done'))

%% >>>>>>>>>> Final Messages
    analysis_log({'kwiktint'},1,'version',{'v3.2.0'});
    fclose('all');
    toc1 = toc/60;
    disp(sprintf('Kwiktint has finished. It took %0.3f seconds or %0.3f minutes',toc,toc1)) % Stop counting time and display results
    disp(['Go to ','<a href = "matlab: [s,r] = system(''explorer ',cd,' &'');">','current folder','</a>'])
    disp(['Open ','<a href = "matlab: [s,r] = system(''explorer ',tint_location,' &'');">','TINT','</a>'])
    disp('----------------------------------------------------------------------------');

end % end of kwiktint


%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> getSNAMES
function [snames,cname,nsess,fnames] = getSNAMES(get_all)
    %   This function just gathers some session names by asking the user to select .set files
    %   it outputs some useful forms of this info
    %   [snames,cname,nsess] = getSNAMES
    if ~exist('get_all','var') || isempty(get_all)
        get_all = 0;
        return
    end
    
%% >>>>>>>>>> Find sessions
    if get_all
        snames = dir('*.set');
        if ~numel(snames)
            disp(sprintf('\tWARNING: no .set files detected...'));
            
            tnames = dir('*.ntt');
            if numel(tnames)>0 % if there are Neuralynx files
                disp(sprintf('\tNeuralynx files detected, attempting conversion...')); 
                disp(sprintf('\tWARNING: this will only work on Neuralynx files with default filenames, concatenation will NOT take place...'));
                
                % connect with NL2Tint - we will try to find tint in the default install directory, if it isn't there we will search through the program files directory
                % this latter method will generally take longer
                nl2tint_location = 'C:\Program Files (x86)\Axona\Tint\NL2Tint\NL2Tint.exe';                    
                disp(sprintf('\t\t...connecting to NL2Tint'))
                if exist(nl2tint_location,'file')
                    disp(sprintf('\t\t...NL2Tint found at: %s',nl2tint_location));
                else
                    disp(sprintf('\t\t...NL2Tint not found at: %s',nl2tint_location));
                    disp(sprintf('\t\t...searching program files, please wait'));
                    [failed,tpath] = system('WHERE /F /R "C:\Program Files (x86)" NL2Tint.exe'); % try to find tint
                    qindx = strfind(tpath,'"');
                    nl2tint_location = tpath(qindx(1)+1:qindx(2)-1); % take the first copy of tint found
                    if failed
                        error('\t\tERROR: cannot find NL2Tint, please install in the default directory or manually edit nl2tint_location in kwiktint... exiting')
                    else
                        disp(sprintf('\t\t...NL2Tint found at: %s',nl2tint_location));
                        disp(sprintf('\t\t...for increased speed install NL2Tint in the default directory or manually change nl2tint_location in kwiktint'));
                    end 
                end                  
                
                disp(sprintf('\t\t...converting'))
                run_line = ['"' nl2tint_location '" ' '/dir ' '"' pwd '"'];
                system(run_line);    
                
                snames = dir('*.set');                
            end
            if ~numel(snames)
                error('\t\tERROR: no .set files detected & Neuralynx conversion failed...');
            end
        end
        snames = {snames(:).name};
        snames = snames(:);
    else
        snames = uipickfiles('FilterSpec','*.set','Output','cell','Prompt','Select the sessions to analyse...');
    end 
    nsess = numel(snames);

%% >>>>>>>>>> sort out parameters for later and reduce .set file names
    fnames = {};
    if length(snames) == 1
        nnow = snames{1};
        [~,nme,~] = fileparts(nnow);
        cname = nme;  
        snames{1} = nme;    
        fnames{1} = [pwd '\' nme];
    else
        for ff = 1:length(snames)
            nnow = snames{ff};
            [~,nme,~] = fileparts(nnow);
            snames{ff} = nme;
            fnames{ff} = [pwd '\' nme];
            if ff == 1 % the first filename
                cname = nme;
            elseif ff == length(snames) % the last filename
                cname = [cname '_' nme];
            else % middle filenames
                cname = [cname '_' nme '_'];
            end 
        end 
    end 
    
end % end of getSNAMES


%% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> findNSPIKES
function nspikes = findNSPIKES(filenames,tet)
    if ~exist('filenames','var') || isempty(filenames)
        nspikes = -1;
        return
    end

%% >>>>>>>>>> Find number of spikes
    nspikes = 0;
    for ss = 1:length(filenames)
        filename = [filenames{ss} '.' num2str(tet)];

        % open spike file
        fid = fopen(filename,'r','ieee-be');
        if (fid < 0)
            fclose(fid);
            return
        end    

        % read all bytes, look for 'data_start'
        fseek(fid,0,-1);
        sresult = 0;
        [bytebuffer,bytecount] = fread(fid,inf,'uint8');
        for ii = 10:length(bytebuffer)
            if strcmp(char(bytebuffer((ii-9):ii))','data_start')
                sresult = 1;
                break
            end
        end
        if ~sresult
            fclose(fid);
            return
        end

        % find line with spike number
        fseek(fid,0,-1);
        while ~feof(fid)
            txt = fgetl(fid);
            if length(regexp(txt,'^num_spikes.*'))
                nspikes = nspikes + sscanf(txt,'%*s %d');    
                break
            end
        end   
        fclose(fid);
    end
    
end % end of findNSPIKES


























