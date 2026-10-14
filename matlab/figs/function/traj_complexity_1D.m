function C = traj_complexity_1D(x)
dx = diff(x);
L = sum(abs(dx));
D = abs(x(end)-x(1));
C = L / max(D, eps);   % 防止除0
end