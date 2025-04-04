% Run single subject in CONN toolbox through first-level S2V
CONTAINER = getenv("SINGULARITY_CONTAINER");
BIND = getenv("SINGULARITY_BIND");
ROOT = '/OUTPUTS';

anats = {};
fmris = {};
atlasfiles = {};
atlasnames = {};
atlasdatasets = {};
roifiles = {};
roidatasets = {};
conditions = {};
onsets = {};
durations = {};
all_tr = 0.0;
all_times = [];

disp(pwd);
disp(BIND);
disp(CONTAINER);

if BIND == ""
    disp('no binds found for INPUTS/OUTPUTS');
    exit;
end

% Get list of subdirectories
subjects = dir(fullfile(ROOT, 'PREPROC'));

% Get just the directory names while excluding dot and double-dot
subjects = {subjects([subjects.isdir] & cellfun(@(d)~all(d == '.'), {subjects.name})).name};
disp(subjects);

% Get list of rois
roinames = dir(fullfile(ROOT, 'ROI'));
roinames = {roinames([roinames.isdir] & cellfun(@(d)~all(d == '.'), {roinames.name})).name};
disp(roinames);

% Get list of atlas names to load for potential sources
if isfile(fullfile(ROOT, 'atlases.txt'))
    % Read first line
    atlasnames = readcell(fullfile(ROOT, 'atlases.txt'), Delimiter=' ');
else
    atlasnames = {};
end
disp(atlasnames);

% Get list of source regions (in addition to ROI list)
if isfile(fullfile(ROOT, 'sources.txt'))
    % Read first line into sources
    sources = readcell(fullfile(ROOT, 'sources.txt'), Delimiter=' ');
else
    sources = {};
end
disp(sources);

% Get current subject
n = 1;
subj = subjects{n};

% Assign the ANAT for the subject
anats{n} = fullfile(ROOT, 'PREPROC', subj, 'ANAT.nii');

% Get list of sessions
sessions = dir(fullfile(ROOT, 'PREPROC', subj, 'FMRI'));
sessions = {sessions([sessions.isdir] & cellfun(@(d)~all(d == '.'), {sessions.name})).name};

% Counter for total runs
r = 1;

% Assign each session
for k=1:numel(sessions)
    % Get current session
    sess = sessions{k};

    disp(sess);

    % Set name for the session-wide condition, all runs
    conditions{k} = ['rest-' sess];

    % Get list of scans for this session
    scans = dir(fullfile(ROOT, 'PREPROC', subj, 'FMRI', sess, '*.nii'));
    scans = {scans(~[scans.isdir]).name};

    % Assign each scan by appending to list for whole subject
    for s=1:numel(scans)
        scan = scans{s};
        disp(scan);

        % Set the scan file
        fmris{n}{r} = fullfile(ROOT, 'PREPROC', subj, 'FMRI', sess, scan);

        % Determine TR
        new_tr = spm_vol_nifti(fmris{n}{r}).private.timing.tspace;
        if all_tr == 0.0
            all_tr = new_tr;
        elseif all_tr ~= new_tr
            if abs(all_tr - new_tr) > 0.01
                disp('Conflicting TR found');
                disp(all_tr);
                disp(new_tr);
                exit;
            end
        end

        % Load slicetimes
        [nifti_dir, nifti_base, nifti_ext] = fileparts(fmris{n}{r});
        jsonfile = fullfile(nifti_dir, [nifti_base '.json']);
        jsondata = jsondecode(fileread(jsonfile));
        new_times = jsondata.SliceTiming;
        if isempty(all_times)
            all_times = new_times;
        elseif all_times ~= new_times
            disp('Conflicting slice times');
            exit;
        end

        % Initialize all conditions for this run
        for c=1:numel(sessions)
            onsets{c}{n}{r} = [];
            durations{c}{n}{r} = [];
        end

        % Set onsets to 0 and duration to infinity to include whole scan.
        % Current scan indexed by total run number, r.
        % Set for condition for this session, k.
        onsets{k}{n}{r} = 0;
        durations{k}{n}{r} = inf;

        % Increment total run count for subject
        r = r + 1;
    end
end

% Assign each roi
for i=1:numel(roinames)
    % Get current roi name
    roi = roinames{i};

    % Find the path to the roi file for this subject
    filename = dir(fullfile(ROOT, 'ROI', roi, subj));
    filename = {filename(~[filename.isdir]).name};
    filename = filename{1};
    roifiles{i}{n} = fullfile(ROOT, 'ROI', roi, subj, filename);
    roidatasets{i} = 'subject-space data';
end

% Assign each atlas file
for i=1:numel(atlasnames)
    atlas = atlasnames{i};
    atlasfiles{i}{n} = fullfile(ROOT, [atlas '.nii']);
    atlasdatasets{i} = 'unsmoothed volumes';
end
disp(atlasfiles);

% Build the variable structure
var.ROOT = ROOT;
var.STRUCTURALS = anats;
var.FUNCTIONALS = fmris;
var.CONDITIONS = conditions;
var.ONSETS = onsets;
var.DURATIONS = durations;
var.ROINAMES = [roinames atlasnames];
var.ROIFILES = [roifiles atlasfiles];
var.ROIDATASETS = [roidatasets atlasdatasets];
var.SOURCES = [roinames sources];
var.TR = all_tr;
var.SLICETIMES = all_times;
disp(var);

NSUBJECTS=length(var.STRUCTURALS);

FILTER=[0.01, 0.1];

% These same steps are also available in CONN as defaultMNISScombined.mat
STEPS={
    'functional_label_as_original',...
    'functional_realign&unwarp',...
    'functional_slicetime',...
    'functional_art',...
    'functional_coregister_affine_noreslice',...
    'functional_label_as_subjectspace',...
    'functional_segment&normalize_direct',...
    'functional_label_as_mnispace',...
    'structural_center',...
    'structural_segment&normalize',...
    'functional_smooth',...
    'functional_label_as_smoothed'...
    };

% Covariates, 2nd-Level subject effects, loaded after merging subjects
% Setup.subjects.effects, Setup.subjects.groups

clear batch;
batch.filename=fullfile(var.ROOT, 'conn_project.mat');

% Setup
batch.Setup.isnew=1;
batch.Setup.nsubjects=1;
batch.Setup.RT=var.TR;
batch.Setup.functionals=var.FUNCTIONALS;
batch.Setup.structurals=var.STRUCTURALS;
batch.Setup.analyses=[1,2];  % R2R and S2V

% Prepopulate secondary datasets so we can refer to subject-space in ROIs
batch.Setup.secondarydatasets{1}=struct('functionals_type', 2, 'functionals_label', 'unsmoothed volumes');
batch.Setup.secondarydatasets{2}=struct('functionals_type', 4, 'functionals_label', 'original data');
batch.Setup.secondarydatasets{3}=struct('functionals_type', 4, 'functionals_label', 'subject-space data');

% Add ROIs
batch.Setup.rois.add = 1;
batch.Setup.rois.names=var.ROINAMES;
batch.Setup.rois.files=var.ROIFILES;
batch.Setup.rois.dataset=var.ROIDATASETS;

% Configure conditions
batch.Setup.conditions.names=var.CONDITIONS;
batch.Setup.conditions.onsets=var.ONSETS;
batch.Setup.conditions.durations=var.DURATIONS;

% Enable saving denoised NIFTIs with d prefix
% Optional output files:
%   outputfiles(1): 1/0 creates confound beta-maps
%   outputfiles(2): 1/0 creates confound-corrected timeseries
%   outputfiles(3): 1/0 creates seed-to-voxel r-maps
%   outputfiles(4): 1/0 creates seed-to-voxel p-maps
%   outputfiles(5): 1/0 creates seed-to-voxel FDR-p-maps) 
%   outputfiles(6): 1/0 creates ROI-extraction REX files
batch.Setup.outputfiles=[0,1,0,0,0,0];

% Configure preproc
batch.Setup.preprocessing.steps=STEPS;
batch.Setup.preprocessing.sliceorder=var.SLICETIMES;

% Configure to run and overwrite any existing
batch.Setup.done=1;
batch.Setup.overwrite='Yes';                            

% Configure denoising
batch.Denoising.filter=FILTER;
batch.Denoising.done=1;
batch.Denoising.overwrite='Yes';

% 1st-Level Analysis for Seed to Voxel and ROI-to-ROI on same sources
batch.Analysis.done=1;
batch.Analysis.overwrite='Yes';
batch.Analysis.sources=var.SOURCES;
batch.Analysis.weight='none';
batch.Analysis.type=3;  % R2R and S2V

disp('Running batch with CONN');
conn_batch(batch);

disp('DONE!');
