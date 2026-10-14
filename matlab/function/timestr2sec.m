function secmat = timestr2sec(timestrcell)
%{
    transfer time string cell to second mat
%}
%% check format if '-'
for k = 1:size(timestrcell,1)
    tempstr = strsplit(timestrcell{k,1},'-');
    if length(tempstr) == 5
        newstr = [char(tempstr(1)),'-',...
            char(tempstr(2)),'-',...
            char(tempstr(3)),':',...
            char(tempstr(4)),':',...
            char(tempstr(5))];
        timestrcell{k,1} = newstr;
    end
end
%%
secmat = zeros(size(timestrcell,1),1);
for k = 1:size(timestrcell,1)
    secmat(k,1) = datenum(timestrcell{k,1})*24*60*60;
end
