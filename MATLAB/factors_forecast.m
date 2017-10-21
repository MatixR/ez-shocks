% -------------------------------------------------------------------------
% Generate forecast via factor model
%
%
%
%
% -------------------------------------------------------------------------

clear; clc;

% Load and manipulate data in import_data. Call results here:
import_data


% Simulate data as in testnfac.m by Serena Ng
%clear; clc;
rng(999);

r = 4; 
N = 100;
T = 50;

e = randn(T,N);
f = randn(T,r);
lambda = randn(N,r);
x = f*lambda'+ e;

fprintf('Data generating process: r = %d \n', r);
fprintf('Sample: T = %d, N = %d \n', size(x));


%%%%
% Find optimal number of factors according to Bai & Ng (2002)
kmax = 20; % Max number of factors to be extracted
gnum = 2; % ICp2 chosen in JLN2015
demean = 2; % Standardise data

bnicv = zeros(kmax,1);
for k = 1:kmax
    bnicv(k) = bnic(x, k, gnum, demean); % Compute BNIC for each k
end

bnicmin = min(bnicv);
rhat = minind(bnicv); % Optimal number of factors according to lowest IC
fprintf('\nFactors via IC(%d): rhat = %d \n', gnum, rhat);


%%%%
% Extract factors via PCA

%[ehat1, Fhat1, lamhat1, ev1]  = jln_factors(x, kmax, gnum, demean);
%[ehat1, Ghat1, lamhat1, ev1]  = jln_factors(x.^2, kmax, gnum, demean);

[Fhat, LF, ef, evf] = factors(x, rhat, demean);
[Ghat, LG, eg, evg] = factors(x.^2, rhat, demean);

sumeigval = cumsum(evf)/sum(evf);
R2_static = sum(evf(1:rhat))/sum(evf);


%%%%
% Forecast

% Build predictor set
zt     = [Fhat, Fhat(:, 1).^2, Ghat(:, 1)];
[~, M] = size(zt);

% Set dependent variables
yt     = standardise(x(:, 1:132)); % only macro data
[T, N] = size(yt);

py     = 4; % number of depvar lags
pz     = 2; % number of predictor lags
maxlag = max(py,pz);

L      = fix(4*(T/100)^(2/9)); % Newey-West lag length rule-of-thumb (N&W 1994)


ybetas = zeros(1+py+pz*M, N); % Parameter matrix

for i = 1:N % Test predictors on their own
    
    i = 1;
    
    X    = [ones(T, 1), jln_mlags(yt(:, i), py), jln_mlags(zt, pz)];
    reg  = nwest(yt(maxlag+1:end, i), X(maxlag+1:end, :), L);
    pass = abs(reg.tstat(py+2:end)) > 2.575; % hard threshold
    keep = [ones(1, py+1) == 1, pass'];
    Xnew = X(:,keep);
    reg  = nwest(yt(maxlag+1:end, i),Xnew(maxlag+1:end, :), L);
    vyt(:,i)       = reg.resid; % forecast errors
    ybetas(keep,i) = reg.beta;   
    fmodels(:,i)   = pass; %chosen predictors
end


% Generate AR(4) errors for zt
[T,R]  = size(zt);
pf     = 4;
L      = fix(4*(T/100)^(2/9));
fbetas = zeros(R,pf+1);
for i = 1:R
   X   = [ones(T,1),mlags(zt(:,i),pf)];
   reg = nwest(zt(pf+1:end,i),X(pf+1:end,:),L);
   vzt(:,i)    = reg.resid;
   fbetas(i,:) = reg.beta';
end

% Save data
[T,N]  = size(vyt);
ybetas = ybetas';
dates  = 1900+(59:1/12:112-1/12)';
dates  = dates(end-T+1:end);
save ferrors dates vyt vzt names vartype ybetas fbetas py pz pf zt xt fmodels

% Also write to .txt file for R code
dlmwrite('vyt.txt',vyt,'delimiter','\t','precision',17);
dlmwrite('vzt.txt',vzt,'delimiter','\t','precision',17);

