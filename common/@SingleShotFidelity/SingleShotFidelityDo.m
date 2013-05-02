function SingleShotFidelityDo(obj)

obj.experiment.run();

% pull out data from the SingleShot measurement filter
pdfData = obj.experiment.measurements.single_shot.pdfData;


figure()
subplot(2,1,1)
cla()
plot(pdfData.bins_I, pdfData.gPDF_I, 'b');
hold on
plot(pdfData.bins_I, pdfData.ePDF_I, 'r');
legend({'Ground','Excited'})
text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*pdfData.maxFidelity_I), 'Units', 'normalized', 'FontSize', 14)

subplot(2,1,2)
cla()
plot(pdfData.bins_Q, pdfData.gPDF_Q, 'b');
hold on
plot(pdfData.bins_Q, pdfData.ePDF_Q, 'r');
legend({'Ground','Excited'})
text(0.1, 0.75, sprintf('Fidelity: %.1f%%',100*pdfData.maxFidelity_Q), 'Units', 'normalized', 'FontSize', 14)

drawnow()
end
