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
comm_load_data=table2array(commdata(:,5))';
grid_cost_data=table2array(gridcostdata(:,2))';
grid_sell_cost=table2array(gridselldata(:,2))';
grid_avail=table2array(gridavaildata(:,2))';
discount_rate=table2array(discountratetable(:,4))';

%Sensitivity
sell_fact=1.6;
cost_fact=0.8;
num=50; %20,30,40,60,70,80

timesteps=length(solar_data);
M=1000000;
PV_cost=20.2*cost_fact;
Bat_cost=10.18*cost_fact;
SCC_cost=9.8685*cost_fact;
gInv_cost=10.334*cost_fact;
PV_intercept_cost=2519*cost_fact;
Bat_intercept_cost=1191*cost_fact;
SCC_intercept_cost=2135*cost_fact;
gInv_intercept_cost=19110*cost_fact;
Inv_cost=15715*cost_fact;
Boost_cost=1925*cost_fact;
labor_cost=10000;
infrastructure_cost=1000000+200000*(num/10); %2500000+300000*(num/10);
grid_sell_cost=grid_sell_cost*sell_fact;
pow_share_max=240;
Inv_max=2000;
lifetime=20;
rev_share=0.1;
DOD=0.5;
n_inv=0.9;
n_charge=0.95;
n_discharge=0.95;
n_distribution=0.7;
home_budget=100000;

f2_min=-13289.44;
f2_max=908690.06;
q=30;
n=13;

epsilon=f2_min+((f2_max-f2_min)/q)*n;

c1=optimvar('a1_Home_Total_Cost','Lowerbound',-Inf,'UpperBound',Inf); %f2
c8=optimvar('a2_Comm_Total_Cost','Lowerbound',-Inf,'UpperBound',Inf); %f1

x1=optimvar('b1_PV_Size','Lowerbound',0,'UpperBound',Inf);
x2=optimvar('b2_Battery_Size','Lowerbound',0,'UpperBound',Inf);
x3=optimvar('b3_SCC_Size','Lowerbound',0,'UpperBound',Inf);
x4=optimvar('b4_GInv_Size','Lowerbound',0,'UpperBound',Inf);
x5=optimvar('b5_Discount_Cost_PV','Lowerbound',0,'UpperBound',Inf);
x6=optimvar('b6_Discount_Cost_Battery','Lowerbound',0,'UpperBound',Inf);
x7=optimvar('b7_Discount_Cost_SCC','Lowerbound',0,'UpperBound',Inf);
x8=optimvar('b8_Discount_Cost_Inverter','Lowerbound',0,'UpperBound',Inf);
x9=optimvar('b9_Discount_Cost_Boost','Lowerbound',0,'UpperBound',Inf);
x10=optimvar('bb10_Discount_Cost_Labor','Lowerbound',0,'UpperBound',Inf);
x11=optimvar('bb11_Energy_Share','Lowerbound',0,'UpperBound',Inf);

c2=optimvar('c2_Home_Capital_Cost','Lowerbound',0,'UpperBound',Inf);
c3=optimvar('c3_Home_Replacement_Cost_Y5','Lowerbound',0,'UpperBound',Inf);
c4=optimvar('c4_Home_Replacement_Cost_Y10','Lowerbound',0,'UpperBound',Inf);
c5=optimvar('c5_Home_Replacement_Cost_Y15','Lowerbound',0,'UpperBound',Inf);
c6=optimvar('c6_Home_Grid_Cost','Lowerbound',0,'UpperBound',Inf);
c7=optimvar('c7_Home_Revenue','Lowerbound',0,'UpperBound',Inf);

c9=optimvar('d2_Comm_Capital_Cost','Lowerbound',0,'UpperBound',Inf); 
c10=optimvar('d3_Comm_Replacement_Cost_Y5','Lowerbound',0,'UpperBound',Inf);
c11=optimvar('d4_Comm_Replacement_Cost_Y10','Lowerbound',0,'UpperBound',Inf);
c12=optimvar('d5_Comm_Replacement_Cost_Y15','Lowerbound',0,'UpperBound',Inf);
c13=optimvar('d6_Comm_Grid_Cost','Lowerbound',0,'UpperBound',Inf);
c14=optimvar('d7_Comm_Revenue','Lowerbound',0,'UpperBound',Inf);

s1=optimvar('e1_Home_Grid_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s2=optimvar('e2_Home_PV_to_Battery',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s3=optimvar('e3_Home_PV_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s4=optimvar('e4_Home_Battery_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s5=optimvar('e5_Home_Battery_SOE',timesteps,'Lowerbound',0,'UpperBound',Inf);
s6=optimvar('e6_Home_PV_to_Microgrid',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s7=optimvar('e7_Home_Battery_to_Microgrid',timesteps,'Lowerbound',0,'UpperBound',Inf); 

s9=optimvar('f1_Comm_Grid_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s10=optimvar('f2_Comm_Microgrid_to_Load',timesteps,'Lowerbound',0,'UpperBound',Inf); 
s11=optimvar('f3_Comm_Microgrid_to_Grid',timesteps,'Lowerbound',0,'UpperBound',Inf);  

prob=optimproblem('Objective',c8,'ObjectiveSense','min');

prob.Constraints.Home_Load_balance = (house_load_data)'==s1+s3+s4;
prob.Constraints.PV_generation_balance = s2+s3+s6==(solar_data)'*(x1./1000);
prob.Constraints.SOE = s5==circshift(s5,[1,1])+s2/n_charge-(s4+s7)/n_discharge;
prob.Constraints.SOE(1,1) = s5(1,1)==x2+s2(1,1)/n_charge-(s4(1,1)+s7(1,1))/n_discharge;
prob.Constraints.SOE_min = s5>=x2*DOD;
prob.Constraints.SOE_max = s5<=x2;
prob.Constraints.SCC_max = x1<=x3;
prob.Constraints.Inv_max = (s3+s4)/n_inv<=Inv_max;
prob.Constraints.Pow_Share_max = (s6+s7)/n_distribution<=pow_share_max;
prob.Constraints.Grid_avail_home = s1<=grid_avail'*M;

prob.Constraints.Comm_Microgrid_balance=(s10+s11)==num*(s6+s7);
prob.Constraints.Comm_Load_balance=(comm_load_data)'==(s9+(s10)/n_inv);
prob.Constraints.Grid_Share_max = s11/n_inv<=x4;
prob.Constraints.Grid_avail_Comm = s9+s11<=grid_avail'*M;

prob.Constraints.Energy_Shared=x11==sum(s6)+sum(s7);
prob.Constraints.Discount_Limit_PV=x5<=PV_cost*x1+PV_intercept_cost;
prob.Constraints.Discount_Limit_Battery=x6<=Bat_cost*x2+Bat_intercept_cost;
prob.Constraints.Discount_Limit_SCC=x7<=SCC_cost*x3+SCC_intercept_cost;
prob.Constraints.Discount_Limit_Inverter=x8<=Inv_cost;
prob.Constraints.Discount_Limit_Boost=x9<=Boost_cost;
prob.Constraints.Discount_Limit_Labor=x10<=labor_cost;
prob.Constraints.Household_Capital_Budget=c2<=home_budget;

prob.Constraints.Home_Total_Cost=c1==c2+c3+c4+c5+c6-c7;
prob.Constraints.Home_Total_Capital_Cost=c2==(PV_cost*x1+PV_intercept_cost)+(Bat_cost*x2+Bat_intercept_cost)+(SCC_cost*x3+SCC_intercept_cost)+Inv_cost+Boost_cost+labor_cost-x5-x6-x7-x8-x9-x10;
%prob.Constraints.Home_Replacement_Cost_Y5=c3==discount_rate(5).*((Bat_cost*x2+Bat_intercept_cost)+labor_cost-x6-x10);
%prob.Constraints.Home_Replacement_Cost_Y10=c4==discount_rate(10).*((Bat_cost*x2+Bat_intercept_cost)+(SCC_cost*x3+SCC_intercept_cost)+Inv_cost+Boost_cost+labor_cost-x6-x7-x8-x9-x10);
%prob.Constraints.Home_Replacement_Cost_Y15=c5==discount_rate(15).*((Bat_cost*x2+Bat_intercept_cost)+labor_cost-x6-x10);
 prob.Constraints.Home_Replacement_Cost_Y7=c3==discount_rate(7).*((Bat_cost*x2+Bat_intercept_cost)+labor_cost-x6-x10);
 prob.Constraints.Home_Replacement_Cost_Y10=c4==discount_rate(10).*((SCC_cost*x3+SCC_intercept_cost)+Inv_cost+Boost_cost+labor_cost-x7-x8-x9-x10);
 prob.Constraints.Home_Replacement_Cost_Y14=c5==discount_rate(14).*((Bat_cost*x2+Bat_intercept_cost)+labor_cost-x6-x10);
%prob.Constraints.Home_Replacement_Cost_Y10=c4==discount_rate(10).*((Bat_cost*x2+Bat_intercept_cost)+(SCC_cost*x3+SCC_intercept_cost)+Inv_cost+Boost_cost+labor_cost-x6-x7-x8-x9-x10);
prob.Constraints.Home_Total_Grid_Cost=c6==sum(discount_rate'.*(grid_cost_data*(s1./1000)));
prob.Constraints.Home_Total_Revenue=c7==sum(((discount_rate'.*(grid_sell_cost*(s11./1000)))*rev_share)/num);

prob.Constraints.Comm_Total_Cost=c8==c9+c10+c11+c12+c13-c14;
prob.Constraints.Comm_Total_Capital_Cost=c9==num*(x5+x6+x7+x8+x9+x10)+(gInv_cost*x4+gInv_intercept_cost)+infrastructure_cost;
%prob.Constraints.Comm_Replacement_Cost_Y5=c10==discount_rate(5).*(num*(x6+x10));
%prob.Constraints.Comm_Replacement_Cost_Y10=c11==discount_rate(10).*(num*(x6+x7+x8+x9+x10)+(gInv_cost*x4+gInv_intercept_cost));
%prob.Constraints.Comm_Replacement_Cost_Y15=c12==discount_rate(15).*(num*(x6+x10));
 prob.Constraints.Comm_Replacement_Cost_Y7=c10==discount_rate(7).*(num*(x6+x10));
 prob.Constraints.Comm_Replacement_Cost_Y10=c11==discount_rate(10).*(num*(x7+x8+x9+x10)+(gInv_cost*x4+gInv_intercept_cost));
 prob.Constraints.Comm_Replacement_Cost_Y14=c12==discount_rate(14).*(num*(x6+x10));
%prob.Constraints.Comm_Replacement_Cost_Y10=c11==discount_rate(10).*(num*(x6+x7+x8+x9+x10)+(gInv_cost*x4+gInv_intercept_cost));
prob.Constraints.Comm_Total_Grid_Cost=c13==sum(discount_rate'.*(grid_cost_data*(s9./1000)));
prob.Constraints.Comm_Total_Revenue=c14==sum((discount_rate'.*(grid_sell_cost*(s11./1000)))*(1-rev_share));

prob.Constraints.Epsilon=c1<=epsilon;

problem=prob2struct(prob); %instantiation of the linear programming problem 
[sol,fval,exitflag,output]=linprog(problem); %solving the linear programming problem

solutions=zeros(1,25);

for i=1:30
    time_start=datevec(datestr(now));
    disp(i);
    f2_min=-13289.44;
    f2_max=908690.06;
    q=30;
    n=i;
    epsilon=f2_min+((f2_max-f2_min)/q)*n;
    prob.Constraints.Epsilon=c1<=epsilon;

    problem=prob2struct(prob); %instantiation of the linear programming problem 
    [sol,fval,exitflag,output]=linprog(problem); %solving the linear programming problem
    solutions=cat(1,solutions,sol(1:25)');
    time_end=datevec(datestr(now));
    disp("Runtime (s): "+etime(time_end,time_start));
end