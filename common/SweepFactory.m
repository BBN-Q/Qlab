function out = SweepFactory(settings, instruments)
    sweepType = settings.type;
    out = sweeps.(sweepType)(settings, instruments);
end