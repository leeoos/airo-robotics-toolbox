%% Sopravvivenza_AIRO! 
% Authors: Massimo, Leonardo, Paolo, Francesco

clc 
close all
clear all

my_path = getenv("ROB2LIB_PATH");
addpath(my_path);
FunObj = Rob2Lib();

%% INPUTS FOR THE PROBLEM
% PAY ATTENTION: update for each problem!

syms L1 L2 L3 q1 q2 q3 

% Direct kinematics.
DHTABLE = [        
    0    L1     0   q1;
    pi/2 0      0   q2;
    0    L3     0   q3;
];
N = size(DHTABLE, 1); % number of joints

syms d1 d2 d3 V F D C E
% Vectro of the centers of masses
RCoM = {[-L1+d1;0;0], [0;-L2+d2;0], [-L3+d3;0;0]};

% sigma vector:
% 0: revolout 
% 1: prismatic
sigma = [
    0;
    0;
    0;
];

% Initial conditions for angular velocity
initial_omega = [
    0;
    0;
    0;
];
OMEGA = cell(1, N);
OMEGA{1} = initial_omega;

% Initial conditions for linear velocity
initial_velocity = [
    0;
    0;
    0;
];
VELOCITY = cell(1, N);
VELOCITY{1} = initial_velocity;
%% END OF INPUTS

pose = FunObj.compute_dir_kin(DHTABLE);
A = pose{1}; % cell array of chain transformations

% Initialization of symbolics vectors
q = (sym('q',[1 N]));
q_dot = (sym('q_dot',[1 N]));
masses = (sym('m',[1 N]));

% Inertia Matricies (Evaluate if you have numbers!)
Ixxsymb = (sym('Ixx',[1 N]));
Iyysymb = (sym('Iyy',[1 N]));
Izzsymb = (sym('Izz',[1 N]));
Ixysymb = zeros(1,N); %(sym('Ixy',[1 N]));
%Iyxsymb = (sym('Iyx',[1 N]));
%Izxsymb = (sym('Izx',[1 N]));
Ixzsymb = zeros(1,N); %(sym('Ixz',[1 N]));
Iyzsymb = zeros(1,N); %(sym('Iyz',[1 N]));
%Izysymb = (sym('Izy',[1 N]));
I = cell(1,3);
for i =(1:N)
    I{i} = [
        Ixxsymb(i), Ixysymb(i), Ixzsymb(i);
        Ixysymb(i), Iyysymb(i), Iyzsymb(i);
        Ixzsymb(i), Iyzsymb(i), Izzsymb(i);
    ];
end

% KINETIC_ENERGY = masses(1) * ((transpose(VELOCITY{1})*VELOCITY{1}) + ... 
%                  (transpose(OMEGA{1})*I{1}*OMEGA{1}));
KINETIC_ENERGY = 0;

% Computaion of linear and angular velocity of each link,
% velocity of CoM and kinetic energy of each link.
for i = (1 : N)
    R_i = A{i}(1:3, 1:3); % Rotation matrix
    r_i = A{i}(1:3, 4);
    z = [0;0;1];

    % Angular velocity
    im1_omega_i = (OMEGA{i} + (1-sigma(i))*q_dot(i)*z);
    i_omega_i = transpose(R_i)*im1_omega_i;
    OMEGA{i+1} = simplify(i_omega_i);
  

    % Linear velocity
    velocity_new = transpose(R_i) * ...
                   (VELOCITY{i} + (sigma(i)*q_dot(i)*z) + cross(im1_omega_i,r_i));
    VELOCITY{i+1} = simplify(velocity_new);  
    

    % Velocity of centers of masses
    velocity_CoM = simplify(VELOCITY{i+1} + cross(OMEGA{i+1}, RCoM{i}));

    KINETIC_ENERGY = KINETIC_ENERGY + (...
                     (1/2*masses(i)*transpose(velocity_CoM)*velocity_CoM) + ... 
                     (1/2*transpose(OMEGA{i+1})*I{i}*OMEGA{i+1})...
                    );
    disp(["Step ", i])
    KINETIC_ENERGY = simplify(KINETIC_ENERGY)
    
end

KINETIC_ENERGY = simplify(expand(KINETIC_ENERGY))

aliases = sym("alias",[1 N]);
q_dot_squared = [sym("foo")];
for i = (1:N)
    q_dot_squared(i) = str2sym("q_dot"+string(i)+"^2");
end
q_dot_squared;
KIN_alias = subs(KINETIC_ENERGY,q_dot_squared,aliases);

reduced_q_dot = [sym("foo")];
M = [sym("bar")];
for r = (1:N)
    for c = (1:N)
        if (r == c)
            reduced_alias = aliases(aliases~=aliases(r));
            KIN_q_dot_squared = subs(KIN_alias, q_dot, zeros(1,N));
            KIN_qr_dot_squared = subs(KIN_q_dot_squared, reduced_alias, zeros(1,N-1));
            M(r,c) = simplify(2*subs(KIN_qr_dot_squared, aliases(r), 1));

        else
            reduced_q_dot = q_dot;
            reduced_q_dot(reduced_q_dot == q_dot(c)) = [];
            reduced_q_dot(reduced_q_dot == q_dot(r)) = [];
            KIN_q_dot = subs(KIN_alias, aliases, zeros(1,N));
            if not(isempty(reduced_q_dot))
                KIN_q_dot = subs(KIN_q_dot, reduced_q_dot, zeros(1,N-2));
            end
            M(r,c) = subs(KIN_q_dot, {q_dot(r),q_dot(c)}, {1,1});
        end
    end
end
M

M_foo = [sym("foo")];
for i = (1:N)
    KINETIC_ENERGY = collect(KINETIC_ENERGY, q_dot(i)^2);
end

for r = (1:N)
    for c = (1:N)
        if ((r == c))
            M_foo(r,c) = simplify(diff(KINETIC_ENERGY, q_dot(r), 2));
        else
            K_reduced_qr = simplify(diff(KINETIC_ENERGY, q_dot(c)));
            K_reduced_qrc = simplify(diff(K_reduced_qr, q_dot(r)));
            M_foo(r,c) = simplify(K_reduced_qrc);
        end
    end
end

disp(["Are M_string and M_diff equal?", isequal(M, M_foo)])