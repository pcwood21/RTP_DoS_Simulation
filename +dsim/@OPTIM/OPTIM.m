classdef OPTIM < handle
    
    properties
        Fhist=[];
        Xhist=[];
        a=1;
        y=2; %Expansion y
        p=0.5; %Contraction B
        o=0.9; %Shrink coeff.
        
        Rw=0.03;
        Rb=0.1;
        
        Xc=[];
        fXc=[];
        Xr=[];
        fXr=0;
        Xo=[];
        Xe=[];
        fXe=0;
        Fvals=[];
        Xvals=[];
        
        seqNumList=[];
        lastSeqNum=1;
    end
    
    methods
        function obj=OPTIM()
        end
        
        function setParams(obj,x0,f0)
            obj.Xhist=x0;
            obj.Fhist=f0;
            obj.seqNumList=zeros(length(x0),1);
        end
        
        function x=getX(obj)
            if isempty(obj.Xhist)
                x=[];
                return;
            end
            [~,idx]=sort(obj.Fhist);
            x=obj.Xhist(idx(1));
        end
        
        function o=getSeqNum(obj)
            o=obj.lastSeqNum;
        end
        
        function putSeqFval(obj,fval,seqNum)
            obj.Fhist(obj.seqNumList==seqNum)=fval;
        end
      
        function putfXf(obj,fXf)
            obj.Fhist(1)=fXf;
            obj.seqNumList(1)=obj.lastSeqNum;
        end
        
        %Refelction
        function Xr=getXr(obj)
            %Order values of F from history
            [Fvals,idx]=sort(obj.Fhist);
            obj.Fhist=Fvals;
            obj.Xhist=obj.Xhist(idx);
            obj.seqNumList=obj.seqNumList(idx);
            Xvals=obj.Xhist(:,idx);
            Xn1=Xvals(:,end);
            Xvals(:,end)=[];
            Fvals(end)=[];
            Xo=mean(Xvals);
            Rv=randn();%-0.5;
            Xstd=var(obj.Xhist);
            R=Rv*(obj.Rw+obj.Rb/(Xstd+obj.Rb));
            Xr=Xo+obj.a*(Xo-Xn1)+R;
            obj.Xr=Xr;
            obj.Xo=Xo;
            obj.Xvals=Xvals;
            obj.Fvals=Fvals;
            %Investigate f(Xr)
            obj.lastSeqNum=obj.lastSeqNum+1;
            return;
        end
        
        function [cont, Xec] =putfXr(obj,fXr)
            obj.fXr=fXr;
            cont=0;
            Xec=[];
            
            
            
            if obj.Fvals(1) <= fXr && fXr < obj.Fvals(end)
                %disp('reflection');
                obj.seqNumList(end)=obj.lastSeqNum;
                obj.Xhist(end)=obj.Xr;
                obj.Fhist(end)=fXr;
                return;
            end
            
            %expansion
            if fXr < obj.Fvals(1)
                cont=1;
                Xec=obj.Xo+obj.y*(obj.Xo-obj.Xhist(end));
                %Xec=obj.y*obj.Xr+(1-obj.y)*obj.Xo;
                obj.Xe=Xec;
                obj.lastSeqNum=obj.lastSeqNum+1;
                return;
            end
            
            if obj.Fhist(1) < 0.5 %Reassess best value
                %disp('Var Low');
                Xec=obj.Xhist(1);
                obj.lastSeqNum=obj.lastSeqNum+1;
                cont=3;
                return;
            end
            
            
            %attempt contraction
            if fXr >= obj.Fvals(end)
                cont=2;
                Xec=obj.Xvals(end);
                obj.lastSeqNum=obj.lastSeqNum+1;
            end
            
        end
        
        function [cont, Xec] = getContraction(obj)
            cont=0;
            Xec=[];
            
            if obj.fXr >= obj.Fvals(end)
                cont=2;
                Xec=obj.Xvals(end);
                obj.lastSeqNum=obj.lastSeqNum+1;
            end
        end
        
        function [cont, Xec] =putfXrC(obj,fXrC)
            cont=0;
            Xec=[];
            obj.seqNumList(end-1)=obj.lastSeqNum;
            obj.Fvals(end)=fXrC;
            obj.Fhist(end-1)=fXrC;
            if obj.fXr >= obj.Fvals(end)
                cont=2; %Contraction
                %Xec=obj.Xo+obj.p*(obj.Xo-obj.Xhist(end));
                Xec=obj.p*obj.Xhist(end)+(1-obj.p)*obj.Xo;
                obj.Xc=Xec;
                obj.lastSeqNum=obj.lastSeqNum+1;
                return;
            end
        end
        
        function putfXe(obj,fXe)
            obj.fXe=fXe;
            if fXe < obj.Fvals(1)
                %disp('expansion');
                obj.seqNumList(end)=obj.lastSeqNum;
                obj.Xhist(end)=obj.Xe;
                obj.Fhist(end)=obj.fXe;
            else
                %disp('Accept Reflection');
                obj.seqNumList(end)=obj.lastSeqNum;
                obj.Xhist(end)=obj.Xr;
                obj.Fhist(end)=obj.fXr;
            end
            
        end
        
        function [cont] = putfXc(obj,fXc)
            obj.fXc=fXc;
            if fXc < obj.Fhist(end)
                %disp('contraction');
                obj.seqNumList(end)=obj.lastSeqNum;
                obj.Fhist(end)=obj.fXc;
                obj.Xhist(end)=obj.Xc;
                cont=0;
                return;
            end
            %disp('shrink');
            cont=1; %Reduction/Shrink
            return;
        end
        
        %Shrink
        function [xVect]=getReduction(obj)
            xVect=zeros(length(obj.Xhist)-1,1);
            for i=2:length(obj.Xhist)
                xVect(i-1)=obj.Xhist(1)+obj.o*(obj.Xhist(i)-obj.Xhist(1));
                obj.lastSeqNum=obj.lastSeqNum+1;
                obj.seqNumList(i)=obj.lastSeqNum;
            end
            obj.Xhist(2:end)=xVect;
            return;
        end
        
        %Shrink
        function [xVect,seqList]=getReductionResample(obj)
            xVect=zeros(length(obj.Xhist),1);
            for i=1:length(obj.Xhist)
                xVect(i)=obj.Xhist(1)+obj.o*(obj.Xhist(i)-obj.Xhist(1));
                obj.lastSeqNum=obj.lastSeqNum+1;
                obj.seqNumList(i)=obj.lastSeqNum;
            end
            obj.Xhist(1:end)=xVect;
            seqList=obj.seqNumList;
            return;
        end
        
        function putReductionValsResample(obj,idx,fVal)
            obj.Fhist(idx)=fVal;
        end
        
        function putReductionVals(obj,idx,fVal)
            obj.Fhist(idx+1)=fVal;
        end
        
    end
    
end