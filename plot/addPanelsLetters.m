function addPanelsLetters(panelsPositions,textPerPanel,xShift,yShift, fontSize)

nPanels = length(panelsPositions);
assert(nPanels == length(textPerPanel));
for iPanel = 1:nPanels
    currentPanelPos = panelsPositions{iPanel};
    annotation('textbox', [currentPanelPos(1)+xShift, currentPanelPos(2)+ currentPanelPos(4)+ ...
        yShift, 0, 0], 'string', textPerPanel{iPanel},'FontSize', fontSize,'FontWeight',...
        'Bold','HorizontalAlignment','center','VerticalAlignment','middle')
end