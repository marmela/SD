function plotStrfExamples (tuningPlotData, statesInfo, figProperties, examplePlotPosition, exampleStrfPosition, exampleColorBarPos)

%%
PLOT_LINE_COLOR = 'k';
TUNING_LINE_COLOR = 'r';
COLORMAP_STRF = parula;

%% Plot tuning plots examples
freqsToPlot = 1000*2.^(0:6);
freqs = tuningPlotData.example.freqs;
[Lia,Locb] = ismember(round(freqs),freqsToPlot);

nStates = length(tuningPlotData.example.strfExamplePerState);
minFr = Inf;
maxFr = -Inf;
for iState = 1:nStates
    frPerFreqToPlot{iState} = tuningPlotData.example.meanFrPerFreqPerState{iState};
    minFr = min(minFr, min(frPerFreqToPlot{iState}));
    maxFr = max(maxFr, max(frPerFreqToPlot{iState}));
end
    
for iState = 1:nStates
    subplot('position',examplePlotPosition{iState});
    hold on;
    plot(frPerFreqToPlot{iState},1:length(frPerFreqToPlot{iState}),'color',PLOT_LINE_COLOR,...
        'LineWidth',figProperties.tuning.examplePlotLineWidth);
    
    %% Plotting tuning width line
    anArrow = annotation('line','LineWidth',figProperties.tuning.examplePlotLineWidth*1.3,'color',TUNING_LINE_COLOR) ; %'doublearrow'
    anArrow.Parent = gca;  % or any other existing axes or figure
    anArrow.Position = [max(frPerFreqToPlot{iState})/2, tuningPlotData.example.iFwhm(iState).onset, ...
        0, tuningPlotData.example.iFwhm(iState).offset-tuningPlotData.example.iFwhm(iState).onset] ;

    %%
    set(gca,'XDir','reverse')
    ylim([0.5,length(frPerFreqToPlot{iState})+0.5])
    if iState==nStates
        set(gca,'YTick',find(Lia),'YTickLabel',freqsToPlot(Locb(Lia))./1000);
        ylabel('Frequency (KHz)');
    else
        set(gca,'YTick',[]);
    end
    set(gca,'FontSize',figProperties.fontSize);
    xlim([minFr,maxFr]);
    set(gca,'XTick',[]);
    if iState==nStates
        frRange = [0,50];
        yFreqIndRefLine = [-1,-1];
        plot(frRange,yFreqIndRefLine,'k','LineWidth',1.5)
        hText = text(mean(frRange),yFreqIndRefLine(1)-3,...
            sprintf('%d spikes/s    ',diff(frRange)),'HorizontalAlignment','center','FontSize',figProperties.fontSize);
        set(gca,'Clipping','Off')
    end    
end

%% Plot STRF Examples
timesPsthMs = tuningPlotData.example.timesPsthMs;
isDuringRelevantTime = timesPsthMs>=tuningPlotData.example.relevantTimeMs(1) & ...
    timesPsthMs<tuningPlotData.example.relevantTimeMs(2);
for iState = nStates:-1:1
    strfExamplePerState{iState} = conv2(tuningPlotData.example.strfExamplePerState{iState},...
        tuningPlotData.example.smoothWin,'same');
    strfExamplePerState{iState}  = strfExamplePerState{iState} (:,isDuringRelevantTime);
end
maxVal = -Inf;
minVal = Inf;
for iState = 1:nStates
    maxVal = max(maxVal,max(strfExamplePerState{iState},[],'all'));
    minVal = min(minVal,min(strfExamplePerState{iState},[],'all'));
end

for iState = 1:nStates
    subplot('position',exampleStrfPosition{iState});
    imagesc(timesPsthMs(isDuringRelevantTime),1:length(freqs),strfExamplePerState{iState});
    hold on;
    colormap(COLORMAP_STRF)
    set(gca,'YTick',[]);
    set(gca,'YDir','normal')
    set(gca,'FontSize',figProperties.fontSize);
    set(gca,'XTick',[]);
    if iState==nStates
        timesMsRefLine = [20,40];
        yFreqIndRefLine = [-1,-1];
        plot(timesMsRefLine,yFreqIndRefLine,'k','LineWidth',1.5)
        hText = text(mean(timesMsRefLine),yFreqIndRefLine(1)-3,...
            sprintf('%d ms',diff(timesMsRefLine)),'HorizontalAlignment','center','FontSize',figProperties.fontSize);
        set(gca,'Clipping','Off')
    end
    title(tuningPlotData.example.strPerState{iState},'FontSize',figProperties.stateFontSize,...
        'color',statesInfo(iState).color) %eval(sprintf('state%dInfo.color',iState)))
    
end

%% STRF colorbar
hBar = colorbar('position',exampleColorBarPos);
caxis([minVal,maxVal]);
title(hBar,sprintf('\\DeltaSpikes/s'));