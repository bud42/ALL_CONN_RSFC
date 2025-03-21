CONTAINER = getenv("SINGULARITY_CONTAINER");
BIND = getenv("SINGULARITY_BIND");
ROOT = "";

disp(pwd);
disp(BIND);
disp(CONTAINER);

if BIND == ""
    disp('no binds found for INPUTS/OUTPUTS');
    exit;
end

% Get the absolute path to outputs as root dir
% We use the abs path so the launched jobs can find the data.
binds = split(BIND, ',');
for b=1:numel(binds)
    paths = split(binds{b}, ':');
    if string(paths{2}) == '/OUTPUTS'
        ROOT = fullfile(paths{1}, 'DATA');
    end
end

if ROOT == ""
    disp('/OUTPUTS not mounted correctly.');
    exit;
end

disp(ROOT);

% Get list of subdirectories
subjects = dir(fullfile(ROOT, 'PREPROC'));

% Get just the directory names while excluding dot and double-dot
subjects = {subjects([subjects.isdir] & cellfun(@(d)~all(d == '.'), {subjects.name})).name};
disp(subjects);

% Get list of rois
roinames = dir(fullfile(ROOT, 'ROI'));
roinames = {roinames([roinames.isdir] & cellfun(@(d)~all(d == '.'), {roinames.name})).name};
disp(roinames);

% Get list of sources in addition to ROIs
if isfile(fullfile(ROOT, 'sources.txt'))
    % Read first line into sources
    sources = readcell(fullfile(ROOT, 'sources.txt'), Delimiter=' ');
else
    sources = {};
end
disp(sources);

% Assign filenames/conditions for each subject
anats = {};
fmris = {};
roifiles = {};
conditions = {'rest'};
onsets = {};
durations = {};
all_tr = 0.0;
for n=1:numel(subjects)
    % Get current subject
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

        % Set the session-wide condition
        conditions{1+k} = ['rest-' sess];

        % Get list of scans for this session
        scans = dir(fullfile(ROOT, 'PREPROC', subj, 'FMRI', sess));
        scans = {scans(~[scans.isdir]).name};

        % Assign each scan by appending to list for whole subject
        for s=1:numel(scans)
            scan = scans{s};

            % Set the scan file
            fmris{n}{r} = fullfile(ROOT, 'PREPROC', subj, 'FMRI', sess, scan);

            % Determine TR
            new_tr = spm_vol_nifti(fmris{n}{r}).private.timing.tspace;
            if all_tr == 0
                all_tr = new_tr;
            elseif all_tr ~= new_tr
                disp('Bad TR found');
                exit;
            end

            % Initialize all conditions for this run
            for c=1:1+numel(sessions)
                onsets{c}{n}{r} = [];
                durations{c}{n}{r} = [];
            end

            % Set onsets to 0 and duration to infinity to include whole scan.
            % Current scan indexed by total run number.

            % Append to overall condition
            onsets{1}{n}{r} = 0;
            durations{1}{n}{r} = inf;

            % Set for condition for this session
            onsets{1+k}{n}{r} = 0;
            durations{1+k}{n}{r} = inf;

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
    end
end

% Build the variable structure
var.ROOT = ROOT;
var.STRUCTURALS = anats;
var.FUNCTIONALS = fmris;
var.CONDITIONS = conditions;
var.ONSETS = onsets;
var.DURATIONS = durations;
var.ROINAMES = roinames;
var.ROIFILES = roifiles;
var.SOURCES = [sources roinames];
var.TR = all_tr;

NSUBJECTS=length(var.STRUCTURALS);

FILTER=[0.01, 0.1];

STEPS={
    'functional_label_as_original',...
    'functional_realign&unwarp',...
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

% TODO: load covariates 2nd-Level subject effects
% Setup.subjects.effects, Setup.subjects.groups

clear batch;
batch.filename=fullfile(var.ROOT, 'conn_project.mat');

% Parallel on SLURM
batch.parallel.N=NSUBJECTS;
batch.parallel.name='ssh SLURM';
batch.parallel.comments='SLURM commands wrapped in ssh';
batch.parallel.cmd_submit='ssh $USER@$HOSTNAME "sbatch --job-name=JOBLABEL --error=STDERR --output=STDOUT OPTS SCRIPT"';
batch.parallel.cmd_submitoptions='-t 12:00:00 --mem=8G';
batch.parallel.cmd_deletejob='ssh $USER@$HOSTNAME scancel JOBID';
batch.parallel.cmd_checkstatus='ssh $USER@$HOSTNAME squeue --jobs=JOBID';
batch.parallel.cmd_rundeployed=1;
batch.parallel.cmd_deployedfile=['singularity exec ' CONTAINER ' /opt/conn/run_conn.sh /opt/matlabruntime/v912'];
batch.parallel.cmd_checkstatus_automatic=0;
batch.parallel.cmd_submit_delay=1;

% Setup
batch.Setup.isnew=1;
batch.Setup.nsubjects=NSUBJECTS;
batch.Setup.RT=var.TR;
batch.Setup.functionals=var.FUNCTIONALS;
batch.Setup.structurals=var.STRUCTURALS;

% Prepopulate secondary datasets so we can refer to subject-space in ROIs
batch.Setup.secondarydatasets{1}=struct('functionals_type', 2, 'functionals_label', 'unsmoothed volumes');
batch.Setup.secondarydatasets{2}=struct('functionals_type', 4, 'functionals_label', 'original data');
batch.Setup.secondarydatasets{3}=struct('functionals_type', 4, 'functionals_label', 'subject-space data');

% Add our subject specific ROIs
batch.Setup.rois.add = 1;
batch.Setup.rois.names=var.ROINAMES;
batch.Setup.rois.files=var.ROIFILES;
batch.Setup.rois.dataset={
    'subject-space data'
    'subject-space data'
};

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

batch.Setup.preprocessing.steps=STEPS;
batch.Setup.done=1;
batch.Setup.overwrite='Yes';                            

batch.Denoising.filter=FILTER;
batch.Denoising.done=1;
batch.Denoising.overwrite='Yes';

% 1st-Level Analysis for Seed to Voxel and ROI-to-ROI on same sources
batch.Analysis.done=1;
batch.Analysis.overwrite='Yes';
batch.Analysis.sources=var.SOURCES;
batch.Analysis.weight='none';

% Lastly, 2nd-Level Analysis
% TBD: batch.Results...
% Extras: QA plots

disp('Running batch with CONN');
conn_batch(batch);

disp('DONE!');
