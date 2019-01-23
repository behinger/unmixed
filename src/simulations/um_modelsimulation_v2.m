cfg = [];
cfg.timelimits = [-0.1,1.2];
cfg.noise = 20;
cfg.srate= 50;
cfg.datalength = 60;
cfg.nsubject = 25;
cfg.optimizer = 'fminunc';%{'fminunc','quasinewton','fminsearch','bobyqa'};

rng(1)
input = [];
for k = 1:cfg.nsubject
    input{k} = simulate_data_lmm('noise',cfg.noise,...
        'srate',cfg.srate,'datasamples',cfg.datalength*cfg.srate,...
        'basis','dirac');
end


EEG = um_designmat(input,'eventtypes','sim','formula','y~1+b+(1+b|subject)');
EEG= um_timeexpandDesignmat(EEG,'timelimits',cfg.timelimits);


result = cfg;
tic
result.model = um_mmfit(EEG,input,'channel',1,'optimizer',cfg.optim);
result.timing = toc;

save(DataHash(cfg),'result')

% model_fminunc
% model = model_qn
% model = model_fminunc
%% Plotting

model = result(4).model;
R = model.Psi.NumBlocks;
covtable = cell(R,1);
covmat = covtable;
offset = 0;
tbl = covarianceParameters(model,0.05,0);
for k = 1:R
    % (1) Build an index idxk to extract relevant rows from tbl
    % for grouping variable k.
    matk = model.Psi.Matrices{k};
    startk = offset + 1;
    endk = offset + matk.NumParametersExcludingSigma;
    idxk = startk : endk;
    
    % (2) k the element of covtable.
    covtable{k} = [tbl(idxk,:)];
    covmat{k}= triu(ones(ceil(sqrt(length(idxk)))));
    covmat{k}(covmat{k}==1) = tbl.Estimate(idxk);
    % (3) Add a title for covtable{k}.
    %ttl = ['Group: ',model.GroupingInfo.GNames{k},...
    %    ', Covariance Type: ',model.slme.Psi.Matrices{k}.Type];
    % <entry key="Title_covtable">Covariance Type: {0}</entry>
%     ttl = getString(message('stats:LinearMixedModel:Title_covtable',model.slme.Psi.Matrices{k}.Type));
%     covtable{k} = classreg.regr.lmeutils.titleddataset(covtable{k},ttl);
    
    % (4) Update offset to go to the next grouping variable.
    offset = endk;
end
colorbar

figure,
nTimeshifts = model.Psi.NumBlocks;
subplot(2,nTimeshifts,1:nTimeshifts);
plot(reshape(model.betaHat,nTimeshifts,2),'o-')
for k = 1:R
    subplot(2,nTimeshifts,nTimeshifts + k);
    imagesc(covmat{k})
    caxis(prctile(tbl.Estimate,[1,99]))
end
