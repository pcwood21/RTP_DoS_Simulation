clear all;
expall_init;


%Calc perturb-free prices for train period

PrHist=zeros(length(timeTrainDay),1);
RPHist=zeros(length(timeTrainDay),1);
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
end

figure;
plotyy(timeTrainDay/60/60/24,PrHist,timeTrainDay/60/60/24,errorScaled(timeTrainDay));
xlabel('Time (days)');
ylabel('Market Price ($/MWh)');
set(gca,'FontSize',12);
set(gca,'FontName','Times New Roman');


chargeTime=2/24;
dischargeTime=2/24;

sortPR=sort(PrHist,'descend');
sellPR=sortPR(ceil(length(sortPR)*chargeTime));
sortPR=sort(PrHist,'ascend');
buyPR=sortPR(ceil(length(sortPR)*chargeTime));


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

%Here we find the optimal sell and buy price
exp1_revcalc=@(x) -1*exp1_revenue_func(x(1),x(2),TestPrHist,battchargeRate,timeTestDay,T_w,battMaxE,PrMWtokW);
X=fminsearch(exp1_revcalc,[buyPR sellPR]);
buyPR=X(1);
sellPR=X(2);

%Note: change these values to find different profit levels
%buyPR=64.4849;
%sellPR=146.6158;
chargeTime=battMaxE/battchargeRate/(max(timeTrainDay)-min(timeTrainDay)); %Amount of time can spend charging
buyPR=quantile(PrHist,0.15);
sellPR=quantile(PrHist,0.85);

battE=0;
revenue=0;

decisionTimes=min(timeTestDay):T_w:max(timeTestDay);
decisionTimes=floor(decisionTimes);
decisionTimes=decisionTimes-min(decisionTimes)+1;
charge=NaN*ones(length(decisionTimes),1);
discharge=NaN*ones(length(decisionTimes),1);
for i=1:length(decisionTimes)
    Pr=TestPrHist(floor(decisionTimes(i)/10)+1);
    if Pr<buyPR && battE < battMaxE
        charge(i)=1;
        battE=battE+T_w*battchargeRate;
        revenue=revenue-Pr*T_w*battchargeRate*PrMWtokW;
    elseif Pr>sellPR && battE > 0
        discharge(i)=1;
        battE=battE-T_w*battchargeRate;
        revenue=revenue+Pr*T_w*battchargeRate*PrMWtokW;
    end
end

revenue=revenue+battE*PrMWtokW*ClearancePrice;

figure;
hold all;
timeScale=timeTestDay/60/60-min(timeTestDay)/60/60;
plot(timeScale,TestPrHist,'LineWidth',1.5);
chargeMap=floor(timeTestDay/T_w);
chargeMap=chargeMap-min(chargeMap)+1;
ychp=charge(chargeMap).*median(TestPrHist);
plot(timeScale(1:60:end),ychp(1:60:end),'+','MarkerSize',12,'LineWidth',2);
ychp=discharge(chargeMap).*median(TestPrHist);
plot(timeScale(1:60:end),ychp(1:60:end),'X','MarkerSize',12,'LineWidth',2);
xlabel('Time (h)');
ylabel('Market Price ($/MWh)');
legend('Price','Charge','Discharge');
set(gca,'FontSize',12);
set(gca,'FontName','Times New Roman');
hold off;

sprintf(['Revenue: $' num2str(revenue)])

%Commented because naive strategy to attack when charge/dischage has no
%rationale for success
%{

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
PrDiffWindow=3;

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
    
    Di=sum(atkDi(1:maxAttack));
    PrDiff=attackTestPrHist(i)-attackTestPrHist(max(i-PrDiffWindow,1));
    Patk=Di*PrDiff;
    
    decTime=floor((time-min(timeTestDay))/T_w)+1;
    if charge(decTime) == 1 || discharge(decTime) == 1
        attackVect=zeros(length(atkDi),1);
        attackVect(targets(1:maxAttack))=1;
    else
        attackVect=zeros(length(atkDi),1);
    end
end

figure;
hold all;
timeScale=timeTestDay/60/60-min(timeTestDay)/60/60;
plot(timeScale,attackTestPrHist,'LineWidth',1.5);
plot(timeScale(1:10:end),TestPrHist(1:10:end),'--','LineWidth',1.5);
chargeMap=floor(timeTestDay/T_w);
chargeMap=chargeMap-min(chargeMap)+1;
ychp=charge(chargeMap).*120;
plot(timeScale(1:120:end),ychp(1:120:end),'-.+','MarkerSize',10,'LineWidth',4);
ychp=discharge(chargeMap).*120;
plot(timeScale(1:120:end),ychp(1:120:end),':x','MarkerSize',10,'LineWidth',4);
hold off;
xlabel('Time (h)');
ylabel('Market Price ($/MWh)');
legend('Attacked Price','Baseline Price','Charge','Discharge');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');
%}

%atkFreeRevenue=nansum(-charge(chargeMap).*TestPrHist.*battchargeRate/1000*10)+nansum(discharge(chargeMap).*TestPrHist.*battchargeRate/1000*10);
%atkRevenue=nansum(-charge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10)+nansum(discharge(chargeMap).*attackTestPrHist.*battchargeRate/1000*10);

%pctDiff=(atkRevenue-atkFreeRevenue)/atkFreeRevenue