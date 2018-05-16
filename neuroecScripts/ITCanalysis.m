function [hyperbolic] = ITCanalysis(choice,v1,d1,v2,d2,RT)

% TITLE CHANGED FROM ITCanalysis-2 to ITCanalysis by MACK FINKEL 07062016

%v1 = immediate amount, v2 = delayed amount, d1 = vector of 0s, d2 = delays
% calculate the percentage of times the participant chose the 'now' option
percentNow = (sum(choice == 0) / length(choice)) * 100;

% find indifference k values for each option
indiffk = (v2 - v1) ./ ((v1.*d2) - (v2.*d1));

%find the minimum and maximum k values that could be reliably estimated
mink = min(indiffk)*(0.99);
maxk = max(indiffk)*(1.01);

%calculate k using Kirby's method
%sort choices by indifference k
kirby = sortrows([choice indiffk],2);
%find best k
numChoicesK = zeros(length(kirby),1);
for i=1:(length(kirby)-1)
    numChoicesK(i,1) = sum(kirby(1:i,1) == 0) + sum(kirby(i+1:end,1));
end
numChoicesK(end,1) = sum(kirby(1:end,1) == 0);
%find subscripts of best k
sub = find(numChoicesK(:,1) == max(numChoicesK(:,1)));
%for each switch point, get geometric mean of k at that row and following
%row
for i = 1:length(sub)
    try
        kirbyK(i) = geomean([kirby(sub(i),2) kirby(sub(i)+1,2)]); %#ok<*AGROW>
    catch %if best k is last
        kirbyK(i) = kirby(sub(i),2);
    end
end
%check if more than one k. if yes, take geometric mean of ks
if length(kirbyK)>1
    kirbyK = geomean(kirbyK);
end

if percentNow == 0
    hyperbolic.k=mink;
    hyperbolic.r2 = 1;
    hyperbolic.LL = nan;
    hyperbolic.noise = nan;
    hyperbolic.errorcode = 'alldelayed';
elseif percentNow == 100
    hyperbolic.k=maxk;
    hyperbolic.r2 = 1;
    hyperbolic.LL = nan;
    hyperbolic.noise = nan;
    hyperbolic.errorcode = 'allimmediate';
else
    %first initialize parameters using kirby fit and find k value
    starter = [0.005 kirbyK];
    noise = 0.005;
    ks = logspace (log10(mink),log10(maxk),4);
    [p,q] = meshgrid(noise, ks);
    pairs = [starter;p(:) q(:)];
    info.LL = -inf;
    for i = 1:length(pairs)
        b0 = [pairs(i,1) pairs(i,2)];
        [gsinfo] = fit_discount_model(choice,v1,d1,v2,d2,b0,mink,maxk);
        if gsinfo.LL > info.LL
            info = gsinfo;
        end
    end
    hyperbolic.k = info.b(2);
    hyperbolic.r2 = info.r2;
    hyperbolic.noise = info.b(1);
    hyperbolic.LL = info.LL;
    hyperbolic.errorcode = 'NA';
    hyperbolic.exitflag = info.exitflag;
    if info.exitflag ~= 1 && info.exitflag ~= 2
        keyboard
    end
end
k = hyperbolic.k;
delay = linspace (0, max(d2));
SVdelay = 1 ./ (1 + k.*delay); % get subjective value for each delay given the calculate k
AUC = mean(SVdelay)*100; %find mean SV*100

%calculate  AUC2 as %subjective value, calculated as
%mean(subjectiveValueLater ./ AmountLater)*100, where subjective value
%assumes the subject's k value
SVlater = v2 ./ (1 + (k*d2));
AUC2 = mean((SVlater ./ v2)*100);

%calculate % of choices predicted by participant's k value
%calculate value of delayed option that would make participant indifferent
%between this option and the sooner option (according to participant's k)
indifferentLL = (v1 .* (1+k.*d2));
%if actual delayed option is larger than calculated delayed option, predict choosing later
%option (1). Otherwise, predict choosing sooner option (0)
predictedChoice = indifferentLL < v2;
percentPredicted = sum(predictedChoice == choice) / length(choice) * 100;

%correlation between RT and absolute diff in subjective values)
SVsooner = v1 ./ (1+k*d1);
r = corrcoef(RT,abs(SVlater - SVsooner));
hyperbolic.RTandSubjValueCorr = r(1,2);
hyperbolic.percentPredicted = percentPredicted;
hyperbolic.AUC = AUC;
hyperbolic.AUC2 = AUC2;
hyperbolic.kirbyK = kirbyK;
hyperbolic.percentNow = percentNow;
hyperbolic.medianRT = median(RT);
end

function [info] = fit_discount_model(choice,v1,d1,v2,d2,b0,mink,maxk)
OPTIONS = optimset('Algorithm','interior-point','Display','off','MaxIter',3000,'MaxFunEvals',9000,'TolFun',1e-12,'TolX',1e-12,'TolCon',0);

[b,negLL,exitflag] = fmincon(@local_negLL,b0,[],[],[],[],[0, mink],[inf, maxk],[],OPTIONS,choice,v1,d1,v2,d2);


% Unrestricted log-likelihood
LL = -negLL;
% Restricted log-likelihood
LL0 = sum((choice==1).*log(0.5) + (1 - (choice==1)).*log(0.5));

info.exitflag = exitflag;
info.b = b;
info.LL = LL;
info.LL0 = LL0;
info.r2 = 1 - LL/LL0;
end

%----- LOG-LIKELIHOOD FUNCTION
function sumerr = local_negLL(beta,choice,v1,d1,v2,d2)

p = choice_prob(v1,d1,v2,d2,beta);

% Trap log(0)
ind = p == 1;
p(ind) = 1-eps;
ind = p == 0;
p(ind) = eps;
% Log-likelihood
err = (choice==1).*log(p) + (1 - (choice==1)).*log(1-p);
% Sum of -log-likelihood
sumerr = -sum(err);
end

%----- CHOICE PROBABILITY FUNCTION - LOGIT
%     p = choice_prob(v1,d1,v2,d2,beta);
%
%     INPUTS
%     v1    - values of option 1 (ie, sooner option)
%     d1    - delays of option 1
%     v2    - values of option 2 (ie, later option)
%     d2    - delays of option 2
%     beta  - parameters, noise term (1) and discount rate (2)
%
%     OUTPUTS
%     p     - choice probabilities for the **OPTION 2**
%
%     REVISION HISTORY:
%     brian lau 03.14.06 written
%     khoi 06.26.09 simplified

function p = choice_prob(v1,d1,v2,d2,beta)

u1 = discount(v1,d1,beta(2:end));
u2 = discount(v2,d2,beta(2:end));

% logit, smaller beta = larger error
p = 1 ./ (1 + exp(beta(1)*(u1-u2)));

end

%----- DISCOUNT FUNCTION - HYPERBOLIC
%     y = discount(v,d,beta)
%
%     INPUTS
%     v     - values
%     d     - delays
%     beta  - discount rate
%
%     OUTPUTS
%     y     - discounted values
%
%     REVISION HISTORY:
%     brian lau 03.14.06 written
%     khoi 06.26.09 simplified

function y = discount(v,d,beta)

y = v./(1+beta(1)*d);

end
