d=genpath(pwd);
[t,s]=strtok(d,pathsep());
while(~isempty(s))
    if(isempty(regexp(t,'(\.svn|\.git|tmp)')))
        addpath(t);
    end
    [t,s]=strtok(s,pathsep());
end
clear d s t