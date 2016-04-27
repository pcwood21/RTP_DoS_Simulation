function [atkRevenue,doshours] = exp3_calc(numTargets,seed)

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
PrDiffWindow=T_w/2;

decisionTimes=min(timeTestDay):T_w:max(timeTestDay);
decisionTimes=floor(decisionTimes);
decisionTimes=decisionTimes-min(decisionTimes)+1;
lastDecTime=1;
charge=NaN*ones(length(decisionTimes),1);
discharge=NaN*ones(length(decisionTimes),1);
isAttacking=zeros(length(decisionTimes),1);
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
            attackTestRPHist(i)=-flexP(ISO.OPT.getX())+errorScaled(time);
        else
            attackTestPrHist(i)=Pr;
            attackTestRPHist(i)=-flexP(Pr)+errorScaled(time);
    end
    
    newPr=attackTestPrHist(i);
    
    [atkDiLow,atkDiHigh]=calcDIRP(newPr);
    [atkDiLow,targetsLow]=sort(abs(atkDiLow),'descend');
    [atkDiHigh,targetsHigh]=sort(abs(atkDiHigh),'descend');
    
    DiLow=sum(abs(atkDiLow(1:maxAttack)));
    DiHigh=sum(abs(atkDiHigh(1:maxAttack)));
    PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):max(i,2))));
    PatkLow=DiLow*PrDiff/10;
    PatkHigh=DiHigh*PrDiff/10;
    
    decTime=floor((time-min(timeTestDay))/T_w)+1;
    if decTime==lastDecTime
        continue;
    end
    lastDecTime=decTime;
    
    isAttacking(i)=sum(attackVect)>0;
   % if isAttacking && newPr < atkSellPr && newPr > atkBuyPr
   %     attackVect=zeros(length(atkDi),1);
   % else
    if newPr+PatkLow < buyPR && battE < battMaxE
        attackVect=zeros(length(atkDi),1);
        attackVect(targetsLow(1:maxAttack))=1;
        charge(decTime)=1;
        battE=battE+T_w*battchargeRate;
        revenue=revenue-newPr*T_w*battchargeRate/1000;
    elseif newPr+PatkHigh > sellPR && battE > 0
        attackVect=zeros(length(atkDi),1);
        attackVect(targetsHigh(1:maxAttack))=-1;
        discharge(decTime)=1;
        battE=battE-T_w*battchargeRate;
        revenue=revenue+newPr*T_w*battchargeRate/1000;

%         elseif newPr < atkBuyPr && battE < battMaxE
%             attackVect=zeros(length(atkDi),1);
%             charge(decTime)=1;
%             battE=battE+T_w*battchargeRate;
%             revenue=revenue-newPr*T_w*battchargeRate*PrMWtokW;
%         elseif newPr > atkSellPr && battE > 0
%             attackVect=zeros(length(atkDi),1);
%             discharge(decTime)=1;
%             battE=battE-T_w*battchargeRate;
%             revenue=revenue+newPr*T_w*battchargeRate*PrMWtokW;
        else
            attackVect=zeros(length(atkDi),1);
        end
    %end
end

atkRevenue=revenue+battE*100*PrMWtokW;
doshours=sum(isAttacking)*T_w*numTargets;

end