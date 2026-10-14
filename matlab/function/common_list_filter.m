function x_out = common_list_filter(x_in,med_win,smo_win)
% med_win = 120;
% smo_win = 120;
x_out = smooth(medfilt1(x_in,med_win),smo_win);

















