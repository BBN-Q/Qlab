function optimize_mixers(channel)
    % channel 0 = all channels
    cfg_files = {'optimize_mixer.json', 'optimize_mixer2.json', 'optimize_mixer3.json'};
    if ~exist('channel', 'var')
        channel = 1;
    end
    if channel > length(cfg_files)
        error('Unknown channel number');
    end
    % create a mixer optimizer object
    [base_path] = fileparts(mfilename('fullpath'));
    cfg_path = [parent_dir(base_path, 1) '/cfg/'];
    if channel == 0
        for i = 1:length(cfg_files)
            optimizer = MixerOptimizer([cfg_path cfg_files{channel}]);
            optimizer.Run();
        end
    else
        optimizer = MixerOptimizer([cfg_path cfg_files{channel}]);
        optimizer.Run();
    end
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