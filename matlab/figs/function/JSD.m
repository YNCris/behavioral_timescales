function jsd = JSD(P,Q)
    eps = 1e-8;
    P = P(:) + eps; Q = Q(:) + eps;
    P = P / sum(P); Q = Q / sum(Q);
    M = 0.5*(P+Q);
    jsd = 0.5*sum(P.*log(P./M)) + 0.5*sum(Q.*log(Q./M));
end