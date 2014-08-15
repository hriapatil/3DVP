function exemplar_make_pbs_scripts

% load occlusion patterns
filename = '../../KITTI/data.mat';
object = load(filename);
data = object.data;
cids = unique(data.idx_ap);
num = numel(cids);

num_job = 32;
index = round(linspace(1, num, num_job+1));
num_cuda = round(num_job/5);

for o_i = 1:num_job
    
  fid = fopen(sprintf('run%d.sh', o_i), 'w');

  fprintf(fid, '#!/bin/bash\n');
  fprintf(fid, '#PBS -S /bin/bash\n');
  fprintf(fid, '#PBS -N run_it%d\n', o_i);
  fprintf(fid, '#PBS -l nodes=1:ppn=12\n');
  fprintf(fid, '#PBS -l mem=2gb\n');
  fprintf(fid, '#PBS -l walltime=48:00:00\n');
  if o_i <= num_cuda
      fprintf(fid, '#PBS -q cvglcuda\n');
  else
      fprintf(fid, '#PBS -q cvgl\n');
  end
  
  fprintf(fid,'cd /scail/scratch/u/yuxiang/SLM/ACF\n');
  if o_i == num_job
      s = sprintf('%d:%d', index(o_i), index(o_i+1));
  else
    s = sprintf('%d:%d', index(o_i), index(o_i+1)-1);
  end
  fprintf(fid, ['matlab.new -nodesktop -nosplash -r "exemplar_dpm_train(' s '); exit;"']);
  
  fclose(fid);
end

fid = fopen('exemplar_qsub.sh', 'w');
fprintf(fid, 'for (( i = 1; i <= %d; i++))\n', num_job);
fprintf(fid, 'do\n');
fprintf(fid, '  qsub run$i.sh\n');
fprintf(fid, 'done\n');
fclose(fid);