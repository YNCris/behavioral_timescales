function p_limit = tm2limit(transmat)
class_num = size(transmat,1);
a = [transmat'-eye(class_num);ones(1,class_num)];
b = [zeros(class_num,1);1];
p_limit = a\b;