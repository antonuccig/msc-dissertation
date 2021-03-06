%% Preconditioned MINRES with absolute value circulant preconditioner for 
% the scalar non-linear reaction-diffusion equation.
% 
% Giancarlo Antonino Antonucci, 2017.

%% Grid
n = 100;           % space grid points
x0 = 0;            	% space start
xN = 1;            	% space end
dx = (xN-x0)/(n+1);	% space step size
x = x0:dx:xN;      	% space grid

m = 100;         	% time grid points
t0 = 0;             % time start
tM = .25;           % time end
dt = (tM-t0)/m;     % time step size
t = t0:dt:tM;       % time grid

%% Parameters
mu = dt/dx^2;       % grid ratio
gamma = 7;          % initial condition parameter
p = 2;              % exponent of the source term

%% Source Term and Conditions
u0 = gamma*exp(x(2:n+1)').*sin(pi*x(2:n+1)');

%% Nonlinear Loop
k = 1; jj = 0;
u_ = ones(n*m,1);
u = zeros(n*m,1);
while norm(u_ - u) > 1e-5 && k < 100
    u_ = u;
    
    % Linear system
    T = spdiags([-ones(n,1) 2*ones(n,1) -ones(n,1)], [-1 0 1], n, n);
    A0 = speye(n) + mu*T;
    A1 = -speye(n);
    A = kron(speye(m),A0) ...
        + kron(spdiags(ones(m,1), -1, m, m),A1);
    G = kron(speye(m),A0) ...
        + kron(spdiags(exp(2i*pi*(0:m-1)'/m), 0, m, m),A1);
    
    b = dt*u_.^p;
    b(1:n) = b(1:n) + u0;

    % preconditioned MINRES with absolute value circulant preconditioner
    for i = 1:m
        idx = (i-1)*n+1:i*n;
        G(idx,idx) = sparse(full(G(idx,idx)'*G(idx,idx))^(1/2));
    end

    A = A(end:-1:1,:); % A = Y*A; 
    b = b(end:-1:1); % b = Y*b;
    [u, j] = pminres(G, A, zeros(n*m,1), b, m, n);
    
    k = k + 1;
    jj = jj+j;
end
jj = jj/(k-1);

%% Plot
result = zeros(n+2,m+1);
result(2:n+1,1) = u0;
result(2:n+1,2:m+1) = reshape(real(u),n,m);

mesh(t,x,result)
xlabel('Time $t$'), ylabel('Space $x$'), zlabel('Solution $u$')
title(['iterations required: j = ' num2str(jj) ' (avg), k = ' num2str(k) ])
view([45,25])