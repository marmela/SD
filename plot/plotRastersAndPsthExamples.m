function plotRastersAndPsthExamples(exampleData, positionsPerPanel, ...
    statesToPlotClickRaster, figProperties, clicks, shadingProperties, isRemFig)

if (~exist('isRemFig','var'))
    isRemFig = false;
end

MS_IN_SEC = 1000;
%% Plot Rasters+PSTHs examples
nClickRasters = length(clicks.iRateToPlot);
nStatesToPlot = length(statesToPlotClickRaster);
timesMs = exampleData.timeMs;

minFr = Inf;
maxFr = -Inf;
for iRaster = 1:nClickRasters
    iClickRate = clicks.iRateToPlot(iRaster);
    for iState = 1:nStatesToPlot
        currentPsth = exampleData.psthPerStimAndState{iClickRate,iState};
        maxFr = max(maxFr,max(currentPsth));
    end
end
yLimToUsePsth = [0,ceil(maxFr)];


for iRaster = 1:nClickRasters
    iClickRate = clicks.iRateToPlot(iRaster);
    %% PSTH Subplot
    subplot('position',positionsPerPanel.psth{iRaster})
    hold on;
    stateStr = extractfield(statesToPlotClickRaster,'str');
    iRemState = find(strcmp(stateStr,'REM'));
    if ~isempty(iRemState)
        iStatesOrder = [iRemState, 1:iRemState-1, iRemState+1:nStatesToPlot];
    else
        iStatesOrder = 1:nStatesToPlot;
    end
    for iState = iStatesOrder
        plot(timesMs,exampleData.psthPerStimAndState{iClickRate,iState},...
            'color',statesToPlotClickRaster(iState).color,'LineWidth',figProperties.psthLineWidth);
    end
    if iRaster==1
        ylabel('Spikes/s'); %'Firing Rate (spks/s)')
    else
        set(gca,'YTickLabel',{});
    end
    ylim(yLimToUsePsth);
    set(gca,'FontSize',figProperties.fontSize)
    xlim(figProperties.timeMsLimits);
    set(gca,'XTick',figProperties.xTickPsthMs,'XTickLabel',{});
    if iRaster==1
        timesMsRefLine = [0,500];
        yFreqIndRefLine = repmat(diff(yLimToUsePsth)*-0.08,1,2); 
        plot(timesMsRefLine,yFreqIndRefLine,'k','LineWidth',1.5)
        hText = text(mean(timesMsRefLine),yFreqIndRefLine(1)*2.5,...
            sprintf('%d ms',diff(timesMsRefLine)),'HorizontalAlignment','center','FontSize',figProperties.fontSize);
        set(gca,'Clipping','Off')
    end
    %% shading
    nShadings = length(shadingProperties);
    for iShading = 1:nShadings
        iClickTrainToShade = shadingProperties(iShading).iClickTrains;
        if ~ismember(iClickRate,iClickTrainToShade)
            continue;
        end
        area(shadingProperties(iShading).timesMs,[yLimToUsePsth(2),yLimToUsePsth(2)],yLimToUsePsth(1),...
            'FaceAlpha',shadingProperties(iShading).alpha,'EdgeColor','none',...
            'FaceColor',shadingProperties(iShading).color);
    end
    %% Raster Subplot
    subplot('position',positionsPerPanel.raster{iRaster})
    nTotalTrials = 0;
    unitedRaster = [];
    for iState = 1:nStatesToPlot
        currentRasterPerState{iState} = exampleData.rasterPerStimAndState{iClickRate,iState};
        nTotalTrials = nTotalTrials + size(currentRasterPerState{iState},1);
        unitedRaster = [unitedRaster; currentRasterPerState{iState}];
        borderTrialBetweenStates(iState) = nTotalTrials;
    end
    hRaster = imagesc(timesMs,1:nTotalTrials, logical(conv2(double(full(unitedRaster)),ones(1,7),'same'))); %QWERTY, was 5
    colormap(gca,flipud(gray))
            hold on;
    for iState = 1:nStatesToPlot-1
        plot([floor(timesMs(1)),ceil(timesMs(end))],repmat(borderTrialBetweenStates(iState)+0.5,1,2),'k');
    end
    trialEdgesOfStates = [0,borderTrialBetweenStates];
    if iRaster == 1
        if isRemFig
            %put text 4% width to the right
            timeMsStateText = figProperties.timeMsLimits(1) - diff(figProperties.timeMsLimits)*...
                0.04/positionsPerPanel.raster{1}(3);
        else
            %put in the middle of the remaining space to the right.
            timeMsStateText = figProperties.timeMsLimits(1) - diff(figProperties.timeMsLimits)*...
                positionsPerPanel.raster{1}(1)/2/positionsPerPanel.raster{1}(3);
        end
        for iState = 1:nStatesToPlot
            previousStateLine = trialEdgesOfStates(iState);
            nTrialsCurrentState = trialEdgesOfStates(iState+1)-trialEdgesOfStates(iState);
            if isRemFig
                shiftTextByTrials = nTrialsCurrentState/2;
            else
                if iState==nStatesToPlot
                    shiftTextByTrials = nTrialsCurrentState*0.35;
                else
                    shiftTextByTrials = nTrialsCurrentState/2;
                end
            end
            hText = text(timeMsStateText,previousStateLine+shiftTextByTrials,...
                statesToPlotClickRaster(iState).str,'HorizontalAlignment','center',...
                'Color',statesToPlotClickRaster(iState).color,'FontSize',figProperties.stateFontSize ,...
                'FontWeight','bold','Margin',1.5);
        end
        if isRemFig
            trialToEndRefLine = nTotalTrials*0.88;
        else
            trialToEndRefLine = nTotalTrials*0.98;
        end
        nTrialsForRefLine = 100;
        plot(repmat(figProperties.timeMsLimits(1)-diff(figProperties.timeMsLimits)*0.03,1,2),...
            trialToEndRefLine+[-nTrialsForRefLine,0],'k','LineWidth',1.5)
        hText = text(figProperties.timeMsLimits(1)-diff(figProperties.timeMsLimits)*0.18,trialToEndRefLine-nTrialsForRefLine/2,...
                    sprintf('%d\ntrials',nTrialsForRefLine),'HorizontalAlignment','center','FontSize',figProperties.fontSize);
        set(gca,'Clipping','Off')
    end  
    yLimToUse = [0,nTotalTrials]+0.5;
    %% shading Raster
    nShadings = length(shadingProperties);
    for iShading = 1:nShadings
        iClickTrainToShade = shadingProperties(iShading).iClickTrains;
        if ~ismember(iClickRate,iClickTrainToShade)
            continue;
        end
        area(shadingProperties(iShading).timesMs,[yLimToUse(2),yLimToUse(2)],yLimToUse(1),...
            'FaceAlpha',shadingProperties(iShading).alpha,'EdgeColor','none',...
            'FaceColor',shadingProperties(iShading).color);
    end
    ylim(yLimToUse);
    
    %%
    
    xlim(figProperties.timeMsLimits)
    ylim(yLimToUse);
    set(gca,'YDir','reverse')
    set(gca,'YTick',[]);
    set(gca,'XTick',[]);
    set(gca,'FontSize',figProperties.fontSize)
    
    %% Stimulus Clicks above Raster Subplot
    subplot('position',positionsPerPanel.stimClicks{iRaster})
    clickTimesMs = 0:MS_IN_SEC/clicks.rateHz(iClickRate):clicks.lengthMs;
    hold on;
    for iClick=1:length(clickTimesMs)
        plot(repmat(clickTimesMs(iClick),1,2),[0,1],'color',figProperties.clicks.color,...
            'LineWidth',figProperties.clicks.lineWidth);
    end
    ylim([0,1])
    xlim(figProperties.timeMsLimits);
    set(gca,'XTick',[],'YTick',[]);
    set(gca,'FontSize',figProperties.fontSize);
    set(gca,'XColor','none')
    title(sprintf('%d Clicks/s',clicks.rateHz(iClickRate)));
end
1;