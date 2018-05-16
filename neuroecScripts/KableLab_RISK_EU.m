function out = KableLab_RISK_EU(choseRisky,CertainAmt,RiskyAmt,Risk,RT)
% choseRisky = 1 if risky option is chosen, 0 if certain option is chosen. Others are no choices
% Risk needs to be between 0 and 1. All inputs must be column vectors. 2016-Jun-07, Arthur
out.percentCertain = (sum(choseRisky == 0) / length(choseRisky)) * 100;
out.percentRisky = (sum(choseRisky == 1) / length(choseRisky)) * 100;
miss = choseRisky ~= 0 & choseRisky ~= 1;
out.percentMissed = (sum(miss)/length(choseRisky)) * 100;
choice = choseRisky(~miss);
CA = CertainAmt(~miss);
RA = RiskyAmt(~miss);
Risk = Risk(~miss);
RT = RT(~miss);
indiffa = log(Risk)./(log(CA)-log(RA));
mina = log(min(indiffa)*(0.99));
maxa = log(max(indiffa)*(1.01));
if (sum(choice) == length(choice)) || (sum(choice) == 0) % if choices are one-sided
    if sum(choice) == length(choice)
        out.alpha=exp(maxa);
    else
        out.alpha=exp(mina);
    end
    out.noise = nan;
    out.LL = 0;
else
    [noise,as] = meshgrid([-1, 1], linspace(mina,maxa,3)); % search grid
    b = [noise(:) as(:)];
    info.negLL = inf;
    for i = 1:length(b)
        [new.b,new.negLL] = fmincon(@negLL,b(i,:),[],[],[],[],[log(eps),mina],[-log(eps),maxa],[],optimset('Algorithm','interior-point','Display','off'),choice,CA,RA,Risk);
        if new.negLL < info.negLL
            info = new;
        end
    end
    out.alpha = exp(info.b(2));
    out.noise = exp(info.b(1));
    out.LL = -info.negLL;
end
out.LL0 = log(0.5)*length(choice);
out.r2 = 1 - out.LL/out.LL0;
SVRisky = Risk.*(RA.^out.alpha);
predictedChoice = SVRisky > (CA.^out.alpha); % 1 if delayed option is greater
out.percentPredicted = sum(predictedChoice == choice) / length(choice) * 100;
r = corrcoef(RT,abs(SVRisky - (CA.^out.alpha)));
out.RTandSubjValueCorr = r(1,2);
out.medianRT = median(RT);
end

function negLL = negLL(beta,choice,CA,RA,Risk)
p = probcalc(beta,CA,RA,Risk);
negLL = -sum((choice==1).*log(p) + (choice==0).*log(1-p));
end

function p = probcalc(beta,CA,RA,Risk)
SVRisky = Risk.*(RA.^exp(beta(2)));
reg = exp(beta(1)).*(SVRisky-(CA.^exp(beta(2))));
p = 1 ./ (1 + exp(-reg));
p(p == 1) = 1-eps;
p(p == 0) = eps;
end