CONTAINER = "/data/h_taylor/Imaging/SINGULARITY_IMAGES/all_conn_rsfc_v1.0.0.sif";
ROOT = pwd;

% Get list of subdirectories
subjects = dir(fullfile(ROOT, '/PREPROC'));

% Get just the directory names while excluding dot and double-dot
subjects = {subjects([subjects.isdir] & cellfun(@(d)~all(d == '.'), {subjects.name})).name};

% Assign filenames/conditions for each subject
anats = {};
fmris = {};
rois = {};
conditions = {'rest'};
onsets = {};
durations = {};
for n=1:numel(subjects)
    anats{n} = fullfile(ROOT, 'PREPROC', subjects{n}, 'ANAT.nii');
    fmris{n}{1} = fullfile(ROOT, 'PREPROC', subjects{n}, 'REST1.nii');
    fmris{n}{2} = fullfile(ROOT, 'PREPROC', subjects{n}, 'REST2.nii');
    rois{1}{n} = fullfile(ROOT, 'ROI', 'DnSeg', subjects{n}, 'T1_seg_L.nii');
    rois{2}{n} = fullfile(ROOT, 'ROI', 'DnSeg', subjects{n}, 'T1_seg_R.nii');
    onsets{1}{n}{1} = 0;
    onsets{1}{n}{2} = 0;
    durations{1}{n}{1} = Inf;
    durations{1}{n}{2} = Inf;
end

% Build the variable structure
var.TR = 0.8;
var.ROOT = ROOT;
var.STRUCTURALS = anats;
var.FUNCTIONALS = fmris;
var.CONDITIONS = conditions;
var.ONSETS = onsets;
var.DURATIONS = durations;
var.SOURCES = {'atlas', 'networks', 'DnSeg_Left', 'DnSeg_Right'};
var.ROINAMES = {'DnSeg_Left', 'DnSeg_Right'};
var.ROIFILES = rois;

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
batch.parallel.name = 'ssh Slurm computer cluster';
batch.parallel.cmd_submit = 'ssh $USER@$HOSTNAME sbatch --job-name=JOBLABEL --error=STDERR --output=STDOUT OPTS SCRIPT';
batch.parallel.cmd_submitoptions = '-t 12:00:00 --mem=8G';
batch.parallel.cmd_deletejob = 'ssh $USER@$HOSTNAME scancel JOBID';
batch.parallel.cmd_checkstatus = 'ssh $USER@$HOSTNAME squeue --jobs=JOBID';
batch.parallel.cmd_rundeployed=1;
batch.parallel.cmd_deployedfile="singularity exec " + CONTAINER + " /opt/conn/run_conn.sh /opt/mcr/v912";

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
% TBD
% batch.Results...
%

% Extras: QA plots

conn_batch(batch);

disp('DONE!');
