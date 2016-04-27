classdef Agent < handle

	properties
		id=[]; %Unique identifying ID
		msgQueue;
		commAgentId;
    end
    
    methods (Abstract)
        
    end
	
	methods
        
        function execute(obj,time) %#ok<INUSD>
            %keyboard
        end
	
		function obj=Agent()
            obj.msgQueue={};
        end
		
		function init(obj)
			obj.queueAtTime(0);
		end
		
		function queueAtTime(obj,time)
			DSim=dsim.DSim.getInstance();
			if time < DSim.currentTime
				time=DSim.currentTime;
			end
			DSim.queueEvent(obj.id,time);
        end
		
		function msg=recv(obj)
			if length(obj.msgQueue) < 1
				msg=[];
				return;
			end
			msg=obj.msgQueue{1};
            obj.msgQueue(1)=[];
        end
        
        function ret=hasWaitingMsg(obj)
            ret = 0;
            if length(obj.msgQueue) >= 1
                ret=1;
            end
        end
		
		function sendComm(obj,msg,dest)
			DSim=dsim.DSim.getInstance();
			msg.newDest=dest;
            if isempty(obj.commAgentId)
                obj.send(msg,dest);
            else
                if length(obj.commAgentId)==1
                    DSim.send(msg,obj.commAgentId);
                    DSim.queueEvent(obj.commAgentId,0);
                else
                    for i=1:length(obj.commAgentId)
                        cAgent=DSim.agentList{obj.commAgentId(i)};
                        if dest==cAgent.availDestAgent
                            DSim.send(msg,obj.commAgentId(i));
                            DSim.queueEvent(obj.commAgentId(i),0);
                            break;
                        end
                    end
                end
            end
		end
		
    end
    
    methods (Static)
        function send(msg,dest)
			DSim=dsim.DSim.getInstance();
			destAgent = DSim.agentList{dest};
			DSim.send(msg,dest);
			DSim.queueEvent(destAgent.id,0);
        end
		
		
		function t=getCurrentTime()
			DSim=dsim.DSim.getInstance();
			t=DSim.currentTime;
		end
		
    end
end
