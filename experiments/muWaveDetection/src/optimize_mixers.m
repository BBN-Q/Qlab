function optimize_mixers
    % create a mixer optimizer object
    [base_path] = fileparts(mfilename('fullpath'));
    cfg_path = [parent_dir(base_path, 1) '/cfg/optimize_mixer.cfg'];
    optimizer = MixerOptimizer(cfg_path);
    optimizer.Run();
end

% find the nth parent of directory given in 'path'
function str = parent_dir(path, n)
	str = path;
	if nargin < 2
		n = 1;
	end
	for j = 1:n
		pos = find(str == filesep, 1, 'last');
		str = str(1:pos-1);
	end
end