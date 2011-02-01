% create a pure file dialog
% show and hide it a bunch of times

numDialogs = 5;

for i = 1:numDialogs
    dialog = javaObjectEDT('java.awt.FileDialog', []);
    %dialog = javaObjectEDT('javax.swing.JFrame');
    dialog.setModal(false);
    dialog.setVisible(true);
    pause(0.05);
    dialog.setVisible(false);
    dialog.dispose();
    dialog = [];
    pause(0.05);
    drawnow;
end