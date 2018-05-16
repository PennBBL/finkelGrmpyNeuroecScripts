function [output] = logisticGLMFitAug16(choice,predictors,predictornames)
%no need to include intercept in the predictors variable

if size(predictors,2) ~= length(predictornames)
    keyboard
end

if sum(choice) ~=0 && sum(choice) ~= length(choice)
    choice = 2-choice; % risky choice was 1 and remains one; safe choice was 0 and becomes 2
    [B,~,stats] = mnrfit(predictors,choice);
    % predicted probabilities from model
    pihat = mnrval(B,predictors);
    
    err = (choice==1).*log(pihat(:,1)) + (choice==2).*log(pihat(:,2));
    LL = sum(err);
    % McFadden's pseudo R2
    R2 = 1 - LL/(log(0.5)*length(choice));
    p = stats.p;

    % added by MP, Tjur's coefficient of discrimination
    tjur = diff(grpstats(pihat(:,1),choice))*(-1);

else
    R2 = 1;
    B = nan(1,length(predictors)+1);
    p = nan(1,length(predictors)+1);
    stats = struct;
    tjur = 1;
end
for i= 1:length(predictornames)
    output.(predictornames{i}).coeff = B(i+1);
    output.(predictornames{i}).pval = p(i+1);
end
output.intercept.coeff = B(1);
output.intercept.pval = p(1);
output.coefficients = B;
output.pvalueofcoeffs = p;
output.R2 = R2;
output.stats = stats;
output.tjur = tjur;
end
