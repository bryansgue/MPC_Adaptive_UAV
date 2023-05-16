function [Cbar] = C_matrix_bar(X,q,q_p)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
phi = q(4);
theta = q(5);
psi = q(6);

phi_p = q_p(4);
theta_p = q_p(5);
psi_p = q_p(6);

m1 = X(1);
Ixx = X(2);
Iyy = X(3);
Izz = X(4);

% Cbar =  [0, 0, 0,                                                                                                                                 0,                                                                                                                                                                                                                                               0,                                                                                                                                                                                                                               0;...
%     0, 0, 0,                                                                                                                                 0,                                                                                                                                                                                                                                               0,                                                                                                                                                                                                                               0;...
%     0, 0, 0,                                                                                                                                 0,                                                                                                                                                                                                                                               0,                                                                                                                                                                                                                               0;...
%     0, 0, 0,                                                                                                                                 0,                                                                                                                                               theta_p*sin(2*phi)*(Iyy/2 - Izz/2) - (psi_p*cos(theta)*(Ixx + Iyy*cos(2*phi) - Izz*cos(2*phi)))/2,                                                                                             - (theta_p*cos(theta)*(Ixx + Iyy*(2*cos(phi)^2 - 1) - Izz*(2*cos(phi)^2 - 1)))/2 - psi_p*cos(phi)*cos(theta)^2*sin(phi)*(Iyy - Izz);...
%     0, 0, 0,                                 (psi_p*cos(theta)*(Ixx + Iyy*cos(2*phi) - Izz*cos(2*phi)))/2 - (theta_p*sin(2*phi)*(Iyy - Izz))/2,                                                                                                                                                                                                               -(phi_p*sin(2*phi)*(Iyy - Izz))/2,                                                                           (phi_p*cos(theta)*(Ixx + Iyy*cos(2*phi) - Izz*cos(2*phi)))/2 + (psi_p*sin(2*theta)*(Iyy/2 - Ixx + Izz/2 - (Iyy*cos(2*phi))/2 + (Izz*cos(2*phi))/2))/2;...
%     0, 0, 0, psi_p*cos(phi)*cos(theta)^2*sin(phi)*(Iyy - Izz) - (theta_p*cos(theta)*(Ixx - Iyy*(2*cos(phi)^2 - 1) + Izz*(2*cos(phi)^2 - 1)))/2, - (phi_p*cos(theta)*(Ixx - Iyy*(2*cos(phi)^2 - 1) + Izz*(2*cos(phi)^2 - 1)))/2 - psi_p*cos(theta)*sin(theta)*(Iyy/2 - Ixx + Izz/2 - (Iyy*(2*cos(phi)^2 - 1))/2 + (Izz*(2*cos(phi)^2 - 1))/2) - theta_p*cos(phi)*sin(phi)*sin(theta)*(Iyy - Izz), theta_p*(Ixx*cos(theta)*sin(theta) - Iyy*cos(theta)*sin(theta) + Iyy*cos(phi)^2*cos(theta)*sin(theta) - Izz*cos(phi)^2*cos(theta)*sin(theta)) + phi_p*(Iyy*cos(phi)*cos(theta)^2*sin(phi) - Izz*cos(phi)*cos(theta)^2*sin(phi))];

Cbar = [ 0, 0, 0,                                                                                                                                                                                                                                                  0,                                                                                                                                                                                                                                                                                                                                                                                                      0,                                                                                                                                                                                                                                                                                                                0;...
    0, 0, 0,                                                                                                                                                                                                                                                  0,                                                                                                                                                                                                                                                                                                                                                                                                      0,                                                                                                                                                                                                                                                                                                                0;...
    0, 0, 0,                                                                                                                                                                                                                                                  0,                                                                                                                                                                                                                                                                                                                                                                                                      0,                                                                                                                                                                                                                                                                                                                0;...
    0, 0, 0,                                                                                                                                                                                                                                                  0,                                                                                                                                                                                     (Iyy*psi_p*cos(theta))/2 - (Ixx*psi_p*cos(theta))/2 - (Izz*psi_p*cos(theta))/2 - Iyy*psi_p*cos(phi)^2*cos(theta) + Izz*psi_p*cos(phi)^2*cos(theta) + Iyy*theta_p*cos(phi)*sin(phi) - Izz*theta_p*cos(phi)*sin(phi),                                                               (Iyy*theta_p*cos(theta))/2 - (Ixx*theta_p*cos(theta))/2 - (Izz*theta_p*cos(theta))/2 - Iyy*theta_p*cos(phi)^2*cos(theta) + Izz*theta_p*cos(phi)^2*cos(theta) - Iyy*psi_p*cos(phi)*cos(theta)^2*sin(phi) + Izz*psi_p*cos(phi)*cos(theta)^2*sin(phi);...
    0, 0, 0,                                 (Ixx*psi_p*cos(theta))/2 - (Iyy*psi_p*cos(theta))/2 + (Izz*psi_p*cos(theta))/2 + Iyy*psi_p*cos(phi)^2*cos(theta) - Izz*psi_p*cos(phi)^2*cos(theta) - Iyy*theta_p*cos(phi)*sin(phi) + Izz*theta_p*cos(phi)*sin(phi),                                                                                                                                                                                                                                                                                                                                              Izz*phi_p*cos(phi)*sin(phi) - Iyy*phi_p*cos(phi)*sin(phi), (Ixx*phi_p*cos(theta))/2 - (Iyy*phi_p*cos(theta))/2 + (Izz*phi_p*cos(theta))/2 + Iyy*phi_p*cos(phi)^2*cos(theta) - Izz*phi_p*cos(phi)^2*cos(theta) - Ixx*psi_p*cos(theta)*sin(theta) + Iyy*psi_p*cos(theta)*sin(theta) - Iyy*psi_p*cos(phi)^2*cos(theta)*sin(theta) + Izz*psi_p*cos(phi)^2*cos(theta)*sin(theta);...
    0, 0, 0, (Izz*theta_p*cos(theta))/2 - (Iyy*theta_p*cos(theta))/2 - (Ixx*theta_p*cos(theta))/2 + Iyy*theta_p*cos(phi)^2*cos(theta) - Izz*theta_p*cos(phi)^2*cos(theta) + Iyy*psi_p*cos(phi)*cos(theta)^2*sin(phi) - Izz*psi_p*cos(phi)*cos(theta)^2*sin(phi), (Izz*phi_p*cos(theta))/2 - (Iyy*phi_p*cos(theta))/2 - (Ixx*phi_p*cos(theta))/2 + Iyy*phi_p*cos(phi)^2*cos(theta) - Izz*phi_p*cos(phi)^2*cos(theta) + Ixx*psi_p*cos(theta)*sin(theta) - Iyy*psi_p*cos(theta)*sin(theta) + Iyy*psi_p*cos(phi)^2*cos(theta)*sin(theta) - Izz*psi_p*cos(phi)^2*cos(theta)*sin(theta) - Iyy*theta_p*cos(phi)*sin(phi)*sin(theta) + Izz*theta_p*cos(phi)*sin(phi)*sin(theta),                                                        Ixx*theta_p*cos(theta)*sin(theta) - Iyy*theta_p*cos(theta)*sin(theta) + Iyy*phi_p*cos(phi)*cos(theta)^2*sin(phi) - Izz*phi_p*cos(phi)*cos(theta)^2*sin(phi) + Iyy*theta_p*cos(phi)^2*cos(theta)*sin(theta) - Izz*theta_p*cos(phi)^2*cos(theta)*sin(theta)];


end

