function output_seq = generate_markov_sequence(transmat, p_limit, T)
    % 获取状态数和状态转移矩阵的维度
    num_states = size(transmat, 1);
    
    % 随机选择初始状态
    current_state = randsrc(1,1,[1:num_states;p_limit']);
    
    % 初始化输出序列
    output_seq = zeros(1, T);
    output_seq(1) = current_state;
    
    % 生成输出序列
    for t = 2:T
        % 根据当前状态和状态转移矩阵计算下一个状态的概率分布
        next_state_probs = transmat(current_state,:);
        
        % 随机选择下一个状态
        current_state = randsrc(1,1,[1:num_states;next_state_probs]);
        
        % 将下一个状态添加到输出序列中
        output_seq(t) = current_state;
    end
end