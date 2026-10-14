function seglist = idx2savelist(idx)
%{
    transfer clustering idx to segmentation positions
%}
%%
addheadidx = [idx(1)-1;idx];
diffidx = diff(addheadidx);
bwidx = diffidx~=0;
startlist = find(bwidx==1);
addtailidx = [idx;idx(end)-1];
diffidx = flipud(diff(flipud(addtailidx)));
bwidx = diffidx~=0;
endlist = find(bwidx==1);
seglist = [startlist,endlist,idx(startlist)];