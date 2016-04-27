loadts=[];
loadval=[];
forecastts=[];
forecastval=[];
for days=19:1:26
    [TimeStamp,TimeZone1,Name,PTID,Load] = import_iso_actualload(['201506' num2str(days) 'pal.csv']);
    uTS=unique(TimeStamp);
    tLoad=[];
    for i=1:length(uTS)
        tLoad(i)=sum(Load(TimeStamp==uTS(i)));
    end
    loadts=[loadts; uTS;];
    loadval=[loadval tLoad];

    [TimeStamp,Capitl,Centrl,Dunwod,Genese,HudVl,Longil,MhkVl,Millwd,NYC,North,West,NYISO] ...
        =import_iso_loadforecast(['201506' num2str(days) 'isolf.csv'],2,2+23);
    forecastts=[forecastts; TimeStamp];
    forecastval=[forecastval; NYISO];
end

figure;
hold all;
plot(loadts,loadval','LineWidth',2);
plot(forecastts,forecastval,'--','LineWidth',2);
legend('Actual','Forecast');
ylabel('Load (MW)');
set(gca,'FontSize',12);
set(gca,'FontName','Times New Roman');
xlabel('Time');
hold off;


return;

loadts=[];
loadval=[];
forecastts=[];
forecastval=[];
for days=19
    [TimeStamp,TimeZone1,Name,PTID,Load] = import_iso_actualload(['201307' num2str(days) 'pal.csv']);
    uTS=unique(TimeStamp);
    tLoad=[];
    for i=1:length(uTS)
        tLoad(i)=sum(Load(TimeStamp==uTS(i)));
    end
    loadts=[loadts; uTS;];
    loadval=[loadval tLoad];

    [TimeStamp,Capitl,Centrl,Dunwod,Genese,HudVl,Longil,MhkVl,Millwd,NYC,North,West,NYISO] ...
        =import_iso_loadforecast(['201307' num2str(days) 'isolf.csv'],2,2+23);
    forecastts=[forecastts; TimeStamp];
    forecastval=[forecastval; NYISO];
end



figure;
hold all;
plot(loadts,loadval');
plot(forecastts,forecastval);
hold off;

ftime=datenum(forecastts);
ltime=datetime(loadts);
ftime=ftime-min(ftime);
ltime=ltime-min(ltime);
[Y,M,D,H,MN,S] = datevec(ltime);
iltime=D*24*60+H*60+MN+S/60;
iltime=iltime*60;
[Y,M,D,H,MN,S] = datevec(ftime);
iftime=D*24*60+H*60+MN+S/60;
iftime=iftime*60;

loadmodel = fit(iltime, loadval', 'cubicinterp');
forecastmodel = fit(iftime,forecastval,'cubicinterp');

loadfit=loadmodel(iltime);
forecastfit=forecastmodel(iftime);

errorsignal=loadmodel(iltime)-forecastmodel(iltime);

errormodel=fit(iltime,errorsignal,'linearinterp');

figure;
hold all;
plot(iltime,loadval');
plot(iltime,loadfit,'--');
plot(iftime,forecastval);
plot(iftime,forecastfit,'--');
hold off;

figure;
hold all;
plot(iltime/60/60/24+19,loadmodel(iltime)-forecastmodel(iltime),'LineWidth',2);
xlabel('Day (June 2015)');
ylabel('Error (MW)');
set(gca,'FontSize',12);
set(gca,'FontName','Times New Roman');
hold off;