function out = bgsubtractphaseslope(data, range)
    % FUNCTION bgsubtractphaseslope(data)
    % subtracts the slope of every row from a 2D data set after correcting
    % for 2pi phase wraps.
    % Inputs:
    %   data - load_data() structure
    %   range - range to fit
    % Output: corrected phase data
    out = unwrap(angle(data.data), [], 2);
    % fit first row
    p = polyfit(data.xpoints(range), out(1,range)', 1);
    % subtract a linear slope from each row
    out = bsxfun(@minus, out, polyval(p, data.xpoints)');
end