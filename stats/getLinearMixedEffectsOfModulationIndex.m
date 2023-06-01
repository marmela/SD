function [lme,pValue,miEstimated,stdError,tStat,miCI95,df] = getLinearMixedEffectsOfModulationIndex (miPerUnit, iAnimalPerUnit, iSessionPerUnit, electrodePerUnit)
miPerUnit = makeColumn(miPerUnit);
iAnimalPerUnit = makeColumn(iAnimalPerUnit);
iSessionPerUnit = makeColumn(iSessionPerUnit);
electrodePerUnit = makeColumn(electrodePerUnit);

T = table(miPerUnit,iAnimalPerUnit,iSessionPerUnit, electrodePerUnit);
T.iAnimalPerUnit = categorical(T.iAnimalPerUnit);
T.iSessionPerUnit = categorical(T.iSessionPerUnit);
T.electrodePerUnit = categorical(T.electrodePerUnit);

lme = fitlme(T,'miPerUnit~1+(1|iAnimalPerUnit)+(1|iSessionPerUnit:iAnimalPerUnit)+(1|electrodePerUnit:iAnimalPerUnit)','FitMethod','REML');

miEstimated = lme.fixedEffects;
miCI95 = lme.coefCI;
df = lme.DFE;
pValue = lme.Coefficients(1,6).pValue;
tStat = lme.Coefficients(1,4).tStat;
stdError = lme.Coefficients(1,3).SE;
