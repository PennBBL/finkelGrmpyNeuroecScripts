function [output] = logisticGLMFit(choice,predictors,predictornames)
%no need to include intercept in the predictors variable

if size(predictors,2) ~= length(predictornames)
    keyboard
end

if sum(choice) ~=0 && sum(choice) ~= length(choice)
    choice = 2-choice; % 1 in choserisky becomes 1, and 0 becomes 2.
    [B,~,stats] = mnrfit(predictors,choice);
    glmprediction = B(1);
    for i = 1:length(B)-1
        glmprediction = glmprediction+ B(i+1).*predictors(:,i);
    end
    probability = 1 ./ (1 + exp(-1.*glmprediction)); %
    probability(probability == 1) = 1-eps;
    probability(probability == 0) = eps;
    err = (choice==1).*log(probability) + (choice==2).*log(1-probability);
    LL = sum(err);
    LL0 = sum((choice==1).*log(0.5) + (choice==2).*log(0.5));
    R2 = 1 - LL/LL0;
    p = stats.p;
else
    R2 = 1;
    B = [nan(1,length(predictors)+1)];
    p = [nan(1,length(predictors)+1)];
    stats = struct;
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
end