function revenue = exp1_revenue_func(buyPR,sellPR,TestPrHist,battchargeRate,timeTestDay,T_w,battMaxE,PrMWtokW)

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

end