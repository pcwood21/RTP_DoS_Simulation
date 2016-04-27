classdef DSim < handle
    
    properties
        
        agentList={};
        timedEventQueue;
        currentTime=0;
        endTime=0;
        
    end
    
    methods
        
        function obj=DSim()
            obj.timedEventQueue=java.util.HashMap;
        end
        
        function queueEvent(obj,agentId,time)
            time=max(obj.currentTime,time);
            try
                agentExecList=obj.timedEventQueue.get(time);
            catch %#ok<CTCH>
                agentExecList=[];
            end
            
            if ~isempty(agentExecList)
                if ~any(agentExecList==agentId) %Doesn't exist in list
                    agentExecList(end+1)=agentId;
                else
                    return;
                end
            else
                agentExecList=agentId;
            end
            
            obj.timedEventQueue.put(time,agentExecList);
        end
        
        function [time,agentExecList]=getNextEvent(obj)
            agentExecList=[];
            time=inf;
            if obj.timedEventQueue.size() < 1
                return;
            end
            time=java.util.Collections.min((obj.timedEventQueue.keySet()));
            agentExecList=unique(obj.timedEventQueue.get(time));
            obj.timedEventQueue.remove(time);
        end
        
        function run(obj,end_time)
            time=0;
            obj.endTime=end_time;
            for k=1:length(obj.agentList)
                agent=obj.agentList{k};
                agent.init();
            end
            lastPct=0;
            tic;
            lastPctTime=zeros(3,1);
            while time < end_time
                [time,agentExecList]=obj.getNextEvent();
                obj.currentTime=time;
                %aList=obj.agentList;
                %for agentId=agentExecList'
                aList=obj.agentList(agentExecList);
                for k=1:length(aList)
                    agent=aList{k};
                    %agentId=agentExecList(k);
                    %agent=aList{agentId};
                    agent.execute(time);
                end
                
                newPct=floor(time/end_time*100);
                if newPct > lastPct
                    fprintf(1,'Sim %d%% Done (%2.1f Secs)\n',newPct,round(((100-lastPct)*mean(lastPctTime)*3),1));
                    lastPct=newPct;
                    lastPctTime=[lastPctTime(1:end-1); toc];
                    tic;
                end
            end
        end
        
        function send(obj,msg,dest)
            agent=obj.agentList{dest};
            agent.msgQueue{end+1}=msg;
            agent.queueAtTime(obj.currentTime);
        end
        
        function id = addAgent(obj,agent)
            obj.agentList{end+1}=agent;
            agent.id=length(obj.agentList);
            id=agent.id;
        end
        
        function aList = getAgentsByName(obj,aName)
            aList={};
            for i=1:length(obj.agentList)
                agent=obj.agentList{i};
                if isa(agent,aName)
                    aList{end+1}=agent;
                end
            end
        end
        
        
    end
    
    methods (Static)
        
        function obj = getInstance()
            persistent instance;
            if isempty(instance)
                obj=dsim.DSim();
                instance=obj;
            else
                obj=instance;
            end
        end

    end
    
end
