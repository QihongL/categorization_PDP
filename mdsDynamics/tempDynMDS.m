%% Plot MDS solution over time
% initialization
clear variables; clf; close all; clc;
PATH.PROJECT = '/Users/Qihong/Dropbox/github/categorization_PDP/';
% provide the NAMEs of the data files (user need to set them mannually)
PATH.SIMID = 'sim25.2_noVisNoise';
% PATH.SIMID = 'sim25.2_RSVP';
FILENAME.ACT = 'hiddenAll_e2.txt';
FILENAME.PROTOTYPE = 'PROTO.xlsx';

% set parameters
targetTimePt = 25;       % select from int[1,25]
graph.turnOnAxis = false;
graph.attachLabels = 1;
doDynamicPlot = 0;
graph.dimension = 2;
% stimulate properties of EEG
subsetSize = 10;
method = 'spatialBlurring';
method = 'randomSubset';
% method = 'normal';

% set plotting constants
graph.SCALE = 1.2;
graph.FS = 17;
graph.LW = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% start
sprintf('Method: %s.\n', method)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% read data
PATH.PROTOTYPE = genDataPath(PATH, FILENAME.PROTOTYPE);
[param, ~] = readPrototype(PATH.PROTOTYPE);
[data, nTimePts] = importData( PATH, FILENAME, param);
nObjs = param.numStimuli;
% generate index matrix (itermNumber x time)
idx = reshape(1:size(data,1), [nTimePts,nObjs])';
% idx = nan(nObjs, nTimePts);
% for itemNum = 1 : nObjs
%     idx(itemNum,:) = (1 + (itemNum-1) * nTimePts) : (itemNum*nTimePts);
% end


%% plot cluster spreads with in sup vs. bas categories
simSize = 100;
meanSpread = cell(simSize,1);
dataSp = cell(simSize,1);
supMeanSpread.within = zeros(nTimePts,param.numUnits.total*param.numCategory.sup);
basMeanSpread.within = zeros(size(supMeanSpread.within));
% do the simulation n times
for i = 1 : simSize
    dataSp{i} = eegSimulation(data, method, subsetSize, param);
    [meanSpread{i}] = getSpread(dataSp{i}, param, idx, nTimePts);
    supMeanSpread.within = meanSpread{i}.sup.within;
    basMeanSpread.within = meanSpread{i}.bas.within;
    supMeanSpread.bet = meanSpread{i}.sup.bet;
    basMeanSpread.bet = meanSpread{i}.bas.bet;
end
% get average spread
supMeanSpread.within = supMeanSpread.within/simSize;
basMeanSpread.within = basMeanSpread.within/simSize;
supMeanSpread.bet = supMeanSpread.bet/simSize;
basMeanSpread.bet = basMeanSpread.bet/simSize;

% plot the spread
figure(1)
subplot(2,2,1)
hold on
plot(sum(supMeanSpread.within,2), 'linewidth',graph.LW)
plot(sum(basMeanSpread.within,2), 'linewidth',graph.LW)
hold off
legend({'superordinate','basic'}, 'fontsize', graph.FS, 'location', 'southeast')
if strcmp(method,'normal')
    title_spread = sprintf('The within spread: sup vs. basic (method: %s, size: NA)', method);
else
    title_spread = sprintf('The within spread: sup vs. basic (method: %s, size: %d)', method, subsetSize);
end
title(title_spread, 'fontsize', graph.FS)
xlabel('Time', 'fontsize', graph.FS)
ylabel('Sum of the spread', 'fontsize', graph.FS)
set(gca,'FontSize',graph.FS)

% plot the spread
subplot(2,2,2)
hold on
plot(sum(supMeanSpread.bet,2), 'linewidth',graph.LW)
plot(sum(basMeanSpread.bet,2), 'linewidth',graph.LW)
hold off
legend({'superordinate','basic'}, 'fontsize', graph.FS, 'location', 'southeast')
if strcmp(method,'normal')
    title_spread = sprintf('The between spread: sup vs. basic (method: %s, size: NA)', method);
else
    title_spread = sprintf('The between spread: sup vs. basic (method: %s, size: %d)', method, subsetSize);
end
title(title_spread, 'fontsize', graph.FS)
xlabel('Time', 'fontsize', graph.FS)
ylabel('Sum of the spread', 'fontsize', graph.FS)
set(gca,'FontSize',graph.FS)

subplot(2,2,3)
betweenWithinRatio = mean(supMeanSpread.bet .\ supMeanSpread.within,2);
plot(betweenWithinRatio, 'linewidth', graph.LW)
title('Ratio of spread: Between / Within ', 'fontsize', graph.FS)
xlabel('time', 'fontsize', graph.FS)
set(gca,'FontSize',graph.FS)


%% compute 2 dimensional MDS
% simulate eeg-like senario: adding spatial noise or select random subset
data = eegSimulation(data, method, subsetSize, param);
% get unique numbers in the distance matrix
dist.num = pdist(data);
% compute the multidimensional scaling
[Y, evals] = cmdscale(dist.num);

%% plot it!
%% static MDS - 2d
if graph.dimension == 2
    figure(3);
    % final time point MDS
    plot(Y(idx(:,targetTimePt),1),Y(idx(:,targetTimePt),2), 'rx', 'linewidth',graph.LW)
    mdsPlotModifier(Y, param, graph, idx);
    
    % temporal MDS
    figure(4);
    hold on
    for itemNum = 1 : nObjs
        plot(Y(idx(itemNum,:),1),Y(idx(itemNum,:),2), 'g',  'linewidth', graph.LW/2)
        plot(Y(idx(itemNum,:),1),Y(idx(itemNum,:),2), 'b.', 'linewidth', graph.LW)
    end
    % mark the initial and final locations
    plot(Y(idx(:,1),1),Y(idx(:,1),2), 'bx', 'linewidth',graph.LW)
    plot(Y(idx(:,end),1),Y(idx(:,end),2), 'rx', 'linewidth',graph.LW)
    hold off
    mdsPlotModifier(Y, param, graph, idx);
    
    %% hierach. clustering
    %     figure(5);
    %     tree = linkage(pdist(data(idx(:,end),:)));
    %     hc = dendrogram(tree, 'Labels', nameGen(param.numCategory),...
    %         'Orientation','left','ColorThreshold','default');
    %     set(hc,'LineWidth',graph.LW)
    
elseif graph.dimension == 3
    %% static plot - 3d
    figure(4)
    hold on
    for itemNum = 1 : nObjs
        % tarjectory
        plot3(Y(idx(itemNum,:),1),Y(idx(itemNum,:),2), Y(idx(itemNum,:),3), 'g',  'linewidth', graph.LW/2)
        % point
        plot3(Y(idx(itemNum,:),1),Y(idx(itemNum,:),2), Y(idx(itemNum,:),3), 'b.', 'linewidth', graph.LW)
    end
    % mark the initial and final locations
    plot3(Y(idx(:,1),1),Y(idx(:,1),2), Y(idx(:,1),3), 'bx', 'linewidth',graph.LW)
    plot3(Y(idx(:,end),1),Y(idx(:,end),2), Y(idx(:,end),3),'rx', 'linewidth',graph.LW)
    hold off
    mdsPlotModifier(Y, param, graph, idx);
else
    error('Dimension must be 2 OR 3.')
end


%% dynamicaly create MDS solutions
if doDynamicPlot
    figure(6);
    for n = 1 : nObjs
        h{n} = animatedline;
    end
    % setup plotting panel
    axis(max(max(abs(Y))) * [-1,1,-1,1] * graph.SCALE); axis('square');
    
    % y values at time t
    for t = 1:nTimePts
        for n = 1 : nObjs
            % create index the t-th location for n-th object
            th.idx = t + nTimePts * (n-1);
            % add the point
            addpoints(h{n},Y(th.idx,1),Y(th.idx,2)); drawnow;
        end
    end
    mdsPlotModifier(Y, param, graph, idx);
end

