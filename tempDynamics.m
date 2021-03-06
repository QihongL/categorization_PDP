%% plot the temporal dynamics of the model behavior
% this program relies on the output file of 'testAllActs'
% it is designed to process the output for the verbal representation layer
clear variables; close all; clc 
% MORE ABOUT THE EXPERIEMENT:
% the model sees the visual representation for all objects, and its verbal
% patterns were recorded.

%% CONSTANTS
% clear variables; clf; close all; clc; 
PATH.ABS = '/Users/Qihong/Dropbox/github/categorization_PDP/';
% provide the NAMEs of the data files (user need to set them mannually)
% PATH.DATA= 'sim16_large';
PATH.DATA= 'sim25.2_noVisNoise';

FILENAME.VERBAL = 'verbalAll_e6.txt';
FILENAME.PROTOTYPE = 'PROTO.xlsx';
EPOCH = 2000;
 

%% read data
% read the output data
PATH.FULL = [PATH.ABS PATH.DATA];
% check if the data file exists
if exist([PATH.FULL '/' FILENAME.VERBAL], 'file') == 0
    error([ 'File ' FILENAME.VERBAL ' not found.'])
end
outputFile = tdfread([PATH.FULL '/' FILENAME.VERBAL]);
name = char(fieldnames(outputFile));
output = getfield(outputFile, name);

% output = output(547:end,:); % if run on old data set

% read the prototype pattern, to get some parameters of the simulation
[param, prototype] = readPrototype ([PATH.FULL '/' FILENAME.PROTOTYPE]);
% param.numStimuli = param.numInstances * param.numCategory.sup;

%% preprocessing
% add a zero row at the beginning so that every pattern has equal numRows
output = vertcat( zeros(1,size(output,2)), output);
INTERVAL = size(output,1) / param.numStimuli;
% split the data
data = mat2cell(output, repmat(INTERVAL, [1 param.numStimuli]), size(output,2) );
for i = 1 : size(data,1)
    data{i} = data{i}(:, 3:end);    % remove the 1st & 2nd columns
    data{i} = data{i}(2:end,:);     % remove the 1st row of zeros
end
 
% check the number of stimuli
if param.numStimuli ~= size(output,1) / INTERVAL
    error ('number of stimuli are wrong')
end

%% plot the activation among all units over time 
% for i = 1 : param.numStimuli
%     subplot(param.numCategory.sup,param.numInstances,i)
%     imagesc(data{i})
% end

%% get the 'right' part of the output data
% let's say a model has 60 units that represents classes A, B and C. If
% object A11 only activates the first 20 units. The remaining 40 units will
% not be included when analyzing the activation dynamics of all objects
% that belongs to class A

filteredData = cell(12,1);
currClass = 1;
for i = 1 : param.numStimuli
    % increment the index that controls the peudo-inner loop
    index = mod(i - 1,param.numInstances) + 1;
    
    % check if current class is bigger than the number of super.category
    if(currClass > param.numCategory.sup)
        error('what!?')
    end
    
    % subset the data using the 'right' part of the units
    first = (currClass - 1) * param.numUnits.total + 1;
    last = param.numUnits.total + (currClass -1) * param.numUnits.total;
    % filter by the 'right' class
    filteredData{i} = data{i}(:, first : last);
    % filter by the 'right' set of units
    filteredData{i} = filteredData{i}(:, prototype(index,:));
    
    % print the indices (for debugging purpose)
%     fprintf('%d %d %d to %d\n', i, index, first, last)
    
    % if I have went through all instances in a class...
    if(index == param.numInstances)
        currClass = currClass + 1;  % go to the next class
    end
end

%% plot the activation over time, for relevant units only 
% for i = 1 : param.numStimuli
%     subplot(param.numCategory.sup,param.numInstances, i)
%     imagesc(filteredData{i})
% end


%%  divide the data according to super, basic, and sub level (across all stimuli)

% the parameters here depends on the number of units that suppose to be on
% for each concept level. 
% This can be seen from every prototype pattern. 
% (It assumes every pattern activates the same number of super, basic, sub units)

% pick whatever prototype pattern
onePrototype = prototype(1,:);
% compute the number of units that are on for every conpcet level
on.sup = sum(onePrototype(1:param.numUnits.sup));
on.bas = sum(onePrototype(param.numUnits.sup + 1 : param.numUnits.sup + param.numUnits.bas));
on.sub = sum(onePrototype(param.numUnits.sup + param.numUnits.bas + 1 : param.numUnits.total));

% divide the data according to the concept level
sup = filteredData{1}(:,1:on.sup);
bas = filteredData{1}(:,on.sup + 1 : on.sup + on.bas);
sub = filteredData{1}(:,on.sup + on.bas + 1 : on.sub);
for i = 2:param.numStimuli;
    sup = [sup, filteredData{i}(:,1:on.sup)];
    bas = [bas, filteredData{i}(:,on.sup + 1 : on.sup + on.bas)];
    sub = [sub, filteredData{i}(:,on.sup + on.bas + 1 : on.sup + on.bas + on.sub)];
end

%%  compute the mean activation value for all time points
mSup = mean(sup,2);
mBas = mean(bas,2);
mSub = mean(sub,2);

tpmean = [mSup, mBas, mSub];
relativeProb = bsxfun(@times, tpmean, (1./sum(tpmean,2)));





%% plot the data
p.LW = 4; 
p.FS = 18; 

subplot(1,2,1)
hold on
% plot three temporal activation pattern
plot(mSup,'g', 'linewidth', p.LW)
plot(mBas,'r', 'linewidth', p.LW)
plot(mSub, 'linewidth', p.LW)
% xlim([0 26]);
ylim([0 .7]);
set(gca,'FontSize',p.FS)



legend({'Superordinate', 'Basic', 'Subordinate'}, 'location', 'southeast', 'fontsize', p.FS)
% TITLE = sprintf('Temporal dynamics of verbal responses');
% title(TITLE, 'fontSize', 18);
xlabel('Time Ticks', 'fontSize', p.FS)
ylabel('Activation Value', 'fontSize', p.FS)

hold off



subplot(1,2,2)
hold on
% plot three temporal activation pattern
plot(relativeProb(:,1),'g', 'linewidth', p.LW)
plot(relativeProb(:,2),'r', 'linewidth', p.LW)
plot(relativeProb(:,3), 'linewidth', p.LW)
hold off

title('Selection probability - luce choice', 'fontSize', p.FS)
legend({'Superordinate', 'Basic', 'Subordinate'}, 'location', 'southeast', 'fontsize', p.FS)
xlabel('Time Ticks', 'fontSize', p.FS)
ylabel('Probability', 'fontSize', p.FS)
set(gca,'FontSize',p.FS)