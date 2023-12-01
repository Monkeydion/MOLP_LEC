len=8784;
aa1=sol(1);
aa2=sol(2);
aa3=sol(3);
aa4=sol(4);
aa5=sol(5);
aa6=sol(6);
aa7=sol(7);
aa8=sol(8);
aa9=sol(9);
ab1=sol(10);
ab2=sol(11);
ab3=sol(12);
ab4=sol(13);
ab5=sol(14);
ab6=sol(15);
ab7=sol(16);
ab8=sol(17);
ab9=sol(18);
ac1=sol(19);
ac2=sol(20);
ac3=sol(21);
ac4=sol(22);
ac5=sol(23);
ac6=sol(24);
ac7=sol(25);
ad=sol(26:8809);
ae=sol(8810:17593);
af=sol(17594:26377);
ag=sol(26378:35161);
ah=sol(35162:43945);
ai=sol(43946:52729);
aj=sol(52730:61513);
ak=sol(61514:70297);
al=sol(70298:79081);
am=sol(79082:87865);

% plot(ad); xlabel('Timestep'); title('Home Grid-to-Load Power (W)'); ylabel('Power (W)')
% plot(ae); xlabel('Timestep'); title('Home PV-to-Battery Power (W)'); ylabel('Power (W)')
% plot(af); xlabel('Timestep'); title('Home PV-to-Load Power (W)'); ylabel('Power (W)')
% plot(ag); xlabel('Timestep'); title('Home Battery-to-Load Power (W)'); ylabel('Power (W)')
% plot(ah); xlabel('Timestep'); title('Home Battery SOE (Wh)'); ylabel('SOE (Wh)')
% plot(ai); xlabel('Timestep'); title('Home PV-to-Microgrid Power (W)'); ylabel('Power (W)')
% plot(aj); xlabel('Timestep'); title('Home Battery-to-Microgrid Power (W)'); ylabel('Power (W)')
% plot(ak); xlabel('Timestep'); title('Community Grid-to-Load Power (W)'); ylabel('Power (W)')
% plot(al); xlabel('Timestep'); title('Community Microgrid-to-Load Power (W)'); ylabel('Power (W)')
% plot(am); xlabel('Timestep'); title('Community Microgrid-to-Grid Power (W)'); ylabel('Power (W)')
%figure

day=320; %72%%233%91%320
hours=24;

%Home Load

Grid_Load=ad(1+((day-1)*hours):((day-1)*hours)+hours);
PV_Load=af(1+((day-1)*hours):((day-1)*hours)+hours);
Bat_Load=ag(1+((day-1)*hours):((day-1)*hours)+hours);
bar(1:24,[Grid_Load';PV_Load';Bat_Load'],'stacked')
title('Home Load Balance'); ylabel('Power (W)');xlabel('Time (Hour)')

yyaxis right
Solar=solar_data(1+((day-1)*hours):((day-1)*hours)+hours);
plot(1:24,Solar,LineWidth=1);
ylabel('Power (W)')
legend('Grid-to-Load','PV-to-Load','Battery-to-Load','Solar Power/1kWp')

figure;

%Home Battery
PV_Bat=ae(1+((day-1)*hours):((day-1)*hours)+hours);
Bat_Load=ag(1+((day-1)*hours):((day-1)*hours)+hours);
Bat_MG=aj(1+((day-1)*hours):((day-1)*hours)+hours);
bar(1:24,PV_Bat','g')
hold on
bar(1:24,-[Bat_Load';Bat_MG'],'stacked')
hold off
title('Home Battery Balance'); ylabel('Power (W)');xlabel('Time (Hour)')
legend('PV-to-Battery','Battery-to-Load','Battery-to-MG')
figure;

%Home MG
PV_MG=ai(1+((day-1)*hours):((day-1)*hours)+hours);
Bat_MG=aj(1+((day-1)*hours):((day-1)*hours)+hours);
bar(1:24,[PV_MG';Bat_MG'],'stacked')
title('Microgrid Share'); ylabel('Power (W)');xlabel('Time (Hour)')
legend('PV-to-MG','Battery-to-MG')
figure;

%Community Load and Grid
Grid_Load=ak(1+((day-1)*hours):((day-1)*hours)+hours);
MG_Load=al(1+((day-1)*hours):((day-1)*hours)+hours);
MG_Grid=am(1+((day-1)*hours):((day-1)*hours)+hours);
bar(1:24,[Grid_Load';MG_Load'],'stacked')
hold on
bar(1:24,-MG_Grid','g')
hold off
title('Community Load Balance and Grid Export'); ylabel('Power (W)');xlabel('Time (Hour)')
legend('Grid-to-Load','MG-to-Load','MG-to-Grid')


