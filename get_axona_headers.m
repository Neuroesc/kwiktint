function [h,d] = get_axona_headers(fname)
% get_dacq_headers  retrieves headers from Axona file formats
% This function reads the headers contained at the top of different Axona files
% They are added to a structure where the structure field names are the header
% names (i.e. 'trial_time' or 'sample_rate') and the values are those given after
% the header. The values are tested to see if they are a) a string, b) a number or
% c) a number followed by a units string like 'Hz'. These are left as strings (a) 
% or converted to double floats (b) with the units removed (c).
%
% USAGE
%
% [h,d] = get_dacq_headers(fname) process with default settings 
%
% INPUT
%
% 'fname' - String, filename, can be full file path
%
% OUTPUT
%
% 'h' - table, header text (column 1) and value (column 2)
%
% 'd' - line number where headers end and data actually starts
%
% NOTES
% 1. 
%
% 2. 
%
% EXAMPLE
% run function using default values
% [h,d] = get_dacq_headers('tint_data.eeg');
% 
% SEE ALSO kwiktint

% HISTORY
%
% version 1.0.0, Release 21/07/17 created to replace completely stupid headerCheck and key_value functions, to allow variable pixel ratio etc
% version 1.1.0, Release 21/07/17 finished .pos and .set conditions
% version 1.2.0, Release 24/07/17 added LED colours and bearings from .set file
% version 1.3.0, Release 24/07/17 added functionality for all file types, realised that they can all be contained in the same loop
% version 1.4.0, Release 24/07/17 regexp has some buggy effects, swicthed to strfind, streamlined conversion of numbers to digits
% version 2.0.0, Release 19/10/21 renamed get_dacq_headers, uses a comparison list and general file reading to collect headers
% version 2.0.1, Release 19/10/21 added comments, tested on different files, working
% version 2.0.1, Release 19/10/21 removed need for comparison lists, function is fully automatic
% version 3.0.0, Release 23/07/25 renamed get_axona_headers to avoid conflicts
% version 3.1.0, Release 23/07/25 changed h to table format
% version 3.1.1, Release 29/11/25 Updates for GitHub release, h now accumulates table rows
% version 3.1.2, Release 29/11/25 datesrt depreciated, replaced with datetime
%
% AUTHOR 
% Roddy Grieves
% University of Glasgow, Sir James Black Building
% Neuroethology and Spatial Cognition Lab
% eMail: roddy.grieves@glasgow.ac.uk
% Copyright 2025 Roddy Grieves

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FUNCTION BODY
    h = table;
    d = 0;
    fid = fopen(fname,'r','ieee-be'); % open file
    if fid < 0
        return
    end    

    line = fgets(fid); % look at the next line of the file (end line = -1)
    ind = 1;
    while line ~= -1 % run through every line until the end, theoretically
        if length(line)>9 & contains('data_start',line(1:10)) 
            d = ind;
            break
        else
            row_now = table(cell(1,1),cell(1,1),'VariableNames', {'header','value'}); % empty table row

            % break the line into the header name, which is the first string (i.e. 'trial_date')
            % and the second part which is the header info (i.e. 'Tuesday, 18 Oct 2021')
            [t,r] = strtok(line);
            row_now.header(1) = { t };
            
            % We test if the header info is completely numeric, if it is we convert to a double float
            % if not we will test if it is a number followed by a space and some units (i.e. '50 Hz')
            % If this is true, we will convert the first number to a double float and drop the units
            r = strtrim( r(2:end) ); % remove whitespaces and return characters at each end of the header info
            if isnan( str2double(r) ) % if the header info contains characters
                c = strsplit(r,' '); % split the info into parts based on whitespaces (i.e. '50 Hz' becomes '50' and 'Hz')
                if isnan( str2double(c{1}) ) % if the info still contains text it can't simply be units, so keep it as a string
                    row_now.value(1) = { r };
                else % if we are just left with numbers it is likely there was just a units string on the end, so convert to double
                    row_now.value(1) = { str2double(c{1}) };
                end
            else % if the header info is all numbers
                row_now.value(1) = { str2double(r) };
            end

            % accumulate
            h = [h; row_now];

            % get next line
            line = fgets(fid);  
        end     
        ind = ind+1;
    end    
    fclose(fid);


































