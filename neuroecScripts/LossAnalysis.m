function [output] = LossAnalysis(gain,loss,resp,RT)

% calculate the % of trials accepted
percentaccept = (sum(resp == 1) / length(resp)) * 100;

% find indifference Beta values for each option
indiffb = gain./loss;

%find the minimum and maximum beta values that could be reliably estimated
minbeta = min(indiffb)*(0.99);
maxbeta = max(indiffb)*(1.01);

if percentaccept == 0
    output.beta=maxbeta;
    output.r2 = 1;
    output.noise = nan;
    output.errorcode = 'rejectall';
elseif percentaccept == 100
    output.beta=minbeta;
    output.r2 = 1;
    output.noise = nan;
    output.errorcode = 'acceptall';
else
    %perform a grid search over beta values and noise values to ensure it's
    %not a local minima
    noise = 0.005;
    betas = linspace(minbeta,maxbeta,10);
    [p,q] = meshgrid(noise, betas);
    pairs = [p(:) q(:)];
    info.LL = -inf;
    for i = 1:length(pairs)
        b0 = [pairs(i,1) pairs(i,2)];
        [gsinfo] = fit_discount_model_loss(b0,gain,loss,resp,minbeta,maxbeta);
        if gsinfo.LL > info.LL
            info = gsinfo;
        end
    end
    output.beta = info.b(2);
    output.r2 = info.r2;
    output.noise = info.b(1);
    output.errorcode = 'NA';
    output.exitflag = info.exitflag;
    if info.exitflag ~= 1 && info.exitflag ~= 2
        keyboard
    end
end
indifferentloss = loss.*output.beta;
predictedChoice = indifferentloss < gain;
percentPredicted = sum(predictedChoice == resp) / length(resp) * 100;
r = corrcoef(RT,abs(gain-output.beta.*loss));
output.percentPredicted = percentPredicted;
output.RTandSubjValueCorr = r(1,2);
output.percentaccept = percentaccept;
output.medianRT = median(RT);
end

function [info] = fit_discount_model_loss(b0,gain,loss,resp,minbeta,maxbeta)

OPTIONS = optimset('Algorithm','interior-point','Display','off','MaxIter',3000,'MaxFunEvals',9000,'TolFun',1e-10,'TolX',1e-3,'TolCon',0);
[b,negLL,exitflag] = fmincon(@local_negLL,b0,[],[],[],[],[0, minbeta],[inf, maxbeta],[],OPTIONS,gain,loss,resp);
% Unrestricted log-likelihood
LL = -negLL;
% Restricted log-likelihood
LL0 = sum((resp==1).*log(0.5) + (1 - (resp==1)).*log(0.5));

info.exitflag = exitflag;
info.b = b;
info.LL = LL;
info.LL0 = LL0;
info.r2 = 1 - LL/LL0;
end

%----- LOG-LIKELIHOOD FUNCTION
function sumerr = local_negLL(b,gain,loss,resp)

p = choice_prob_loss(b,gain,loss);

% Trap log(0)
ind = p == 1;
p(ind) = 0.999999;
ind = p == 0;
p(ind) = 0.000001;
% Log-likelihood
err = (resp==1).*log(p) + (resp==0).*log(1-p);
% Sum of -log-likelihood
sumerr = -sum(err);
end

function p = choice_prob_loss(b,gain,loss)
u1 = gain;
u2 = loss * b(2);

% logit, smaller beta = larger error
p = 1 ./ (1 + exp(-b(1)*(u1-u2)));
end