function [revenue,doshours] = secretary_calc(numTargets,prTrain,seed)

expall_init;

rng(seed);

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
maxAttack=numTargets;
PrDiffWindow=10;

decisionTimes=min(timeTestDay):T_w:max(timeTestDay);
decisionTimes=floor(decisionTimes);
decisionTimes=decisionTimes-min(decisionTimes)+1;
lastDecTime=0;
charge=NaN*ones(length(decisionTimes),1);
discharge=NaN*ones(length(decisionTimes),1);
battE=0;
revenue=0;

PrDiffHist=[];

for i=1:length(timeTestDay)
    time=timeTestDay(i);
    newPr=ISO.processPrices(0);
    Pr(attackVect==0)=newPr;
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
    

   
    if ~isempty(ISO.OPT.getX())
            attackTestPrHist(i)=ISO.OPT.getX();
            attackTestRPHist(i)=-flexP(Pr)+errorScaled(time);
        else
            attackTestPrHist(i)=Pr;
            attackTestRPHist(i)=-flexP(Pr)+errorScaled(time);
    end
    
    atkDi=calcDI(newPr);
    [atkDi,targets]=sort(abs(atkDi),'descend');
    
    Di=sum(abs(atkDi(1:maxAttack)));
    
    if i==1
        PrDiff=0;
    else
        PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):i)));
    end
    PrDiffHist(end+1)=PrDiff;
    Patk=Di*PrDiff*PrDiffWindow;
    
    decTime=floor((time-min(timeTestDay))/T_w)+1;
    if decTime==lastDecTime
        continue;
    end
    lastDecTime=decTime;
    
    if ( newPr < prTrain.minPrice || PrDiff < prTrain.minDiff ) && battE < battMaxE
        attackVect=zeros(length(atkDi),1);
        attackVect(targets(1:maxAttack))=1;
        charge(decTime)=1;
        battE=battE+T_w*battchargeRate;
        revenue=revenue-newPr*T_w*battchargeRate/1000;
    elseif (newPr > prTrain.maxPrice || PrDiff > prTrain.maxDiff) && battE > 0
        attackVect=zeros(length(atkDi),1);
        attackVect(targets(1:maxAttack))=1;
        discharge(decTime)=1;
        battE=battE-T_w*battchargeRate;
        revenue=revenue+newPr*T_w*battchargeRate/1000;
    else
        attackVect=zeros(length(atkDi),1);
    end
end

chargeMap=floor(timeTestDay/T_w);
chargeMap=chargeMap-min(chargeMap)+1;

revenue=nansum(-charge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10)+nansum(discharge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10);
doshours=nansum(charge(chargeMap))+nansum(discharge(chargeMap));
doshours=doshours*numTargets;

keyboard

figure;
hold all;
timeScale=timeTestDay/60/60-min(timeTestDay)/60/60;
plot(timeScale,attackTestPrHist,'LineWidth',1.5);
plot(timeScale(1:10:end),TestPrHist(1:10:end),'--','LineWidth',1.5);
chargeMap=floor(timeTestDay/T_w);
chargeMap=chargeMap-min(chargeMap)+1;
ychp=charge(chargeMap).*120;
plot(timeScale(1:1:end),ychp(1:1:end),'-','MarkerSize',10,'LineWidth',4);
ychp=discharge(chargeMap).*120;
plot(timeScale(1:1:end),ychp(1:1:end),'-','MarkerSize',10,'LineWidth',4);
hold off;
xlabel('Time (h)');
ylabel('Market Price ($/MWh)');
legend('Attacked Price','Baseline Price','Charge','Discharge');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');

end
