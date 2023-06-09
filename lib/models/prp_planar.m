%% DATASHEET FOR A PRP PLANAR ROBOT
% Insert in the following file all the inputs necessary to compute the
% dynamic model of a ... robot

lib_path = getenv("ROB2LIB_PATH");
addpath(lib_path);
rob2fun = rob2lib();

%% INPUTS
% PAY ATTENTION: update for each problem!

N = 3; % number of joints

% Suppose diagonal ineria matrix for each link
I_diag = true; 

% Load symbols in the workspace
run('rob2symb.m')

% Inertia matrix for each link
%celldisp(I) % uncomment for debug

% Definition of gravity vector
% Mind the position of gravity
g = [
    0;
    -g0;
    0;
];

% PAY ATTENTION: this part require a precomputation that depends on the problem
% Vectors of the centers of masses w.r.t world frame
W_CoM = {
    [
        q1; 
        0; 
        0;
    ], ...
    [
        (q1+k2) + d2*cos(q2); 
        d2*sin(q2); 
        0;
    ], ...
    [
        (q1+k2) + q3*cos(q2); 
        q3*sin(q2); 
        0;
    ], ...
};
% uncomment for debug
celldisp(W_CoM)

% Velocities of the centers of masses w.r.t world frame (derivative of W_CoM)
CoM_VELOCITY = {
    [
        q_dot1; 
        0;
        0;
    ], ... 
    [
        q_dot1 - d2*sin(q2)*q_dot2;
        d2*cos(q2)*q_dot2; 
        0;
    ], ...
    [
        q_dot1 + q_dot3*cos(q2) - q3*sin(q2)*q_dot2;
        q_dot3*sin(q2) + q3*cos(q2)*q_dot2;  
        0;
    ], ...
};
% uncomment for debug
celldisp(CoM_VELOCITY)

% Angular velocities of each link
OMEGA = {
    [
        0; 
        0; 
        0;
    ], ... 
    [
        0; 
        0; 
        q_dot2;
    ], ...
    [
        0; 
        0; 
        q_dot2;
    ], ...
};
% uncomment for debug
celldisp(OMEGA)