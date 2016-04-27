base_1500_loads;
%clear ISO;
ISO=dsim.ISO();
ISO.init();

load('combined_june_model');

errorP=@(t) loadmodel(t)-forecastmodel(t);

T_w=60*5; %5 minutes

numLoadDays=8;
startTestDay=7*24*60*60;
endTestDay=startTestDay+1*24*60*60;

timeTestDay=startTestDay:10:endTestDay;

timeTrainDay=1:10:startTestDay-1;

PrMWtokW=1/1000;


%Scale the error model 
flexPmin=flexP(1000);
flexPmax=flexP(-1000);
modelPmax=max(errormodel([timeTrainDay timeTestDay]));
modelPmin=min(errormodel([timeTrainDay timeTestDay]));
errorscaleFactor=(flexPmax-flexPmin)/(modelPmax-modelPmin)*0.5;
errorScaled=@(t) errormodel(t)*errorscaleFactor;

%{
plot(timeTestDay,errormodel(timeTestDay));


%}

%Prime the market
for i=1:1000
    time=timeTrainDay(1);
    Pr=ISO.processPrices(0);
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
end

battchargeRate=300*2/60/60; %kWs
battMaxE=300*4;
%These values are calculated from exp1 and are left here for cache purposes
buyPR=64.4849;
sellPR=146.6158;
atkFreeRevenue=70.88;
ClearancePrice=100;
%atkBuyPr=48.9229;
%atkSellPr=142.2204;
