% Load Data
soldata=readtable("Solar_Data.xlsx","Sheet","2020");
housedata=readtable("Household_Load.csv");
commdata=readtable("Community_Load.csv");
gridcostdata=readtable("APEC Data.xlsx","Sheet","Grid_Cost_v2");
gridselldata=readtable("APEC Data.xlsx","Sheet","Sell_Cost");
gridavaildata=readtable("APEC Data.xlsx","Sheet","Loss");
discountratetable=readtable("Discount Rate.xlsx","Sheet","Discount Rates");

solar_data=table2array(soldata(:,2))';
house_load_data=table2array(housedata(:,4))';
house_load_data=table2array(commdata(:,5))';
grid_cost_data=table2array(gridcostdata(:,2))';
grid_sell_cost=table2array(gridselldata(:,2))';
grid_avail=table2array(gridavaildata(:,2))';
discount_rate=table2array(discountratetable(:,4))';

%Sensitivity
sell_fact=1.6;
cost_fact=0.8;

timesteps=length(solar_data);
M=100000000;
PV_cost=20.2*cost_fact;
Bat_cost=10.18*cost_fact;
SCC_cost=9.8685*cost_fact;
gInv_cost=10.334*cost_fact;
PV_intercept_cost=2519*cost_fact;
Bat_intercept_cost=1191*cost_fact;
SCC_intercept_cost=2135*cost_fact;
gInv_intercept_cost=19110*cost_fact;
Inv_cost=15715*cost_fact;
labor_cost=10000;
grid_sell_cost=grid_sell_cost*sell_fact;
Inv_max=5000;
lifetime=20;
DOD=0.5;
n_inv=0.9;
n_charge=0.95;
n_discharge=0.95;
home_budget=167000;

c1=optimvar('a1_Home_Total_Cost','Lowerbound',-Inf,'UpperBound',Inf); %f2

x1=optimvar('b1_PV_Size','Lowerbound',0,'UpperBound',Inf);
x2=optimvar('b2_Battery_Size','Lowerbound',0,'UpperBound',Inf);
x3=optimvar('b3_SCC_Size','Lowerbound',0,'UpperBound',Inf);
x4=optimvar('b4_GInv_Size','Lowerbound',0,'UpperBound',Inf);

c2=optimvar('c2_Capital_Cost','Lowerbound',0,'UpperBound',Inf);
c3=optimvar('c3_Replacement_Cost_Y5','Lowerbound',0,'UpperBound',Inf);
c4=optimvar('c4_Replacement_Cost_Y10','Lowerbound',0,'UpperBound',Inf);
c5=optimvar('c5_Replacement_Cost_Y15','Lowerbound',0,'UpperBound',Inf);
c6=optimvar('c6_Grid_Cost','Lowerbound',0,'UpperBound',Inf);
c7=optimvar('c7_Revenue','Lowerbound',0,'UpperBound',Inf);

s1=optimvar('e1_Grid_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s2=optimvar('e2_PV_to_Battery',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s3=optimvar('e3_PV_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s4=optimvar('e4_Battery_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s5=optimvar('e5_Battery_SOE',timesteps,'Lowerbound',0,'UpperBound',Inf);
s6=optimvar('e6_PV_to_Grid',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s7=optimvar('e7_Battery_to_Grid',timesteps,'Lowerbound',0,'UpperBound',Inf); 

prob=optimproblem('Objective',c1,'ObjectiveSense','min');

prob.Constraints.Load_balance = (house_load_data)'==s1+s3+s4;
prob.Constraints.PV_generation_balance = s2+s3+s6==(solar_data)'*(x1./1000);
prob.Constraints.SOE = s5==circshift(s5,[1,1])+s2/n_charge-(s4+s7)/n_discharge;
prob.Constraints.SOE(1,1) = s5(1,1)==x2+s2(1,1)/n_charge-(s4(1,1)+s7(1,1))/n_discharge;
prob.Constraints.SOE_min = s5>=x2*DOD;
prob.Constraints.SOE_max = s5<=x2;
prob.Constraints.SCC_max = x1<=x3;
prob.Constraints.Inv_max = (s3+s4)/n_inv<=Inv_max;
prob.Constraints.Grid_avail_home = s1+s6+s7<=grid_avail'*M;
prob.Constraints.Grid_Share_max = (s6+s7)/n_inv<=x4;

prob.Constraints.Total_Cost=c1==c2+c3+c4+c5+c6-c7;
prob.Constraints.Total_Capital_Cost=c2==(PV_cost*x1+PV_intercept_cost)+(Bat_cost*x2+Bat_intercept_cost)+(SCC_cost*x3+SCC_intercept_cost)+Inv_cost+(gInv_cost*x4+gInv_intercept_cost)+labor_cost;
% prob.Constraints.Replacement_Cost_Y5=c3==discount_rate(5).*((Bat_cost*x2+Bat_intercept_cost));
% prob.Constraints.Replacement_Cost_Y10=c4==discount_rate(10).*((Bat_cost*x2+Bat_intercept_cost)+(SCC_cost*x3+SCC_intercept_cost)+Inv_cost+(gInv_cost*x4+gInv_intercept_cost)+labor_cost);
% prob.Constraints.Replacement_Cost_Y15=c5==discount_rate(15).*((Bat_cost*x2+Bat_intercept_cost));
prob.Constraints.Home_Replacement_Cost_Y7=c3==discount_rate(7).*((Bat_cost*x2+Bat_intercept_cost)+labor_cost);
prob.Constraints.Home_Replacement_Cost_Y10=c4==discount_rate(10).*((SCC_cost*x3+SCC_intercept_cost)+Inv_cost+(gInv_cost*x4+gInv_intercept_cost)+labor_cost);
prob.Constraints.Home_Replacement_Cost_Y14=c5==discount_rate(14).*((Bat_cost*x2+Bat_intercept_cost)+labor_cost);
prob.Constraints.Total_Grid_Cost=c6==sum(discount_rate'.*(grid_cost_data*(s1./1000)));
prob.Constraints.Total_Revenue=c7==sum(((discount_rate'.*(grid_sell_cost*((s6+s7)./1000)))));
%prob.Constraints.Household_Capital_Budget=c2<=home_budget;

problem=prob2struct(prob); %instantiation of the linear programming problem 
[sol,fval,exitflag,output]=linprog(problem); %solving the linear programming problem