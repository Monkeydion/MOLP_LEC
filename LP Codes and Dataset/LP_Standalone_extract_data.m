len=8784;
aa=sol(1);
ab=sol(2);
ac=sol(3);
ad=sol(4);
ad1=sol(5);
ad2=sol(6);
ad3=sol(7);
ad4=sol(8);
ad5=sol(9);
ad6=sol(10);
ad7=sol(11);
ae=sol(12:8795);
af=sol(8796:17579);
ag=sol(17580:26363);
ah=sol(26364:35147);
ai=sol(35148:43931);
aj=sol(43932:52715);
ak=sol(52716:61499);

% plot(ae); xlabel('Timestep'); title('Grid-to-Load Power (W)'); ylabel('Power (W)')
% plot(af); xlabel('Timestep'); title('PV-to-Battery Power (W)'); ylabel('Power (W)')
% plot(ag); xlabel('Timestep'); title('PV-to-Load Power (W)'); ylabel('Power (W)')
% plot(ah); xlabel('Timestep'); title('Battery-to-Load Power (W)'); ylabel('Power (W)')
% plot(ai); xlabel('Timestep'); title('Battery SOE (Wh)'); ylabel('SOE (Wh)')
% plot(aj); xlabel('Timestep'); title('PV-to-Grid Power (W)'); ylabel('Power (W)')
% plot(ak); xlabel('Timestep'); title('Battery-to-Grid Power (W)'); ylabel('Power (W)')
%bar([ae';ag';ah'],'stacked')