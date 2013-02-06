function result = struct_reduce(fcn, input)
    result = struct();
    fields = fieldnames(input)';
    
    for field = fields
        if fcn(input.(field{1}))
            result.(field{1}) = input.(field{1});
        end
    end
end