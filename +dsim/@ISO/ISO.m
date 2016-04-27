classdef ISO < dsim.Agent

	properties
		clientList=[];
		clientPower=[];
        clientLastRxTime=[];
        clientPowerHist=[];
        clientPowerHistSeq=[];
		nextExecTime=0;
		execPeriod=1;
        OPT;
        lastX=0;
        bestPrice=0;
        priceState=0;
        xVect=[];
        xVectK;
        nVar=6;
        x0;
        f0;
        runInit=1;
        seqNum=0;
        optInit=1; %Initialize optimally ie with ground truth
        xSeqVect=[];
	end
	
	methods
		function obj=ISO()
            obj.OPT=[];
            obj.OPT=dsim.OPTIM();
		end
		
		function init(obj)
            
            obj.x0=[];
            obj.f0=[];
            obj.runInit=1;
            obj.priceState=0;
            obj.nextExecTime=obj.execPeriod;
            obj.queueAtTime(obj.nextExecTime);
		end
		
		function execute(obj,time)
		
			while obj.hasWaitingMsg()
				msg=obj.recv();
				if strcmp(msg.type,'register')
					obj.clientList(end+1)=msg.id;
					obj.clientPower(end+1)=0;
                    obj.clientLastRxTime(end+1)=time;
                elseif strcmp(msg.type,'powerLevel')
                    if obj.seqNum==msg.seqNum
                        obj.clientPower(obj.clientList==msg.id)=msg.Power;
                        obj.clientPowerHist(obj.clientPowerHistSeq==msg.seqNum,obj.clientList==msg.id)=msg.Power;
                    else
                        if any(obj.clientPowerHistSeq==msg.seqNum)
                            obj.clientPowerHist(obj.clientPowerHistSeq==msg.seqNum,obj.clientList==msg.id)=msg.Power;
                            nfval=obj.optfunhist(msg.seqNum);
                            obj.OPT.putSeqFval(nfval,msg.seqNum);
                            %disp('Stale Info');
                        else
                            %disp('Dropped Info');
                        end
                    end
                    obj.clientLastRxTime(obj.clientList==msg.id)=time;
				end
			end
			
			if time>=obj.nextExecTime
				obj.nextExecTime=time+obj.execPeriod;
				obj.queueAtTime(obj.nextExecTime);
                obj.cleanSeqHist();
				X=obj.processPrices(time);
                obj.predictPower(X,time);
                obj.lastX=X;
				obj.sendPrices(X,time);
			end
		
        end
        
        function cleanSeqHist(obj)

            activeSeqs=obj.OPT.seqNumList;
            rmIdx=zeros(length(obj.clientPowerHistSeq),1);
            for i=1:length(obj.clientPowerHistSeq)
                if ~any(obj.clientPowerHistSeq(i)==activeSeqs)
                    rmIdx(i)=1;
                end
            end
            obj.clientPowerHistSeq(rmIdx==1)=[];
            obj.clientPowerHist(rmIdx==1,:)=[];

        end
		
        function val=optfun(obj)
            val=abs(sum(obj.clientPower));
        end
        
            function val=optfunhist(obj,seq)
                val=-1;
                if ~any(obj.clientPowerHistSeq==seq)
                    return;
                else
                    cPower=obj.clientPowerHist(seq==obj.clientPowerHistSeq,:);
                    cPower=squeeze(cPower);
                    val=abs(sum(cPower));
                end
            end
        
        function predictPower(obj,X,time)
            if ~isempty(obj.seqNum)
                obj.clientPowerHistSeq(end+1)=obj.seqNum;
            end
            nClients=length(obj.clientList);
            obj.clientPowerHist(end+1,:)=zeros(nClients,1);
            DSim=dsim.DSim.getInstance();
            for i=1:nClients
                agent=DSim.agentList{obj.clientList(i)};
                LATime=time-obj.clientLastRxTime(i);
                p=agent.predictPower(X,time,LATime);
                obj.clientPower(obj.clientList==agent.id)=p;
                if ~isempty(obj.seqNum)
                    obj.clientPowerHist(end,obj.clientList==agent.id)=p;
                end
            end  
        end
        
        function sendPrices(obj,X,time)
            bestPrice=obj.OPT.getX();
            if isempty(bestPrice)
                bestPrice=X;
            end
            obj.bestPrice=bestPrice;
            %obj.seqNum=obj.seqNum+1;
            nClients=length(obj.clientList);
            idx=randperm(nClients);
            for i=1:nClients
                msg=struct();
                msg.lambda=bestPrice;
                msg.testLambda=X;
                msg.sTime=time;
                msg.seqNum=obj.seqNum;
                if isempty(obj.seqNum)
                    keyboard
                end
                dest=obj.clientList(idx(i));
                obj.sendComm(msg,dest);
            end
            
        end
        
		function X=processPrices(obj,time)
            state=obj.priceState;
            if obj.runInit
                %Initialization
                if obj.optInit==1
                    DSim=dsim.DSim.getInstance();
                    aList=DSim.getAgentsByName('dsim.MktPlayer');
                    X=dsim.optimalPrice(aList,[],time)+rand()*1e-1;
                else
                    X=rand()*100;
                end
                obj.seqNum=obj.seqNum+1;
                obj.x0(end+1)=X;
                if state > 0
                    obj.f0(end+1)=obj.optfun();
                end
                if state > obj.nVar
                    obj.runInit=0;
                    obj.priceState=0;
                    obj.x0(end)=[];
                    obj.OPT.setParams(obj.x0,obj.f0);
                    X=obj.processPrices(time);
                    return;
                end
                obj.priceState=obj.priceState+1;
                return;
            end
            switch state
                case 0 %Send Xr
                    Xr=obj.OPT.getXr();
                    X=Xr;
                    obj.seqNum=obj.OPT.getSeqNum();
                    obj.priceState=1;
                    return;
                case 1 %process fXr
                    fXr=obj.optfun();
                    [cont, Xec] = obj.OPT.putfXr(fXr);
                    if cont==0
                        obj.priceState=0;
                        X=obj.processPrices(time);
                        return;
                    end
                    X=Xec;
                    if cont==1
                        obj.priceState=2; %Sending Xe
                    elseif cont==2
                        obj.priceState=5; %Sending Xlast for recalc
                    else %cont==3
                        obj.priceState=6; %Re-evaluate best X
                    end
                    return;
                case 2 %Process fXe
                        fXe=obj.optfun();
                        obj.OPT.putfXe(fXe);
                        obj.priceState=0;
                        X=obj.processPrices(time);
                        return;
                case 5 %Process f-recalc
                        fRecalc=obj.optfun();
                        [cont, Xc] = obj.OPT.putfXrC(fRecalc);
                        if cont==2
                            X=Xc;
                            obj.seqNum=obj.OPT.getSeqNum();
                            obj.priceState=3;
                            return;
                        end
                        obj.priceState=0;
                        X=obj.processPrices(time);
                        return;
                case 3 %Process fXc
                    fXc=obj.optfun();
                    cont2=obj.OPT.putfXc(fXc);
                        if cont2==0
                            obj.priceState=0;
                            X=obj.processPrices(time);
                            return;
                        end
                    obj.priceState=4; %Reduction
                    [obj.xVect,obj.xSeqVect]=obj.OPT.getReductionResample();
                    X=obj.xVect(1);
                    obj.seqNum=obj.xSeqVect(1);
                    obj.xVectK=2;
                    return;
                case 4 %Process reduction 
                    if obj.xVectK <= length(obj.xVect)+1 %Process fXvect
                        fval=obj.optfun(); %Value for xVect(k-1)
                        obj.OPT.putReductionValsResample(obj.xVectK-1,fval);
                    end
                    if obj.xVectK <= length(obj.xVect) %Still procesing new values
                        X=obj.xVect(obj.xVectK);
                        obj.seqNum=obj.xSeqVect(obj.xVectK);
                        obj.xVectK=obj.xVectK+1;
                    else
                        obj.xVectK=obj.xVectK+1;
                        obj.priceState=0;
                        X=obj.processPrices(time);
                    end
                    return;
                case 6 %Process re-eval of best point
                    fval=obj.optfun();
                    obj.OPT.putfXf(fval);
                    [cont, Xe] = obj.OPT.getContraction();
                    if cont==0
                        obj.priceState=0;
                        X=obj.processPrices(time);
                    else %cont==2 , contraction
                        obj.priceState=5;
                        X=Xe;
                        obj.seqNum=obj.OPT.getSeqNum();
                    end
                    return;
            otherwise
                return;
            end
			
		end
		
	end

end
