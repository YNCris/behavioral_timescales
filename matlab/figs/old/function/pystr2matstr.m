function new_str_list = pystr2matstr(tempmsk)
new_str_list = cell(size(tempmsk,1),size(tempmsk,2));
for n = 1:size(new_str_list,1)
    ttmsk = reshape(tempmsk(n,:,:),...
        [size(tempmsk,2),size(tempmsk,3)]);
    new_ttmsk = cell(1,size(ttmsk,1));
    % delete blank
    for m = 1:size(new_ttmsk,2)
        tempstr = deblank(ttmsk(m,:));
        new_ttmsk{1,m} = tempstr;
    end
    new_str_list(n,:) = new_ttmsk;
end