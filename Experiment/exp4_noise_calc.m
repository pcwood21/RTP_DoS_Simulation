function [atkRevenue,doshours] = exp4_noise_calc(noiseLevel,seed)

expall_init;
numTargets=20;
atkBuyPr =64.9985;
atkSellPr =111.3501;

rng(seed);

atkDi=calcDI(100); %Get a basic impact list
%modDi=unifrnd(1-noiseLevel,1+noiseLevel,length(atkDi),1);
modDi=abs(normrnd(1,noiseLevel,length(atkDi),1));


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
PrDiffWindow=T_w/100;

decisionTimes=min(timeTestDay):PrDiffWindow:max(timeTestDay);
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
    
    atkDi=calcDI(newPr).*modDi;
    [atkDi,targets]=sort(abs(atkDi),'descend');
    
    Di=sum(abs(atkDi(1:maxAttack)));
    PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):max(i,2))));
    Patk=Di*PrDiff*PrDiffWindow;
    
    decTime=floor((time-min(timeTestDay))/PrDiffWindow)+1;
    if decTime==lastDecTime
        continue;
    end
    lastDecTime=decTime;
    
    isAttacking(i)=sum(attackVect)>0;
    if (isAttacking(i))
        Patk=0;
    end
   % if isAttacking && newPr < atkSellPr && newPr > atkBuyPr
   %     attackVect=zeros(length(atkDi),1);
   % else
        if newPr+Patk < atkBuyPr && battE < battMaxE
            attackVect=zeros(length(atkDi),1);
            attackVect(targets(1:maxAttack))=1;
            charge(decTime)=1;
            battE=battE+PrDiffWindow*battchargeRate;
            revenue=revenue-newPr*PrDiffWindow*battchargeRate*PrMWtokW;
        elseif newPr+Patk > atkSellPr && battE > 0
            attackVect=zeros(length(atkDi),1);
            attackVect(targets(1:maxAttack))=1;
            discharge(decTime)=1;
            battE=battE-PrDiffWindow*battchargeRate;
            revenue=revenue+newPr*PrDiffWindow*battchargeRate*PrMWtokW;
%         elseif newPr < atkBuyPr && battE < battMaxE
%             attackVect=zeros(length(atkDi),1);
%             charge(decTime)=1;
%             battE=battE+PrDiffWindow*battchargeRate;
%             revenue=revenue-newPr*PrDiffWindow*battchargeRate*PrMWtokW;
%         elseif newPr > atkSellPr && battE > 0
%             attackVect=zeros(length(atkDi),1);
%             discharge(decTime)=1;
%             battE=battE-PrDiffWindow*battchargeRate;
%             revenue=revenue+newPr*PrDiffWindow*battchargeRate*PrMWtokW;
        else
            attackVect=zeros(length(atkDi),1);
        end
    %end
end

chargeMap=floor(timeTestDay/PrDiffWindow);
chargeMap=chargeMap-min(chargeMap)+1;

atkRevenue=nansum(-charge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10)+nansum(discharge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10) + battE*100*PrMWtokW;
doshours=sum(isAttacking)*PrDiffWindow*numTargets;
end