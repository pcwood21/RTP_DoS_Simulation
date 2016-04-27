clear all;
expall_init;

maxAttack=20;
PrDiffWindow=T_w/100;
%Calc perturb-free prices for train period

PrHist=zeros(length(timeTrainDay),1);
RPHist=zeros(length(timeTrainDay),1);
TrainPatkHist=zeros(length(timeTrainDay),1);
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
    atkDi=calcDI(newPr);
    [atkDi,~]=sort(abs(atkDi),'descend');
    
    Di=sum(abs(atkDi(1:maxAttack)));
    DiTotal=sum(abs(atkDi));
    PrDiff=mean(diff(PrHist(max(i-PrDiffWindow,1):max(i,2))));
    Patk=Di*PrDiff*PrDiffWindow;
    TrainPatkHist(i)=Patk;
end

postAtkPr=TrainPatkHist(11:end)+PrHist(11:end);

bottomPct=0.15;
atkBuyPr=quantile(postAtkPr,bottomPct);
atkSellPr=quantile(postAtkPr,1-bottomPct);



%Prime market
for i=length(timeTrainDay)-1000:length(timeTrainDay)
    time=timeTrainDay(i);
    Pr=ISO.processPrices(0);
    RP=abs(flexP(Pr)+errorScaled(time));
    ISO.clientPower=RP;
end

attackTestPrHist=zeros(length(timeTestDay),1);
attackTestRPHist=zeros(length(timeTestDay),1);
PatkHist=zeros(length(timeTestDay),1);
PrDiffHist=zeros(length(timeTestDay),1);
DiHist=zeros(length(timeTestDay),1);
atkDi=calcDI(50);
Pr=50*ones(length(atkDi),1);
attackVect=zeros(length(atkDi),1);

maxAttack=20;
PrDiffWindow=T_w/100;

decisionTimes=min(timeTestDay):PrDiffWindow:max(timeTestDay);
decisionTimes=floor(decisionTimes);
decisionTimes=decisionTimes-min(decisionTimes)+1;
lastDecTime=1;
charge=NaN*ones(length(decisionTimes),1);
discharge=NaN*ones(length(decisionTimes),1);
battE=0;
revenue=0;

%{
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
    [atkDi,~]=sort(abs(atkDi),'descend');
    
    Di=sum(abs(atkDi(1:maxAttack)));
    DiHist(i)=Di;
    PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):max(i,2))));
    PrDiffHist(i)=PrDiff;
    Patk=Di*PrDiff*PrDiffWindow;
    PatkHist(i)=Patk;
end
PatkHist(1:10)=[];
PrDiffHist(1:10)=[];
DiHist(1:10)=[];

timeScale=timeTestDay/60/60-min(timeTestDay)/60/60;
pTime=timeScale(11:end);
figure;
[AX,H1,H2] = plotyy(pTime(1:20:end),PatkHist(1:20:end),pTime(1:20:end),DiHist(1:20:end));
set(get(AX(1),'Ylabel'),'String','Power of Attack ($)') 
set(get(AX(2),'Ylabel'),'String','D_j Gain of Attack Targets (kW/$)') 
xlabel('Time (h)');
legend('P_{atk}','D_j');
set(AX(1),'FontSize',12);
set(AX(1),'FontName','Times New Roman');
set(AX(2),'FontSize',12);
set(AX(2),'FontName','Times New Roman');
%}

%New Market Price w/ Atk:
%postAtkPr=PatkHist+attackTestPrHist(11:end);

%atkBuyPr=quantile(postAtkPr,0.05);
%atkSellPr=quantile(postAtkPr,1-2/24);

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
    
    atkDi=calcDI(newPr);
    [atkDi,targets]=sort(abs(atkDi),'descend');
    
    Di=sum(abs(atkDi(1:maxAttack)));
    PrDiff=mean(diff(attackTestPrHist(max(i-PrDiffWindow,1):max(i,2))));
    Patk=Di*PrDiff*PrDiffWindow;
    
    decTime=floor((time-min(timeTestDay))/PrDiffWindow)+1;
    if decTime==lastDecTime
        continue;
    end
    lastDecTime=decTime;
    
    isAttacking=sum(attackVect);
    if (isAttacking)
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

%atkRevenue=revenue+battE*100*PrMWtokW; %Assuming mean $100 for sell price

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
plot(timeScale(1:10:end),ychp(1:10:end),'+','MarkerSize',8,'LineWidth',2);
ychp=discharge(chargeMap).*100;
plot(timeScale(1:10:end),ychp(1:10:end),'X','MarkerSize',8,'LineWidth',2);
hold off;
xlabel('Time (h)');
ylim([-50 200]);
ylabel('Market Price ($/MWh)');
legend('Attacked Price','Baseline Price','Charge','Discharge','Location','southeast');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');

atkRevenue=nansum(-charge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10)+nansum(discharge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10) + battE*100*PrMWtokW;
sprintf(['Attack Revenues: $' num2str(atkRevenue)])

return;


%numTargets=[0 1 2 3 4 5 10 15 20 25 30 35 40 45 50 55 60];
numTargets=[5 10 15 20 40];
atkRevs=zeros(length(numTargets),8);
doscost=zeros(length(numTargets),8);
for i=1:length(numTargets)
    for j=1:8
        [atkRevs(i,j),doscost(i,j)]=exp2_calc(numTargets(i),j,atkBuyPr,atkSellPr);
    end
end

pRevs=mean(atkRevs(1:end-1,:),2);
pcost=mean(doscost(1:end-1,:),2);
pRevs=[atkFreeRevenue pRevs'];
pcost=[0 pcost'];

pInc=(pRevs-pRevs(1))./pRevs(1)*100;

figure;
plot(pcost(1:end-1)/3600,pInc(1:end-1),'LineWidth',2)
%xlim([0 25.01]);
ax=gca;
%set(ax,'XTick',[0 5 10 15 20 25]);
xlabel('DDoS-Hours (h)');
ylabel('Revenue Increase (%)');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');


%optimize buyPR/sellPR

optfun=@(x) -exp2_pr_opt_calc(20,1,x(1),x(2));

gaopts=gaoptimset('UseParallel',1);
x=ga(optfun,2,[],[],[],[],[0 0],[500 500],[],[],gaopts);

fmopts=optimset('MaxFunEvals',100);

[x,fval]=fminsearch(optfun,[73.4063  144.3969],fmopts);

x =[   73.4063  144.3969];
fval=0.8594;
comp=pRevs(9);
pctGain=(fval-comp)/comp;