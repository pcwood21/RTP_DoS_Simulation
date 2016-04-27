function [revenue,doshours] = exp2_pr_opt_calc(numTargets,seed,buyPR,sellPR)

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

for i=1:length(timeTestDay)
    time=timeTestDay(i);
    newPr=ISO.processPrices(0);
    Pr(attackVect==0)=newPr;
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
    

   
    if ~isempty(ISO.OPT.getX())
            attackTestPrHist(i)=ISO.OPT.getX();
            attackTestRPHist(i)=-flexP(ISO.OPT.getX())+errorScaled(time);
        else
            attackTestPrHist(i)=Pr;
            attackTestRPHist(i)=-flexP(Pr)+errorScaled(time);
    end
    
    atkDi=calcDI(newPr);
    [atkDi,targets]=sort(abs(atkDi),'descend');
    
    Di=sum(abs(atkDi(1:maxAttack)));
    PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):max(i,2))));
    Patk=Di*PrDiff*PrDiffWindow;
    
    decTime=floor((time-min(timeTestDay))/T_w)+1;
    if decTime==lastDecTime
        continue;
    end
    lastDecTime=decTime;
    
    if newPr-Patk < buyPR && battE < battMaxE
        attackVect=zeros(length(atkDi),1);
        attackVect(targets(1:maxAttack))=1;
        charge(decTime)=1;
        battE=battE+T_w*battchargeRate;
        revenue=revenue-newPr*T_w*battchargeRate/1000;
    elseif newPr+Patk > sellPR && battE > 0
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

end