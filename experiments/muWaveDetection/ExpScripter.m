% timeDomain
function ExpScripter

import MeasFilters.*

exp = ExpManager();

exp.dataFileHandler = HDF5DataHandler('silly.h5', 1);

expSettings = jsonlab.loadjson('scripter.json');
instrSettings = expSettings.instruments;
sweepSettings = expSettings.sweeps;
measSettings = expSettings.measurements;

for instrument = fieldnames(instrSettings)'
    instr = InstrumentFactory(instrument{1});
    add_instrument(exp, instrument{1}, instr, instrSettings.(instrument{1}));
end

for sweep = fieldnames(sweepSettings)'
    add_sweep(exp, SweepFactory(sweepSettings.(sweep{1}), exp.instruments));
end

add_measurement(exp, DigitalHomodyne(measSettings.meas1));
add_measurement(exp, DigitalHomodyne(measSettings.meas2));

exp.init();
exp.run();

end