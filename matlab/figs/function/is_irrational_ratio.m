function is_irr = is_irrational_ratio(x)
    % 先检查是否是整数
    if mod(x, 1) == 0
        is_irr = false; % 整数是有理数
        return;
    end
    
    % 尝试寻找整数比值表示
    [num, den] = rat(x, 1e-6); % 逼近有理数
    is_irr = abs(num / den - x) > 1e-6; % 误差较大则可能是无理数
end