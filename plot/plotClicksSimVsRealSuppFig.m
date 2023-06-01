function plotClicksSimVsRealSuppFig(statesData, isSigClicksAndMinFrUnit, exampleUnit)
nStates = length(statesData);
CLICK_RATES_INDICES_REAL_DATA = 2:5; %indices of 10-40 Hz click rates (2,10,20,30,40);
IND_2HZ_CLICKS = 1;

%% click locking real vs. sim for Unit data
figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'Extra' filesep 'ClicksSimVsReal'];
makeDirIfNeeded(figDir)
sessPerUnit = extractfield(statesData{1}.unitData,'session');
chPerUnit = extractfield(statesData{1}.unitData,'ch');
clusPerUnit = extractfield(statesData{1}.unitData,'clus');
iExample = find(strcmp(exampleUnit.session,sessPerUnit) & ...
    exampleUnit.ch == chPerUnit & exampleUnit.clus == clusPerUnit);

for iState = nStates:-1:1
    clicksSimPerUnit = extractfield(statesData{iState}.unitData,'clicksSim');
    sessionPerUnit = extractfield(statesData{iState}.unitData,'session');
    clicksRealPerUnit = cell2mat(extractfield(statesData{iState}.unitData,'clicksAll'));
    isRelevantUnit = isSigClicksAndMinFrUnit' & ~cellfun(@isempty,clicksSimPerUnit);
    
    exampleData = clicksSimPerUnit{iExample};
    
    exampleRealPerState{iState} = exampleData.realClicksResponses;
    exampleSimPerState{iState} = exampleData.simClicksResponses;
    
    
    clicksSimPerUnit(~isRelevantUnit) = [];
    clicksRealPerUnit(~isRelevantUnit) = [];
    sessionPerUnit(~isRelevantUnit) = [];
    clicksSimPerUnit = cell2mat(clicksSimPerUnit);

    clickRates = clicksSimPerUnit(1).clickRates;
    nClickRates = length(clickRates);
    
    nUnits = sum(isRelevantUnit);
    
    for iUnit = nUnits:-1:1
        lockingReal2Hz(iUnit,1) = clicksRealPerUnit(iUnit).clicksLockedFr(IND_2HZ_CLICKS);
        lockedFrRealPerUnit(iUnit,:) = clicksRealPerUnit(iUnit).clicksLockedFr(CLICK_RATES_INDICES_REAL_DATA);
        lockedFrSimPerUnit(iUnit,:) = clicksSimPerUnit(iUnit).lockingPerClickRate;
    end
    isNanNorm = lockingReal2Hz==0;
    normalizingMatrix = repmat(lockingReal2Hz,1,nClickRates);
    normalizedLockedFrReal = lockedFrRealPerUnit./normalizingMatrix;
    normalizedLockedFrSim = lockedFrSimPerUnit./normalizingMatrix;

    sessionPerUnit(isNanNorm) = [];
    normalizedLockedFrSim(isNanNorm,:) = [];
    normalizedLockedFrReal(isNanNorm,:) = [];
    
    normalizedLockedFrWithinSessSim = normalizedLockedFrSim;
    normalizedLockedFrWithinSessReal = normalizedLockedFrReal;
    
    [uniqueSessions,~,iUniqueSession] = unique(sessionPerUnit);
    nSessions = length(uniqueSessions);
    realUnitLockPerSessAndClickRate = nan(nSessions,nClickRates);
    for iSess = nSessions:-1:1
        isCurrentSess = iUniqueSession==iSess;
        realUnitLockPerSessAndClickRate(iSess,:) = mean(normalizedLockedFrReal(isCurrentSess,:));
        simUnitLockPerSessAndClickRate(iSess,:) = mean(normalizedLockedFrSim(isCurrentSess,:));
        
        normalizedLockedFrWithinSessSim(isCurrentSess,:) = ...
            normalizedLockedFrWithinSessSim(isCurrentSess,:)-simUnitLockPerSessAndClickRate(iSess,:);
        normalizedLockedFrWithinSessReal(isCurrentSess,:) = ...
            normalizedLockedFrWithinSessReal(isCurrentSess,:)-realUnitLockPerSessAndClickRate(iSess,:);
        
    end
    
    meanRealUnitPerStateAndClickRate(iState,:) = mean(realUnitLockPerSessAndClickRate);
    semRealUnitPerStateAndClickRate(iState,:) = std(realUnitLockPerSessAndClickRate)./sqrt(size(realUnitLockPerSessAndClickRate,1));
    meanSimUnitPerStateAndClickRate(iState,:) = mean(simUnitLockPerSessAndClickRate);
    semSimUnitPerStateAndClickRate(iState,:) = std(simUnitLockPerSessAndClickRate)./sqrt(size(simUnitLockPerSessAndClickRate,1));
end
timesMs = clicksSimPerUnit(1).timesMs;

plotFigurePerClickRateAndState(meanRealUnitPerStateAndClickRate,meanSimUnitPerStateAndClickRate,...
    semRealUnitPerStateAndClickRate,semSimUnitPerStateAndClickRate, statesData, clickRates,'Units',...
    exampleRealPerState, exampleSimPerState, timesMs)


1;


function plotFigurePerClickRateAndState(meanRealPerStateAndClickRate,meanSimPerStateAndClickRate,...
    semRealPerStateAndClickRate,semSimPerStateAndClickRate, statesData, clickRates,titleStr,...
    exampleRealPerState, exampleSimPerState,timesMs)
ERROR_LINE_WIDTH = 1.5;
BAR_LINE_WIDTH = 1.5;
FONT_SIZE = 16;
BAR_WIDTH = 0.8;

timeLimits = [-50,550];
isRelevantTime = timesMs>=timeLimits(1) & timesMs<timeLimits(2);

gaussWin = getGaussWin(2.5,15)';

maxYValue = max(max(meanRealPerStateAndClickRate+semRealPerStateAndClickRate,[],'all'),...
    max(meanSimPerStateAndClickRate+semSimPerStateAndClickRate,[],'all'));
maxYValue = min(1,ceil(maxYValue*20)./20);
nClickRates = length(clickRates);
nStates = length(statesData);
figPositions = [0,50,1600,950];
figure('Position',figPositions);

maxFr = -Inf;
for iState = 1:nStates
    realSmoothedAll = conv2(exampleRealPerState{iState},gaussWin,'same');
    maxFr = max(maxFr,max([realSmoothedAll(:,isRelevantTime);...
        exampleSimPerState{iState}(:,isRelevantTime)],[],'all'));
end

frLimits = [0,ceil(maxFr/10)*10];
PLOT_LINE_WIDTH = 1.5;

colorsMatlab = lines;
for iState = 1:nStates 
    currStateReal = exampleRealPerState{iState};
    currStateSim = exampleSimPerState{iState};
    subplot(nClickRates*2,nStates,iState)
    title(statesData{iState}.info.str);%,'color',statesData{iState}.info.color) ;
    
    for iRate = 1:nClickRates
        hSubplot = subplot(nClickRates*2,nStates,(iRate-1)*nStates+iState);
        hold on;
        realSmoothed = conv(currStateReal(iRate,:),gaussWin,'same');
        hSim = plot(timesMs(isRelevantTime),currStateSim(iRate,isRelevantTime),'LineWidth',PLOT_LINE_WIDTH,'color',colorsMatlab(2,:));
        hReal = plot(timesMs(isRelevantTime),realSmoothed(isRelevantTime),'LineWidth',PLOT_LINE_WIDTH,'color',colorsMatlab(1,:));
        xlim(timeLimits);
        ylim(frLimits);
        set(gca,'FontSize',FONT_SIZE);
        set(gca,'XTick',[],'YTickLabel',{});
        if iState == 1
            set(gca,'Clipping','Off')
            currentSubplotPositions = get(hSubplot,'position');
            timeMsStateText = timeLimits(1) - diff(timeLimits)*...
                currentSubplotPositions(1)/2/currentSubplotPositions(3);
            hText = text(timeMsStateText,mean(frLimits)*1.5,...
                sprintf('%d clicks/s',clickRates(iRate)),'HorizontalAlignment','center',...
                'FontSize',FONT_SIZE ,'FontWeight','bold');
            if iRate==nClickRates
                text(timeMsStateText, mean(frLimits)*0.35, 'Real',  'HorizontalAlignment', 'center', ...
                    'color',colorsMatlab(1,:),'FontSize',FONT_SIZE ,'FontWeight','bold');
                text(timeMsStateText, mean(frLimits)*-0.35, 'Simulated',  'HorizontalAlignment', 'center', ...
                    'color',colorsMatlab(2,:),'FontSize',FONT_SIZE ,'FontWeight','bold');
            end
            
        end
        
        if iState==nStates && iRate==nClickRates
            timesMsRefLine = [0,500];
            yFreqIndRefLine = repmat(frLimits(1)-diff(frLimits)*0.1,1,2);
            plot(timesMsRefLine,yFreqIndRefLine,'k','LineWidth',1.5)
            hText = text(mean(timesMsRefLine),yFreqIndRefLine(1)*2.5,...
                sprintf('%d ms',diff(timesMsRefLine)),'HorizontalAlignment','center','FontSize',FONT_SIZE);
            frRefLineLimits = [0,100];
            plot(repmat(timeLimits(1)-diff(timeLimits)*0.03,1,2),frRefLineLimits,'k','LineWidth',1.5)
            hText = text(timeLimits(1)-diff(timeLimits)*0.13,mean(frRefLineLimits)*0.05,...
                sprintf('%d\nspikes/s',diff(frRefLineLimits)),'HorizontalAlignment',...
                'center','FontSize',FONT_SIZE);
            set(gca,'Clipping','Off')
            
        end
    end
end 

for iState = 1:nStates    
    subplot(2,nStates,nStates+iState);
    hold on;
    title(statesData{iState}.info.str);%,'color',statesData{iState}.info.color)
    hBar{iState} = bar(clickRates,[meanRealPerStateAndClickRate(iState,:)',  meanSimPerStateAndClickRate(iState,:)'],'LineWidth',BAR_LINE_WIDTH,'BarWidth',BAR_WIDTH);
    ylim([0,maxYValue])
    set(gca,'FontSize',FONT_SIZE);
    

    pause(0.1);
    for iBar = 1:length(hBar{iState})
        if iBar==1
            semForState = semRealPerStateAndClickRate(iState,:);
        else
            semForState = semSimPerStateAndClickRate(iState,:);
        end
        errorbar(hBar{iState}(iBar).XData+hBar{iState}(iBar).XOffset,hBar{iState}(iBar).YData, semForState,'.k','LineWidth',ERROR_LINE_WIDTH)
    end
    
    xlabel('Click Rate (clicks/s)');
    if iState==1
        ylabel('Normalized Locked Response');
        legend(hBar{iState},{'Real','Simulated'},'Location','northeast');
    else
        set(gca,'YTickLabel',{});
    end
end
pause(0.1);
pause(0.1);

figDir = [SdLocalPcDef.FIGURES_DIR filesep 'Paper' filesep 'Extra' filesep 'ClicksSimVsReal'];
makeDirIfNeeded(figDir)
figName = [titleStr '-exampleAndPopulation'];
figPath = [figDir filesep figName];
savefig(figPath);
hgexport(gcf,figPath ,hgexport('factorystyle'), 'Format', 'eps');
print(gcf,[figPath '.png'],'-dpng','-r600')
set(gcf,'PaperSize',figPositions(3:4)/100*1.05)
print(gcf,[figPath '.pdf'],'-dpdf','-r600')



1;