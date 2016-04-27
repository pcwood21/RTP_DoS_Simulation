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

PrHist(1:length(PrHist)/10)=[]; %Throw away the first initilization samples
PrChange=diff(smooth(PrHist,T_w/2));

figure;
hold all;
plot(PrHist)
plot(smooth(PrHist,T_w/2))
hold off;

figure;
%hold all;
x1=1:length(PrHist);
x2=1:length(PrChange);
plotyy(x1,PrHist,x2,PrChange);
%hold off;

prTrain.maxDiff=max(PrChange);
prTrain.minDiff=min(PrChange);
prTrain.maxPrice=max(PrHist);
prTrain.minPrice=min(PrHist);



[revenue,doshours]=secretary_calc(20,prTrain,1);


