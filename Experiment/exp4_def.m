

noiseLevel=[0 .1 .2 .3 .5 .75 1 1.5 2];
atkRevs=zeros(length(noiseLevel),6);
for i=1:length(noiseLevel)
    for j=1:6
        [rev]=exp4_noise_calc(noiseLevel(i),j);
        atkRevs(i,j)=rev;
    end
end

pRevs=mean(atkRevs,2);
%pRevs(1)=atkFreeRevenue;

pInc=(pRevs-pRevs(1))./pRevs(1)*100;

figure('Position',[100,100,550,250]);
%Indeciies were downselected because number of seeds is too low
plot(noiseLevel([1 2 4 9]),pInc([1 2 4 9]),'LineWidth',2)
xlabel('\sigma^2');
ylabel('Attack Profit Reduction (%)');
set(gca,'FontSize',13);
set(gca,'FontName','Times New Roman');




swapCount=0:1:9;
atkRevs=zeros(length(swapCount),3);
for i=1:length(swapCount)
    for j=1:3
        [atkRevs(i,j)]=exp4_swap_calc(swapCount(i),j);
    end
end

%pRevs=trimmean(atkRevs,25,2)-0.3150;
pRevs=mean(atkRevs,2);
%pRevs(1)=atkFreeRevenue;

pInc=(pRevs-pRevs(1))./pRevs(1)*100;
%pInc=(pRevs-0.3150)./0.3150*100;

figure('Position',[100,100,550,250]);
plot(swapCount,pInc,'-','LineWidth',2)
ax=gca;
xlabel('Number of Swaps');
ylabel('Attack Profit Reduction (%)');
xlim([0 9]);
set(gca,'FontSize',12);
set(gca,'FontName','Times New Roman');

