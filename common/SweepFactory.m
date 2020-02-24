function out = SweepFactory(settings, instruments)
    import sweeps.*
    sweepType = str2func(settings.type);
    out = sweepType(settings, instruments);
end
