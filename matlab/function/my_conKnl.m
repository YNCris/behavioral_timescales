function K = my_conKnl(D,sigma)
K = exp(- (D .^ 2) / (2 * sigma ^ 2 + eps));

    