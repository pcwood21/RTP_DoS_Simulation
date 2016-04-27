

numGen=2;
numConsumer=20;
numPlayers=numGen+numConsumer;
x0=0;

genB=rand(numGen,1)*numConsumer/numGen/20;
genC=rand(numGen,1)*numConsumer/numGen/10;
conB=1*rand(numConsumer,1)*numGen/numConsumer*5;
conC=1*rand(numConsumer,1)*numGen/numConsumer/10;
%sum(1./(1+exp(conB.*x)))
optfun=@(x) abs(-sum(1./(1+exp(conB.*x))) + sum(5./(1+exp(-genB.*x))));

%testing
x=0.01:0.01:10;
for i=1:length(x)
    y(i)=optfun(x(i));
end
plot(x,y);

nTestPoints=10;
x0=linspace(0,10,nTestPoints);
for i=1:length(x0)
    f0(i)=optfun(x0(i));
end
OPT=dsim.OPTIM(nTestPoints,x0,f0);

return;

nIter=0;
lastX=x0(end);
while nIter<500 && optfun(lastX)>0.01
    nIter=nIter+1;
    lastX=OPT.getX();
    Xr=OPT.getXr();
    fXr=optfun(Xr);
    [cont, Xec] = OPT.putfXr(fXr);
    if cont==0
        continue;
    end
    if cont==1
        %Xc
        fXe=optfun(Xec);
        OPT.putfXe(fXe);
        continue;
    else %cont==2
        fXc=optfun(Xec);
        cont2=OPT.putfXc(fXc);
        if cont2==0
            continue;
        end
    end
    
    xVect=OPT.getReduction();
    for k=1:length(xVect)
        fval=optfun(xVect(k));
        OPT.putReductionVals(k,fval);
    end
end