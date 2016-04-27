
nConsumer=100;
nGenerator=2;
rng(0); %ensures repeatability

C_PrMin=zeros(nConsumer,1);
C_PrMax=abs(normrnd(250,75,nConsumer,1));
C_Pmin=abs(normrnd(0,0.5,nConsumer,1));
C_Pmax=abs(normrnd(3,1,nConsumer,1));

%Fix the distributions to make sense
C_Pmin(C_Pmin>C_Pmax)=C_Pmax(C_Pmin>C_Pmax);
C_Pmax(C_Pmax<C_Pmin)=C_Pmin(C_Pmax<C_Pmin);
C_PrMin(C_PrMin>C_PrMax)=C_PrMax(C_PrMin>C_PrMax);
C_PrMax(C_PrMax<C_PrMin)=C_PrMin(C_PrMax<C_PrMin);

G_PrMin=abs(normrnd(30,5,nGenerator,1));
G_PrMax=abs(normrnd(80,5,nGenerator,1));
G_Pmin=-abs(normrnd(3*nConsumer/nGenerator,1*nConsumer/nGenerator,nGenerator,1));
G_Pmax=zeros(nGenerator,1);

%Fix the distributions to make sense
G_Pmin(G_Pmin>G_Pmax)=G_Pmax(G_Pmin>G_Pmax);
G_Pmax(G_Pmax<G_Pmin)=G_Pmin(G_Pmax<G_Pmin);
G_PrMin(G_PrMin>G_PrMax)=G_PrMax(G_PrMin>G_PrMax);
G_PrMax(G_PrMax<G_PrMin)=G_PrMin(G_PrMax<G_PrMin);

PrMin=[C_PrMin; G_PrMin];
PrMax=[C_PrMax; G_PrMax];
Pmin=[C_Pmin; G_Pmin];
Pmax=[C_Pmax; G_Pmax];

prS=@(Pr) 6*(Pr-PrMin)./(PrMax-PrMin)-3;
flexP=@(Pr) sum((Pmax-Pmin)./(1+exp(prS(Pr)))+Pmin);

%{
PrTest=-20:3:200;
RP=[];
Pc=[];
Pg=[];
G_prS=@(Pr) 6*(Pr-G_PrMin)./(G_PrMax-G_PrMin)-3;
G_flexP=@(Pr) sum((G_Pmax-G_Pmin)./(1+exp(G_prS(Pr)))+G_Pmin);
for i=1:length(PrTest)
    prC=PrTest(i)*ones(nConsumer+nGenerator,1);
    prC(end-2:end)=-10000;
    Pc(i)=flexP(prC);
    Pg(i)=G_flexP(PrTest(i)*ones(nGenerator,1));
    RP(i)=flexP(PrTest(i)*ones(nConsumer+nGenerator,1));
end
figure;
hold all;
plot(PrTest,abs(RP),'-','LineWidth',2);
plot(PrTest,Pc,'--','LineWidth',1.5);
plot(PrTest,-Pg,':','LineWidth',1.5);
xlabel('Price ($)');
ylabel('Power Level (kW)');
xlim([-20 200]);
legend('Residual','Consumption','Generation');
set(gca,'FontSize',12);
set(gca,'FontName','Times New Roman');


%}

flexFullP=@(Pr) (Pmax-Pmin)./(1+exp(prS(Pr)))+Pmin;
calcDI=@(Pr) flexFullP(Pr.*ones(nConsumer+nGenerator,1))-flexFullP((Pr-1).*ones(nConsumer+nGenerator,1));


calcDIRP=@(Pr) deal(flexFullP(Pr.*ones(nConsumer+nGenerator,1))-flexFullP(-1000.*ones(nConsumer+nGenerator,1)), flexFullP(Pr.*ones(nConsumer+nGenerator,1))-flexFullP(1000.*ones(nConsumer+nGenerator,1)));
