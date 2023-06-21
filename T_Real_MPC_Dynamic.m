% Programa de control predictivo para un drone basado en optimizacion usando Casadi
%% Clear variables
clc, clear all, close all;

load("chi_values.mat");
chi_real = chi';

%% DEFINITION OF TIME VARIABLES
f = 30; % Hz 
ts = 1/f;
to = 0;
tf = 45;
t = (to:ts:tf);

%% Inicializa Nodo ROS
rosshutdown
setenv('ROS_MASTER_URI','http://192.168.88.223:11311')
setenv('ROS_IP','192.168.88.104')
rosinit

%% 1) PUBLISHER TOPICS & MSG ROS - UAV M100

[velControl_topic,velControl_msg] = rospublisher('/m100/velocityControl','geometry_msgs/Twist');
u_ref = [0.0, -0.0, 0.0, 0.0];
send_velocities(velControl_topic, velControl_msg, u_ref);

%% 2) Suscriber TOPICS & MSG ROS
odomSub = rossubscriber('/dji_sdk/odometry');

[x,euler,x_p,omega] = odometryUAV(odomSub)
euler_p(:,1) = Euler_p(omega(:,1),euler(:,1));

h(:,1) = [x(:,1);euler(3,1)];
h_p(:,1) = [x_p(:,1);euler_p(3,1)]; 

%% Definicion del horizonte de prediccion
N = 10; 

%% CONSTANTS VALUES OF THE ROBOT
a = 0.0; 
b = 0.0;
c = 0.0;
L = [a, b, c];



%% GENERAL VECTOR DEFINITION
H = [h;h_p];

%% Variables definidas por la TRAYECTORIA y VELOCIDADES deseadas
mul = 5;
[hxd, hyd, hzd, hpsid, hxdp, hydp, hzdp, hpsidp] = Trayectorias(3,t,mul);

%% GENERALIZED DESIRED SIGNALS
%hd = [hxd; hyd; hzd; hpsid];
hd = [hxd;hyd;hzd;0*hpsid;hxdp; hydp; hzdp; 0*hpsidp];

hd_p = [hxdp;hydp;hzdp;hpsidp];

%% Deficion de la matriz de la matriz de control
%Q = 0.05*eye(4);

%% Definicion de la matriz de las acciones de control
%R = 0.005*eye(4);

Q = 0.01*[1 0 0 0; 0 2 0 0 ; 0 0 1 0 ; 0 0 0 0.5];
% Definicion de la matriz de las acciones de control
R = 0.001*eye(4);

Ke = 0.01;  % N = 15 ; Ke = 0.01 Ka = 4 ; f = 30
Kb = 0.8*eye(4);
Ka = 0.8*eye(4);
%Ka(2,2) = 0.0001*0.1; 

%% Definicion de los limites de las acciondes de control
bounded = [2.5; -2.5; 2.5; -2.5; 2.5; -2.5; 1.5; -1.5];

%% Definicion del vectro de control inicial del sistema
vcc = zeros(N,4);
H0 = repmat(H,1,N+1)'; 

% Definicion del optimizador
[f, solver, args] = mpc_drone(chi_real,bounded, N, L, ts, Q, R);

% Chi estimado iniciales
chi_estimados(:,1) = chi';
%chi_estimados(:,1) =[0.6502;0;0.8556;0;0.3880;0;0;0.1767;0.6019;0;0.0982;0;1.0217;0;0;0;0;1.0987]

tic
for k=1:length(t)-N
tic

    %% Generacion del; vector de error del sistema
    he(:,k)=hd(1:4,k)-h(:,k);
    
    args.p(1:8) = [h(:,k);h_p(:,k)]; % Generacion del estado del sistema
    
    for i = 1:N % z
        args.p(8*i+1:8*i+8)=[hd(:,k+i)];
%         args.p(4*i+5:4*i+7)=obs;
    end 
    
    args.x0 = [reshape(H0',8*(N+1),1);reshape(vcc',size(vcc,2)*N,1)]; % initial value of the optimization variables
    %tic;
    sol = solver('x0', args.x0, 'lbx', args.lbx, 'ubx', args.ubx,...
            'lbg', args.lbg, 'ubg', args.ubg,'p',args.p);
    %toc
    %sample(k)=toc;
    opti = reshape(full(sol.x(8*(N+1)+1:end))',4,N)';
    H0 = reshape(full(sol.x(1:8*(N+1)))',8,N+1)';
    hfut(:,1:4,k+1) = H0(:,1:4);
    vc(:,k)= opti(1,:)';
    
    vcp(:,k) = [0;0;0;0];
    %% DYNAMIC ESTIMATION
    %[Test(:,k),chi_estimados(:,k+1)] = estimadaptive_dymanic_UAV_real(chi_estimados(:,k),vcp(:,k), vc(:,k), h_p(:,k), hd(1:4,k), h(:,k) ,Ka,Kb, L, ts, Ke);

    
    %% Dinamica del sistema 

    send_velocities(velControl_topic, velControl_msg, vc(:,k));

%% 3) Odometria del UAV
    
    [x(:,k+1),euler(:,k+1),x_p(:,k+1),omega(:,k+1)] = odometryUAV(odomSub);
    
    euler_p(:,k+1) = Euler_p(omega(:,k+1),euler(:,k+1));
      
    R = Rot_zyx(euler(:,k+1));

    v(:,k+1) = inv(R)*x_p(:,k+1);
    
    
    h(:,k+1) = [x(:,k+1);euler(3,k+1)];
    h_p(:,k+1) = [x_p(:,k+1);euler_p(3,k+1)]; 

    
    J = [cos(psi(k)) -sin(psi(k)) 0 0;
    sin(psi(k)) cos(psi(k)) 0 0;
    0 0 1 0;
    0 0 0 1];

    %v(:,k+1) = pinv(J)*h_p(:,k);

        
    %% Actualizacion de los resultados del optimizador para tener una soluciona aproximada a la optima
    
    vcc = [opti(2:end,:);opti(end,:)];
    H0 = [H0(2:end,:);H0(end,:)];
    
    while toc<ts
    end
    dt(k) = toc;
end
toc
%% 1) PUBLISHER TOPICS & MSG ROS
u_ref = [0.0, -0.0, 0.0, 0.0];
send_velocities(velControl_topic, velControl_msg, u_ref);

save("T_MPC_Din-Est_UAV_Real.mat","hd","hd_p","h","h_p","v","vc","dt","t","ts","N");

%%
close all; paso=100; 
%a) Parámetros del cuadro de animación
figure(1)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
    set(gcf, 'PaperPosition', [0 0 8 3]);
    hi = light;
    hi.Color=[0.65,0.65,0.65];
    hi.Style = 'infinite';
%b) Dimenciones del Robot
    Drone_Parameters(0.02);
%c) Dibujo del Robot    
    G2=Drone_Plot_3D(h(1,1),h(2,1),h(3,1),0,0,psi(1));hold on

    G3 = plot3(h(1,1),h(2,1),h(3,1),'-','Color',[56,171,217]/255,'linewidth',1.5);hold on,grid on   
    G4 = plot3(hd(1,1),hd(2,1),hd(3,1),'Color',[32,185,29]/255,'linewidth',1.5);
    G5 = Drone_Plot_3D(h(1,1),h(2,1),h(3,1),0,0,psi(1));hold on
%    plot3(hxd(ubicacion),hyd(ubicacion),hzd(ubicacion),'*r','linewidth',1.5);
    view(20,15);
    


for k = 1:10:length(t)-N
    %drawnow
    delete(G2);
    delete(G3);
    delete(G4);
    delete(G5);
   
    G2=Drone_Plot_3D(h(1,k),h(2,k),h(3,k),0,0,psi(k));hold on  
    G3 = plot3(hd(1,1:k),hd(2,1:k),hd(3,1:k),'Color',[32,185,29]/255,'linewidth',1.5);
    G4 = plot3(h(1,k),h(2,k),h(3,k),'-.','Color',[56,171,217]/255,'linewidth',1.5);
    G5 = plot3(hfut(1:N,1,k),hfut(1:N,2,k),hfut(1:N,3,k),'Color',[100,100,100]/255,'linewidth',0.1);

    pause(0)
end

% %% Grafica para paper
% close all
% set(gcf, 'PaperUnits', 'inches');
% set(gcf, 'PaperSize', [4 2]);
% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperPosition', [0 0 10 4]);
% for k = 1:10:length(t)-N
%     %drawnow
%     delete(G2);
%     delete(G3);
%     delete(G4);
%     %delete(G5);
%     delete(G6);
%     delete(G7);
%     delete(G8);
%    % delete(G9);
%     
%     subplot(1,2,1)
%     view([50.029234115280943 45.991686774086247])
%     %xlim([-5 5])
%     zlim([-1 6])
%     G2=Drone_Plot_3D(hx(k),hy(k),hz(k),0,0,psi(k));hold on  
%     G3 = plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.5);
%     G4 = plot3(hx(1:k),hy(1:k),hz(1:k),'-.','Color',[56,171,217]/255,'linewidth',1.5);
%     legend([G3 G4],{'${\eta}_{ref}$','${\eta}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
%     %legend('boxoff')
%     grid on;
%     title('$\textrm{(a)}$','Interpreter','latex','FontSize',9);
%     ylabel('$ \eta_y[m]$','Interpreter','latex','FontSize',9);
%     xlabel('$ \eta_x[m]$','Interpreter','latex','FontSize',9);
%     zlabel('$ \eta_z[m]$','Interpreter','latex','FontSize',9);
%      
%     subplot(1,2,2)
%     view([0 90])
%     
%     G6=Drone_Plot_3D(hx(k),hy(k),hz(k),0,0,psi(k));hold on  
%     G7 = plot3(hxd(1:k),hyd(1:k),hzd(1:k),'Color',[32,185,29]/255,'linewidth',1.5);
%     G8 = plot3(hx(1:k),hy(1:k),hz(1:k),'-.','Color',[56,171,217]/255,'linewidth',1.5);
%     legend([G7 G8],{'${\eta}_{ref}$','${\eta}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
%     %legend('boxoff')
%     grid on;
%     title('$\textrm{(b)}$','Interpreter','latex','FontSize',9);
%     ylabel('$ \eta_y[m]$','Interpreter','latex','FontSize',9);
%     xlabel('$ \eta_x[m]$','Interpreter','latex','FontSize',9);
%     zlabel('$ \eta_z[m]$','Interpreter','latex','FontSize',9);
% 
%     pause(0)
% end
%%
figure (2)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);

plot(t(1:length(he)),he(1,:),'Color',[226,76,44]/255,'linewidth',1); hold on;
plot(t(1:length(he)),he(2,:),'Color',[46,188,89]/255,'linewidth',1); hold on;
plot(t(1:length(he)),he(3,:),'Color',[26,115,160]/255,'linewidth',1);hold on;
plot(t(1:length(he)),he(4,:),'Color',[83,57,217]/255,'linewidth',1);hold on;
grid on;

legend({'$\tilde{\eta}_{x}$','$\tilde{\eta}_{y}$','$\tilde{\eta}_{z}$','$\tilde{\eta}_{\psi}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');0
legend('boxoff')
%title('$\textrm{Evolution of Control Errors}$','Interpreter','latex','FontSize',9);
ylabel('$[m]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time }[s]$','Interpreter','latex','FontSize',9);
% xlabel('$Time[s]$','Interpreter','latex','FontSize',9);


figure(4)

plot(vc(1,100:end))
hold on
plot(h_p(1,100:end))

legend("vc","v","v_{ref}")
ylabel('x [m/s]'); xlabel('s [ms]');
%title('$\textrm{Evolution of ul Errors}$','Interpreter','latex','FontSize',9);

figure(5)
plot(vc(2,100:end))
hold on
plot(h_p(2,100:end))

legend("vc","v","v_{ref}")
ylabel('y [m/s]'); xlabel('s [ms]');
title('$\textrm{Evolution of um Errors}$','Interpreter','latex','FontSize',9);

figure(6)
plot(vc(3,100:end))
hold on
plot(h_p(3,100:end))

legend("vc","v","v_{ref}")
ylabel('z [m/ms]'); xlabel('s [ms]');
title('$\textrm{Evolution of un Errors}$','Interpreter','latex','FontSize',9);

figure(7)
plot(vc(4,100:end))
hold on
plot(h_p(4,100:end))

legend("vc","v","v_{ref}")
ylabel('psi [rad/s]'); xlabel('s [ms]');
title('$\textrm{Evolution of w Errors}$','Interpreter','latex','FontSize',9);


% figure
% set(gcf, 'PaperUnits', 'inches');
% set(gcf, 'PaperSize', [4 2]);
% set(gcf, 'PaperPositionMode', 'manual');
% set(gcf, 'PaperPosition', [0 0 10 4]);
% plot(t(1:length(ul_c)),ul_c,'Color',[226,76,44]/255,'linewidth',1); hold on
% plot(t(1:length(ul_c)),um_c,'Color',[46,188,89]/255,'linewidth',1); hold on
% plot(t(1:length(ul_c)),un_c,'Color',[26,115,160]/255,'linewidth',1); hold on
% plot(t(1:length(ul_c)),w_c,'Color',[83,57,217]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),ul,'--','Color',[226,76,44]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),um,'--','Color',[46,188,89]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),un,'--','Color',[26,115,160]/255,'linewidth',1); hold on
% plot(t(1:length(ul)),w,'--','Color',[83,57,217]/255,'linewidth',1); hold on
% grid on;
% legend({'$\mu_{lc}$','$\mu_{mc}$','$\mu_{nc}$','$\omega_{c}$','$\mu_{l}$','$\mu_{m}$','$\mu_{n}$','$\omega$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
% legend('boxoff')
% title('$\textrm{Control Values}$','Interpreter','latex','FontSize',9);
% ylabel('$[rad/s]$','Interpreter','latex','FontSize',9);
% xlabel('$\textrm{Time}[s]$','Interpreter','latex','FontSize',9);

figure(9)
plot(chi_estimados(:,:)')

figure(8)
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperSize', [4 2]);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition', [0 0 10 4]);
plot(t(1:length(dt)),dt,'Color',[46,188,89]/255,'linewidth',1); hold on
grid on;
legend({'$t_{sample}$'},'Interpreter','latex','FontSize',11,'Orientation','horizontal');
legend('boxoff')
%title('$\textrm{Sample Time}$','Interpreter','latex','FontSize',9);
ylabel('$[s]$','Interpreter','latex','FontSize',9);
xlabel('$\textrm{Time }[kT_0]$','Interpreter','latex','FontSize',9);
%xlabel('$Time[kT_0]$','Interpreter','latex','FontSize',9);
%%
% figure(9)
%   ul_e= vc(1,1:end) - v(1,1:size(vc(1,1:end),2));
%   um_e= vc(2,1:end) - v(2,1:size(vc(1,1:end),2));
%   un_e= vc(3,1:end) - v(3,1:size(vc(1,1:end),2));
%   
%   plot(ul_e), hold on, grid on
%   plot(um_e)
%   plot(un_e)
%   legend("hxe","hye","hze","psie")
%   title ("Errores de posición")