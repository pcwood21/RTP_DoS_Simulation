%Assuming run after exp1_baseline, else:
%{
clear all;
expall_init;
atkFreeRevenue =    0.3150;

%}

clear all;
expall_init;

maxAttack=20;
PrDiffWindow=T_w/20;
%Calc perturb-free prices for train period

PrHist=zeros(length(timeTrainDay),1);
RPHist=zeros(length(timeTrainDay),1);
TrainPatkHighHist=zeros(length(timeTrainDay),1);
TrainPatkLowHist=zeros(length(timeTrainDay),1);
for i=1:length(timeTrainDay)
    time=timeTrainDay(i);
    Pr=ISO.processPrices(0);
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
   
    if ~isempty(ISO.OPT.getX())
            PrHist(i)=ISO.OPT.getX();
            RPHist(i)=-flexP(ISO.OPT.getX())+errorScaled(time);
        else
            PrHist(i)=Pr;
            RPHist(i)=-flexP(Pr)+errorScaled(time);
    end
    
    newPr=PrHist(i);
    
    [atkDiLow,atkDiHigh]=calcDIRP(newPr);
    [atkDiLow,targetsLow]=sort(abs(atkDiLow),'descend');
    [atkDiHigh,targetsHigh]=sort(abs(atkDiHigh),'descend');
    
    DiLow=sum(abs(atkDiLow(1:maxAttack)));
    DiHigh=sum(abs(atkDiHigh(1:maxAttack)));
    PrDiff=mean(diff(PrHist(max(i-PrDiffWindow,1):max(i,2))));
    PatkLow=DiLow*PrDiff/10;
    PatkHigh=DiHigh*PrDiff/10;
    TrainPatkHighHist(i)=PatkHigh;
    TrainPatkLowHist(i)=PatkLow;
end

postAtkPrBuy=TrainPatkLowHist(11:end)+PrHist(11:end);
postAtkPrSell=TrainPatkHighHist(11:end)+PrHist(11:end);

bottomPct=0.15;
atkBuyPr=quantile(postAtkPrBuy,bottomPct);
atkSellPr=quantile(postAtkPrSell,1-bottomPct);



%Prime market
for i=length(timeTrainDay)-1000:length(timeTrainDay)
    time=timeTrainDay(i);
    Pr=ISO.processPrices(0);
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
end
attackTestPrHist=zeros(length(timeTestDay),1);
attackTestRPHist=zeros(length(timeTestDay),1);
atkDi=calcDI(50);
Pr=50*ones(length(atkDi),1);
attackVect=zeros(length(atkDi),1);
maxAttack=20;
PrDiffWindow=T_w/20;

decisionTimes=min(timeTestDay):PrDiffWindow:max(timeTestDay);
decisionTimes=floor(decisionTimes);
decisionTimes=decisionTimes-min(decisionTimes)+1;
lastDecTime=0;
charge=NaN*ones(length(decisionTimes),1);
discharge=NaN*ones(length(decisionTimes),1);
battE=0;
revenue=0;

for i=1:length(timeTestDay)
    time=timeTestDay(i);
    newPr=ISO.processPrices(0);
    Pr(attackVect==0)=newPr;
    Pr(attackVect==1)=1000;
    Pr(attackVect==-1)=-1000;
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
    

   
    if ~isempty(ISO.OPT.getX())
            attackTestPrHist(i)=ISO.OPT.getX();
            attackTestRPHist(i)=-flexP(Pr)+errorScaled(time);
        else
            attackTestPrHist(i)=newPr;
            attackTestRPHist(i)=-flexP(newPr)+errorScaled(time);
    end
    
    newPr=attackTestPrHist(i);
    
    [atkDiLow,atkDiHigh]=calcDIRP(newPr);
    [atkDiLow,targetsLow]=sort(abs(atkDiLow),'descend');
    [atkDiHigh,targetsHigh]=sort(abs(atkDiHigh),'descend');
    
    DiLow=sum(abs(atkDiLow(1:maxAttack)));
    DiHigh=sum(abs(atkDiHigh(1:maxAttack)));
    PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):max(i,2))));
    if i==1
        continue;
    end
    PatkLow=DiLow*PrDiff/10;
    PatkHigh=DiHigh*PrDiff/10;
    
    decTime=floor((time-min(timeTestDay))/PrDiffWindow)+1;
    if decTime==lastDecTime
        continue;
    end
    lastDecTime=decTime;

    if sum(abs(attackVect))>0
        PatkLow=0;
        PatkHigh=0;
    end
    
    if newPr+PatkLow < atkBuyPr && battE < battMaxE
        attackVect=zeros(length(atkDi),1);
        attackVect(targetsLow(1:maxAttack))=1;
        charge(decTime)=1;
        battE=battE+PrDiffWindow*battchargeRate;
        revenue=revenue-newPr*PrDiffWindow*battchargeRate/1000;
    elseif newPr+PatkHigh > atkSellPr && battE > 0
        attackVect=zeros(length(atkDi),1);
        attackVect(targetsHigh(1:maxAttack))=-1;
        discharge(decTime)=1;
        battE=battE-PrDiffWindow*battchargeRate;
        revenue=revenue+newPr*PrDiffWindow*battchargeRate/1000;
    else
        attackVect=zeros(length(attackVect),1);
    end
end

TestPrHist=zeros(length(timeTestDay),1);
TestRPHist=zeros(length(timeTestDay),1);
for i=1:length(timeTestDay)
    time=timeTestDay(i);
    Pr=ISO.processPrices(0);
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
   
    if ~isempty(ISO.OPT.getX())
            TestPrHist(i)=ISO.OPT.getX();
            TestRPHist(i)=-flexP(ISO.OPT.getX())+errorScaled(time);
        else
            TestPrHist(i)=Pr;
            TestRPHist(i)=-flexP(Pr)+errorScaled(time);
    end
end

figure('Position',[100,100,550,250]);
hold all;
timeScale=timeTestDay/60/60-min(timeTestDay)/60/60;
plot(timeScale,attackTestPrHist,'LineWidth',1.5);
plot(timeScale(1:10:end),TestPrHist(1:10:end),'--','LineWidth',1.5);
chargeMap=floor(timeTestDay/PrDiffWindow);
chargeMap=chargeMap-min(chargeMap)+1;
ychp=charge(chargeMap).*100;
plot(timeScale(1:1:end),ychp(1:1:end),'+','MarkerSize',8,'LineWidth',2);
ychp=discharge(chargeMap).*100;
plot(timeScale(1:1:end),ychp(1:1:end),'X','MarkerSize',8,'LineWidth',2);
hold off;
xlabel('Time (h)');
ylim([-50 200]);
ylabel('Market Price ($/MWh)');
legend('Attacked Price','Baseline Price','Charge','Discharge','Location','southeast');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');

atkRevenue=nansum(-charge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10)+nansum(discharge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10)+battE*100*PrMWtokW;

return;


numTargets=[0 1 2 3 4 5 10 15 20 25 30 35 40 45 50 55 60];
atkRevs=zeros(length(numTargets),4);
for i=1:length(numTargets)
    parfor j=1:4
        [atkRevs(i,j)]=exp3_calc(numTargets(i),j);
    end
end

pRevs=trimmean(atkRevs,75,2);
pcost=numTargets/(nConsumer+nGenerator)*100;
pRevs(1)=atkFreeRevenue;

pInc=(pRevs-pRevs(1))./pRevs(1)*100;

figure;
plot(pcost(1:end-3),pInc(1:end-3),'LineWidth',2)
%xlim([0 25.01]);
ax=gca;
%set(ax,'XTick',[0 5 10 15 20 25]);
xlabel('Compromised Users (%)');
ylabel('Revenue Increase (%)');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');

